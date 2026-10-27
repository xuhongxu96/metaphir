// Every block of a published build read so far, kept so that nothing is read
// twice: in IndexedDB, one database per build, where the blocks stay until
// the site reads another build (a build's files never change, so its blocks
// expire only with it), with the recently used ones in memory too. Without
// IndexedDB (as in Node), blocks are kept in memory only.

export interface Block {
  file: string;
  start: number;
  bytes: Uint8Array;
}

interface BlockInfo {
  id: number;
  file: string;
  start: number;
  end: number;
  /** Whether the block is the whole file. */
  whole: boolean;
}

/** Recently used blocks kept in memory, at most this many bytes. */
const MEMORY_BUDGET = 512 * 1024 * 1024;
const DATABASE_PREFIX = "metaphir-blocks-";

function request<T>(req: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

export class BlockCache {
  /** The blocks of each file, sorted by start; they may overlap. */
  private byFile = new Map<string, BlockInfo[]>();
  /**
   * The size of each file's largest block, which bounds how far before a
   * range a block holding it can start.
   */
  private maxSize = new Map<string, number>();
  private nextId = 0;
  /** Bytes of recently used blocks, least recently used first. */
  private memory = new Map<number, Uint8Array>();
  private memoryBytes = 0;
  /** Reads from IndexedDB under way, so that each block is read once. */
  private reading = new Map<number, Promise<Uint8Array | undefined>>();
  private readonly db: IDBDatabase | undefined;

  private constructor(db: IDBDatabase | undefined, infos: BlockInfo[]) {
    this.db = db;
    for (const info of infos) this.index(info);
    this.nextId = infos.reduce((max, info) => Math.max(max, info.id + 1), 0);
  }

  /** The cache of a corpus's build, dropping its own other builds. */
  static async open(corpus: string, build: string): Promise<BlockCache> {
    if (typeof indexedDB === "undefined") return new BlockCache(undefined, []);
    try {
      // Another corpus's cache is kept: switching back must not reread it.
      const prefix = `${DATABASE_PREFIX}${encodeURIComponent(corpus)}:`;
      const name = prefix + build;
      // This corpus's other builds' blocks have expired.
      for (const other of (await indexedDB.databases?.()) ?? [])
        if (other.name?.startsWith(prefix) && other.name !== name)
          indexedDB.deleteDatabase(other.name);
      const open = indexedDB.open(name, 1);
      open.onupgradeneeded = () => {
        open.result.createObjectStore("info", { keyPath: "id" });
        open.result.createObjectStore("bytes");
      };
      const db = await request(open);
      const infos = await request(
        db.transaction("info").objectStore("info").getAll() as IDBRequest<BlockInfo[]>,
      );
      return new BlockCache(db, infos);
    } catch {
      // Storage may be unavailable, as in private windows.
      return new BlockCache(undefined, []);
    }
  }

  /** A block that holds the bytes [offset, offset + size) of file. */
  async get(file: string, offset: number, size: number): Promise<Block | undefined> {
    const info = this.find(file, offset, offset + size);
    if (!info) return undefined;
    const bytes = await this.bytesOf(info);
    return bytes && { file, start: info.start, bytes };
  }

  /** The whole file, if it was kept whole. */
  async getWhole(file: string): Promise<Uint8Array | undefined> {
    const info = this.byFile.get(file)?.find((block) => block.whole);
    return info && this.bytesOf(info);
  }

  /**
   * Keeps bytes, read from file at start; the promise settles once they are
   * stored (and never fails: blocks not stored are read again).
   */
  put(file: string, start: number, bytes: Uint8Array, whole = false): Promise<void> {
    const info: BlockInfo = {
      id: this.nextId++,
      file,
      start,
      end: start + bytes.length,
      whole,
    };
    this.index(info);
    this.remember(info.id, bytes);
    if (!this.db) return Promise.resolve();
    return new Promise((resolve) => {
      try {
        const transaction = this.db!.transaction(["info", "bytes"], "readwrite");
        transaction.objectStore("bytes").put(bytes, info.id);
        transaction.objectStore("info").put(info);
        transaction.oncomplete = transaction.onerror = transaction.onabort = () =>
          resolve();
      } catch {
        // Out of quota, say.
        resolve();
      }
    });
  }

  private index(info: BlockInfo): void {
    this.maxSize.set(
      info.file,
      Math.max(this.maxSize.get(info.file) ?? 0, info.end - info.start),
    );
    let blocks = this.byFile.get(info.file);
    if (!blocks) this.byFile.set(info.file, (blocks = []));
    let at = blocks.length;
    while (at > 0 && blocks[at - 1].start > info.start) at--;
    blocks.splice(at, 0, info);
  }

  /** A block that holds [start, end) of file. */
  private find(file: string, start: number, end: number): BlockInfo | undefined {
    const blocks = this.byFile.get(file);
    if (!blocks) return undefined;
    // Any block starting at or before start may hold the range, back to
    // those too far before it for the largest block to reach its end.
    let low = 0;
    let high = blocks.length;
    while (low < high) {
      const middle = (low + high) >> 1;
      if (blocks[middle].start <= start) low = middle + 1;
      else high = middle;
    }
    const reach = this.maxSize.get(file) ?? 0;
    for (let i = low - 1; i >= 0 && blocks[i].start + reach >= end; i--)
      if (blocks[i].end >= end) return blocks[i];
    return undefined;
  }

  private async bytesOf(info: BlockInfo): Promise<Uint8Array | undefined> {
    const kept = this.memory.get(info.id);
    if (kept) {
      // Most recently used again.
      this.memory.delete(info.id);
      this.memory.set(info.id, kept);
      return kept;
    }
    if (!this.db) return undefined;
    let read = this.reading.get(info.id);
    if (!read) {
      read = request(this.db.transaction("bytes").objectStore("bytes").get(info.id))
        .then((stored) => {
          if (!stored) return undefined;
          const bytes = new Uint8Array(stored as ArrayBuffer | Uint8Array);
          this.remember(info.id, bytes);
          return bytes;
        })
        .catch(() => undefined)
        .finally(() => this.reading.delete(info.id));
      this.reading.set(info.id, read);
    }
    return read;
  }

  private remember(id: number, bytes: Uint8Array): void {
    this.memory.set(id, bytes);
    this.memoryBytes += bytes.length;
    for (const [oldest, old] of this.memory) {
      // Without IndexedDB, memory is all there is.
      if (this.memoryBytes <= MEMORY_BUDGET || !this.db) break;
      this.memory.delete(oldest);
      this.memoryBytes -= old.length;
    }
  }
}
