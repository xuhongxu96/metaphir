// Reads byte ranges of a published corpus over HTTP.
//
// On a Hugging Face bucket, a file's URL redirects to a signed CDN URL; only
// that first request counts toward the Hub's rate limit, so each file is
// resolved once and its ranges are read from the CDN URL until it expires.
// Nearby ranges are read together, and every block read is kept (see
// blocks.ts), so that no byte is read twice while the build is current.

import { BlockCache, type Block } from "./blocks.ts";

export interface ByteRange {
  file: string;
  offset: number;
  size: number;
}

export interface FetchStats {
  requests: number;
  /** Bytes read over the network. */
  bytes: number;
  /** Ranges found in the cache. */
  cached: number;
  /** Responses asking to slow down (HTTP 429 or 503). */
  throttled: number;
}

/**
 * Ranges of a file closer than this are read in one request: the bytes
 * between them are kept too, and later queries often need them. The index
 * and the features are read in large blocks, so that after a few queries
 * they are all kept; packs, 6 GB in all, in smaller ones.
 */
const MAX_GAP: Record<string, number> = {
  "functions.idx": 10 * 1024 * 1024,
  "features.bin": 10 * 1024 * 1024,
  "packs.bin": 10 * 1024 * 1024,
};
const DEFAULT_MAX_GAP = 1024 * 1024;
/** No request reads more than this, unless one range is larger. */
const MAX_REQUEST = 16 * 1024 * 1024;
/** Requests in flight at once, over one HTTP/2 connection. */
const CONCURRENCY = 48;
/** Times a request is retried when the server asks to slow down. */
const MAX_THROTTLED = 8;

/**
 * How long, in milliseconds, a response asking to slow down says to wait:
 * Retry-After, or the Hub's "RateLimit: ...;t=<seconds>"; otherwise longer
 * after each attempt.
 */
function waitOf(response: Response, attempt: number): number {
  const retryAfter = Number(response.headers.get("retry-after"));
  if (response.headers.has("retry-after") && Number.isFinite(retryAfter))
    return retryAfter * 1000;
  const reset = /;t=(\d+)/.exec(response.headers.get("ratelimit") ?? "");
  if (reset) return Number(reset[1]) * 1000;
  return Math.min(1000 * 2 ** attempt, 60_000);
}

/** Ranges of one file, sorted, merged into the requests that read them. */
export function planRequests(ranges: ByteRange[]): ByteRange[][] {
  const sorted = [...ranges].sort((a, b) =>
    a.file === b.file ? a.offset - b.offset : a.file < b.file ? -1 : 1,
  );
  const requests: ByteRange[][] = [];
  let current: ByteRange[] = [];
  let start = 0;
  let end = 0;
  for (const range of sorted) {
    const last = current[current.length - 1];
    const fits =
      last !== undefined &&
      last.file === range.file &&
      range.offset <= end + (MAX_GAP[range.file] ?? DEFAULT_MAX_GAP) &&
      Math.max(end, range.offset + range.size) - start <= MAX_REQUEST;
    if (!fits) {
      if (current.length) requests.push(current);
      current = [];
      start = range.offset;
      end = range.offset;
    }
    current.push(range);
    end = Math.max(end, range.offset + range.size);
  }
  if (current.length) requests.push(current);
  return requests;
}

/** The body of response, reporting each chunk's size as it arrives. */
async function readBody(
  response: Response,
  onBytes?: (bytes: number) => void,
): Promise<Uint8Array> {
  if (!response.body || !onBytes) return new Uint8Array(await response.arrayBuffer());
  const chunks: Uint8Array[] = [];
  let length = 0;
  const reader = response.body.getReader();
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    length += value.length;
    onBytes(value.length);
  }
  const bytes = new Uint8Array(length);
  let at = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, at);
    at += chunk.length;
  }
  return bytes;
}

export class RangeFetcher {
  readonly stats: FetchStats = { requests: 0, bytes: 0, cached: 0, throttled: 0 };
  /** When a server that asked to slow down lets requests go on. */
  private pausedUntil = 0;
  /** Each file's CDN URL, once resolved. */
  private resolved = new Map<string, Promise<string>>();
  private readonly base: string;
  private readonly cache: BlockCache;

  private constructor(base: string, cache: BlockCache) {
    this.base = base;
    this.cache = cache;
  }

  /**
   * A fetcher for the build named build, whose files are under the URL base.
   */
  static async open(base: string, build: string): Promise<RangeFetcher> {
    return new RangeFetcher(base, await BlockCache.open(build));
  }

  url(file: string): string {
    return `${this.base.replace(/\/$/, "")}/${file}`;
  }

  /** Reads a whole small file, such as the header. */
  async fetchFile(file: string): Promise<Uint8Array> {
    const cached = await this.cache.getWhole(file);
    if (cached) {
      this.stats.cached++;
      return cached;
    }
    let response: Response;
    for (let throttled = 0; ; throttled++) {
      response = await this.request(this.url(file), undefined, throttled);
      if (response.status !== 429 && response.status !== 503) break;
      if (throttled >= MAX_THROTTLED)
        throw new Error(`${file}: the server keeps asking to slow down`);
    }
    if (!response.ok) throw new Error(`${file}: HTTP ${response.status}`);
    const bytes = new Uint8Array(await response.arrayBuffer());
    this.stats.requests++;
    this.stats.bytes += bytes.length;
    await this.cache.put(file, 0, bytes, /*whole=*/ true);
    return bytes;
  }

