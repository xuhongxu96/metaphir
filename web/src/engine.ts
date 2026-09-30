// Opening the published corpus and running queries, apart from the page.

import { RangeFetcher, type ByteRange } from "./fetcher.ts";
import type { Matchable } from "./pipeline.ts";
import { QueryControl, runQuery } from "./pipeline.ts";
import { SessionPool } from "./pool.ts";

export const wasmUrl = (name: string) => new URL(`wasm/${name}`, document.baseURI).href;

/** An instruction a match matched: the pattern's and the function's. */
export interface MatchedInstruction {
  /** The pattern instruction's result name, or its opcode. */
  name: string;
  /** Its line in the pattern (from 1), unless it is from a library. */
  patternLine?: number;
  /** The matched instruction's position among its function's. */
  position: number;
}

/** A function's IR, and the line of each of its instructions (from 1). */
export interface FunctionIR {
  text: string;
  lines: number[];
}

/**
 * A match, as metaphir-match --matches-only --print-instructions prints it.
 */
export interface Match {
  /** Orders the matches as the corpus does. */
  key: number;
  module: string;
  fn: string;
  bindings: string;
  instructions: MatchedInstruction[];
  /** The IR of the matched function, when it can be shown. */
  ir?: () => Promise<FunctionIR>;
}

export function parseMatch(key: number, line: string): Match {
  const [module, fn, bindings, instructions] = line.split("\t");
  return {
    key,
    module,
    fn,
    bindings: bindings ?? "",
    instructions: [
      ...(instructions ?? "").matchAll(/([^\s,{}@]+)(?:@(\d+))? = #(\d+)/g),
    ].map((m) => ({
      name: m[1],
      patternLine: m[2] === undefined ? undefined : Number(m[2]),
      position: Number(m[3]),
    })),
  };
}

/**
 * The lines of a function's instructions in its textual IR: those of its
 * body that are not labels, comments, debug records or the closing brace.
 */
export function instructionLines(text: string): number[] {
  const lines: number[] = [];
  text.split("\n").forEach((line, i) => {
    const trimmed = line.trim();
    if (
      i === 0 ||
      !trimmed ||
      trimmed.startsWith(";") ||
      trimmed.startsWith("#dbg_") ||
      trimmed === "}" ||
      /^[-\w.$"]+:/.test(trimmed)
    )
      return;
    lines.push(i + 1);
  });
  return lines;
}

/** A query pauses after each this many matches, until continued. */
export const MATCH_BATCH = 100;
/**
 * A query with more candidates than this pauses before reading their
 * features, until continued: reading and matching them all takes long.
 */
export const CANDIDATE_PROMPT = 20_000;

/** "1 match", "2 matches". */
export function count(n: number, noun: string, plural = `${noun}s`): string {
  return `${n.toLocaleString()} ${n === 1 ? noun : plural}`;
}

/** Why a query is paused: it reached a number of matches, or it would
 * check many candidates. */
export type Pause =
  | { kind: "matches"; matches: number }
  | { kind: "candidates"; candidates: number };

export interface Progress {
  /** What the query does, or "done" or "stopped" once it ended. */
  stage: string;
  /** Why the query is paused, while it is. */
  paused?: Pause;
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

  /** A corpus read by fetcher, as open() opens the one configured. */
  constructor(
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

  /**
   * Matches pattern, reporting progress and each function's matches. It
   * pauses control after each MATCH_BATCH matches, and before reading the
   * features of more than CANDIDATE_PROMPT candidates, unless it runs to
   * the end.
   */
  async match(
    pattern: string,
    onProgress: (progress: Progress) => void,
    onMatches: (matches: Match[]) => void,
    control: QueryControl,
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
      if (!control.paused) progress.paused = undefined;
      onProgress({ ...progress });
    };
    // The report after continuing or stopping says the query goes on.
    const pause = (why: Pause) => {
      control.pause();
      if (!control.paused) return;
      progress.paused = why;
      report();
      void control.proceed().then(() => report());
    };
    let nextPause = MATCH_BATCH;
    const packs = new Map<number, ByteRange>();
    const irOf = (fn: number) => async () => {
      let frame: Uint8Array | undefined;
      await fetcher.fetchRanges([packs.get(fn)!], (_, bytes) => (frame = bytes));
      const printed = await pool.coordinator.printFunction(frame!);
      if ("error" in printed) throw new Error(printed.error);
      return { text: printed.ir, lines: printed.lines };
    };
    const events = {
      onStage: (description: string) => {
        progress.fraction = description === "matching" ? 0 : undefined;
        report(description);
      },
      onFetch: (read: number, total: number) => {
        // Once all is read, the session works on it for as long as it
        // takes, which is not known.
        progress.fraction = read < total ? read / total : undefined;
        report(progress.stage, read === total);
      },
      onListed: (candidates: number) => {
        if (candidates > CANDIDATE_PROMPT)
          pause({ kind: "candidates", candidates });
      },
      onCandidates: (candidates: number, matchable: Matchable[]) => {
        progress.candidates = candidates;
        progress.matchable = matchable.length;
        for (const m of matchable) packs.set(m.function, m);
      },
      onMatched: (fn: number, lines: string) => {
        progress.matched++;
        const found = lines
          .split("\n")
          .filter(Boolean)
          .map((line, i) => ({ ...parseMatch(fn + i / 1e6, line), ir: irOf(fn) }));
        progress.matches += found.length;
        progress.fraction = progress.matched / Math.max(progress.matchable, 1);
        if (found.length) onMatches(found);
        if (progress.matches >= nextPause && !control.stopped) {
          // Those being matched meanwhile come after: the count goes on.
          const reached = nextPause;
          while (nextPause <= progress.matches) nextPause += MATCH_BATCH;
          pause({ kind: "matches", matches: reached });
        } else report(progress.stage, found.length > 0);
      },
    };
    await runQuery(
      pattern,
      "pattern.mpir",
      pool.coordinator,
      pool.sessions,
      fetcher,
      events,
      control,
    );
    if (!control.stopped) progress.fraction = 1;
    report(control.stopped ? "stopped" : "done");
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
        match.ir = async () => {
          const body = functionText(new TextDecoder().decode(text), match.fn) ?? "";
          return { text: body, lines: instructionLines(body) };
        };
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
