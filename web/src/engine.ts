// Opening the published corpus and running queries, apart from the page.

import { RangeFetcher, type ByteRange } from "./fetcher.ts";
import { runQuery } from "./pipeline.ts";
import { SessionPool } from "./pool.ts";

export const wasmUrl = (name: string) => new URL(`wasm/${name}`, document.baseURI).href;

/** A match, as metaphir-match --matches-only prints it. */
export interface Match {
  /** Orders the matches as the corpus does. */
  key: number;
  module: string;
  fn: string;
  bindings: string;
  /** The IR of the matched function, when it can be shown. */
  ir?: () => Promise<string>;
}

export function parseMatch(key: number, line: string): Match {
  const [module, fn, bindings] = line.split("\t");
  return { key, module, fn, bindings: bindings ?? "" };
}

export interface Progress {
  stage: string;
  /** How far the stage is, from 0 to 1, when that is known. */
  fraction?: number;
  matches: number;
  matched: number;
  matchable: number;
  candidates: number;
  requests: number;
  bytes: number;
  seconds: number;
}

export class PublishedCorpus {
  readonly functions: number;
  readonly modules: number;
  private readonly fetcher: RangeFetcher;
  private readonly pool: SessionPool;

  private constructor(
    fetcher: RangeFetcher,
    pool: SessionPool,
    functions: number,
    modules: number,
  ) {
    this.fetcher = fetcher;
    this.pool = pool;
    this.functions = functions;
    this.modules = modules;
  }

  /** Opens the corpus config.json names, with a worker per core (up to 8). */
  static async open(): Promise<PublishedCorpus> {
    const config = await (await fetch("config.json", { cache: "no-cache" })).json();
    const data: string = config.data;
    if (data.includes("OWNER"))
      throw new Error("No corpus is configured: set data in config.json.");
    const manifest = await (
      await fetch(`${data.replace(/\/$/, "")}/manifest.json`, { cache: "no-cache" })
    ).json();
    const fetcher = await RangeFetcher.open(data, manifest.build);
    const header = await fetcher.fetchFile("header.bin.zst");
    const workers = Math.max(1, Math.min(navigator.hardwareConcurrency || 4, 8));
    const { pool, functions, modules } = await SessionPool.start(
      workers,
      wasmUrl("metaphir.js"),
      header,
    );
    return new PublishedCorpus(fetcher, pool, functions, modules);
  }

  /** Matches pattern, reporting progress and each function's matches. */
  async match(
    pattern: string,
    onProgress: (progress: Progress) => void,
    onMatches: (matches: Match[]) => void,
  ): Promise<void> {
    const { fetcher, pool } = this;
    const started = performance.now();
    const before = { ...fetcher.stats };
    const progress: Progress = {
      stage: "starting",
      matches: 0,
      matched: 0,
      matchable: 0,
      candidates: 0,
      requests: 0,
      bytes: 0,
      seconds: 0,
    };
    // Reports come at most every 100 ms, but for stage changes.
    let reported = 0;
    const report = (stage = progress.stage, force = true) => {
      const now = performance.now();
      if (!force && now - reported < 100) return;
      reported = now;
      progress.stage = stage;
      progress.requests = fetcher.stats.requests - before.requests;
      progress.bytes = fetcher.stats.bytes - before.bytes;
      progress.seconds = (now - started) / 1000;
      onProgress({ ...progress });
    };
    const packs = new Map<number, ByteRange>();
    const irOf = (fn: number) => async () => {
      let frame: Uint8Array | undefined;
      await fetcher.fetchRanges([packs.get(fn)!], (_, bytes) => (frame = bytes));
      const printed = await pool.coordinator.printFunction(frame!);
      if ("error" in printed) throw new Error(printed.error);
      return printed.ir;
    };
    await runQuery(pattern, "pattern.mpir", pool.coordinator, pool.sessions, fetcher, {
      onStage: (description) => {
        progress.fraction = description === "matching" ? 0 : undefined;
        report(description);
      },
      onFetch: (read, total) => {
        progress.fraction = total ? read / total : 1;
        report(progress.stage, read === total);
      },
      onCandidates: (candidates, matchable) => {
        progress.candidates = candidates;
        progress.matchable = matchable.length;
        for (const m of matchable) packs.set(m.function, m);
      },
      onMatched: (fn, lines) => {
        progress.matched++;
        const found = lines
          .split("\n")
          .filter(Boolean)
          .map((line, i) => ({ ...parseMatch(fn + i / 1e6, line), ir: irOf(fn) }));
        progress.matches += found.length;
        progress.fraction = progress.matched / Math.max(progress.matchable, 1);
        if (found.length) onMatches(found);
        report(progress.stage, found.length > 0);
      },
    });
    progress.fraction = 1;
    report("done");
  }
}

/** Matches local files with metaphir-match (the development server only). */
export async function matchLocal(
  picked: File[],
  indexFile: File | undefined,
  pattern: string,
  onProgress: (progress: Progress) => void,
  onMatches: (matches: Match[]) => void,
): Promise<void> {
  const { matchLocalFiles } = await import("./local.ts");
  const files = [];
  for (const file of picked) {
    if (!/\.(ll|bc)$/.test(file.name)) continue;
    // Paths relative to the picked directory.
    const path = file.webkitRelativePath.split("/").slice(1).join("/") || file.name;
    files.push({ path, bytes: new Uint8Array(await file.arrayBuffer()) });
  }
  if (!files.length) throw new Error("Pick a directory with .ll or .bc files.");
  const index = indexFile ? new Uint8Array(await indexFile.arrayBuffer()) : undefined;
  const started = performance.now();
  const progress = (stage: string, matches = 0): Progress => ({
    stage,
    matches,
    matched: 0,
    matchable: files.length,
    candidates: 0,
    requests: 0,
    bytes: 0,
    seconds: (performance.now() - started) / 1000,
  });
  onProgress(progress(`matching ${files.length} files`));
  const result = await matchLocalFiles(wasmUrl("metaphir-match.js"), files, pattern, index);
  if (result.status !== 0) throw new Error(result.err || `failed (${result.status})`);
  // Textual IR shows the function as it is written; bitcode cannot be
  // shown without a disassembler.
  const texts = new Map(
    files.filter((f) => f.path.endsWith(".ll")).map((f) => [f.path, f.bytes]),
  );
  const matches = result.out
    .split("\n")
    .filter(Boolean)
    .map((line, i) => {
      const match = parseMatch(i, line);
      const text = texts.get(match.module);
      if (text)
        match.ir = async () =>
          functionText(new TextDecoder().decode(text), match.fn) ?? "";
      return match;
    });
  onMatches(matches);
  onProgress(progress("done", matches.length));
}

/** The definition of fn (as "@name") in the textual IR of a module. */
export function functionText(module: string, fn: string): string | undefined {
  const lines = module.split("\n");
  const start = lines.findIndex(
    (line) => line.startsWith("define ") && line.includes(`${fn}(`),
  );
  if (start < 0) return undefined;
  const end = lines.findIndex((line, i) => i > start && line.startsWith("}"));
  return lines.slice(start, end < 0 ? undefined : end + 1).join("\n");
}