  /**
   * Reads the ranges, calling onRange with each as its bytes arrive, in no
   * particular order.
   */
  fetchRanges(
    ranges: ByteRange[],
    onRange: (range: ByteRange, bytes: Uint8Array) => void,
    onProgress?: (read: number, total: number) => void,
  ): Promise<void> {
    return this.fetchBlocks(ranges, (block, within) => {
      for (const range of within)
        onRange(
          range,
          block.bytes.subarray(
            range.offset - block.start,
            range.offset - block.start + range.size,
          ),
        );
    }, onProgress);
  }

  /**
   * Reads the ranges, calling onBlock once with each block that holds some,
   * and those it holds, in no particular order.
   */
  async fetchBlocks(
    ranges: ByteRange[],
    onBlock: (block: Block, within: ByteRange[]) => void,
    onProgress?: (read: number, total: number) => void,
  ): Promise<void> {
    // Ranges in blocks kept already, by block.
    const kept = new Map<Uint8Array, { block: Block; within: ByteRange[] }>();
    const missing: ByteRange[] = [];
    const found = await Promise.all(
      ranges.map((range) => this.cache.get(range.file, range.offset, range.size)),
    );
    ranges.forEach((range, i) => {
      const block = found[i];
      if (!block) {
        missing.push(range);
        return;
      }
      this.stats.cached++;
      let entry = kept.get(block.bytes);
      if (!entry) kept.set(block.bytes, (entry = { block, within: [] }));
      entry.within.push(range);
    });
    for (const { block, within } of kept.values()) onBlock(block, within);

    const requests = planRequests(missing);
    // Bytes to read over the network, and read so far.
    const extent = (request: ByteRange[]) =>
      Math.max(...request.map((r) => r.offset + r.size)) - request[0].offset;
    const total = requests.reduce((sum, request) => sum + extent(request), 0);
    let read = 0;
    onProgress?.(0, total);
    const onBytes = (bytes: number) => {
      read += bytes;
      onProgress?.(read, total);
    };
    // Done once what was read is stored too.
    const stored: Promise<void>[] = [];
    let next = 0;
    const work = async () => {
      while (next < requests.length) {
        const request = requests[next++];
        const first = request[0];
        const start = first.offset;
        const end = Math.max(...request.map((r) => r.offset + r.size));
        const bytes = await this.read(first.file, start, end - start, onBytes);
        // All of it is kept, the bytes between the ranges too.
        stored.push(this.cache.put(first.file, start, bytes));
        onBlock({ file: first.file, start, bytes }, request);
      }
    };
    await Promise.all(
      Array.from({ length: Math.min(CONCURRENCY, requests.length) }, work),
    );
    await Promise.all(stored);
  }

  /** Reads bytes [offset, offset + size) of file, retrying once expired. */
  private async read(
    file: string,
    offset: number,
    size: number,
    onBytes?: (bytes: number) => void,
  ): Promise<Uint8Array> {
    if (size === 0) return new Uint8Array();
    let expired = 0;
    let throttled = 0;
    for (;;) {
      const url = await this.resolve(file, expired > 0);
      const response = await this.request(
        url,
        { headers: { Range: `bytes=${offset}-${offset + size - 1}` } },
        throttled,
      );
      if (response.status === 429 || response.status === 503) {
        if (++throttled > MAX_THROTTLED)
          throw new Error(`${file}: the server keeps asking to slow down`);
        continue;
      }
      // A signed URL that expired is resolved again.
      if ((response.status === 403 || response.status === 401) && expired++ < 2)
        continue;
      if (response.status !== 206 && response.status !== 200)
        throw new Error(`${file}: HTTP ${response.status}`);
      let bytes = await readBody(response, response.status === 206 ? onBytes : undefined);
      // A server that ignores Range sends the whole file.
      if (response.status === 200) bytes = bytes.slice(offset, offset + size);
      if (bytes.length !== size)
        throw new Error(`${file}: expected ${size} bytes, got ${bytes.length}`);
      this.stats.requests++;
      this.stats.bytes += size;
      return bytes;
    }
  }

  /**
   * Fetches url once any pause a server asked for is over. A response
   * asking to slow down, for the attempt-th time, pauses every request.
   */
  private async request(
    url: string,
    init: RequestInit | undefined,
    attempt: number,
  ): Promise<Response> {
    const wait = this.pausedUntil - Date.now();
    if (wait > 0) await new Promise((resume) => setTimeout(resume, wait));
    const response = await fetch(url, init);
    if (response.status === 429 || response.status === 503) {
      this.stats.throttled++;
      await response.arrayBuffer().catch(() => undefined);
      this.pausedUntil = Math.max(
        this.pausedUntil,
        Date.now() + waitOf(response, attempt),
      );
    }
    return response;
  }

  /** The URL to read file's ranges from: where its URL redirects. */
  private resolve(file: string, again: boolean): Promise<string> {
    let url = this.resolved.get(file);
    if (!url || again) {
      url = (async () => {
        // A one-byte read follows the redirect and shows where it went.
        let response: Response;
        for (let throttled = 0; ; throttled++) {
          response = await this.request(
            this.url(file),
            { headers: { Range: "bytes=0-0" } },
            throttled,
          );
          if (response.status !== 429 && response.status !== 503) break;
          if (throttled >= MAX_THROTTLED)
            throw new Error(`${file}: the server keeps asking to slow down`);
        }
        await response.arrayBuffer();
        if (!response.ok) throw new Error(`${file}: HTTP ${response.status}`);
        this.stats.requests++;
        return response.url || this.url(file);
      })();
      this.resolved.set(file, url);
      url.catch(() => this.resolved.delete(file));
    }
    return url;
  }
}
