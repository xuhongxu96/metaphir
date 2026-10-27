// Opening the published corpus and running queries, apart from the page.

import type { CorpusConfig } from "./corpora.ts";
import { RangeFetcher, type ByteRange } from "./fetcher.ts";
import type { Matchable, Note, Rejected } from "./pipeline.ts";
import { QueryControl, runQuery } from "./pipeline.ts";
import { SessionPool } from "./pool.ts";

/** A WebAssembly module's script, versioned so that no cache keeps an old one. */
export const wasmUrl = (name: string) =>
  new URL(`wasm/${name}?v=${__WASM_VERSION__}`, document.baseURI).href;

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
  /** Loads the IR of the matched function; every match the page shows has
   * it, once made (see makeMatch). */
  ir?: () => Promise<FunctionIR>;
}

export function parseMatch(key: number, line: string): Match {
  const [module, fn, bindings, instructions] = line.split("\t");
  return makeMatch(key, module, fn, bindings ?? "", instructions ?? "");
}

/** A match of its parts as metaphir-match prints them: bindings like
 * "{?x = %a}", instructions like "{%r@1 = #0}". */
export function makeMatch(
  key: number,
  module: string,
  fn: string,
  bindings: string,
  instructions: string,
): Match {
  return {
    key,
    module,
    fn,
    bindings,
    instructions: [...instructions.matchAll(/([^\s,{}@]+)(?:@(\d+))? = #(\d+)/g)].map((m) => ({
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
 * None of the examples (eval/patterns) has as many: the most, pr210499,
 * has 148,678 of the published corpus.
 */
export const CANDIDATE_PROMPT = 200_000;

/** "1 match", "2 matches". */
export function count(n: number, noun: string, plural = `${noun}s`): string {
  return `${n.toLocaleString()} ${n === 1 ? noun : plural}`;
}

/** Why a query is paused: it reached a number of matches, or it would
 * check many candidates. */
export type Pause =
  | { kind: "matches"; matches: number }
  | { kind: "candidates"; candidates: number };

/** Rejected functions kept per constraint, to be looked at. */
export const REJECTION_SAMPLES = 10;

/** What tells rejecting constraints apart: the same one, at the same place. */
export const rejectionKey = (r: Rejected) => `${r.line}:${r.column}:${r.message}`;

/** A constraint that rejected the structural matches of functions. */
export interface Rejection extends Rejected {
  /** How many functions it rejected. */
  functions: number;
  /** The first REJECTION_SAMPLES of them, each as the structural match
   * the constraint rejected. */
  samples: Match[];
}

export interface Progress {
  /** What the query does, or "done" or "stopped" once it ended. */
  stage: string;
  /** The warnings the pattern was compiled with. */
  warnings: Note[];
  /** The constraints that rejected structural matches, in order found. */
  rejections: Rejection[];
  /** Why the query is paused, while it is. */
  paused?: Pause;
  /** How far the stage is, from 0 to 1, when that is known. */
  fraction?: number;
  /** The corpus: its modules and functions. */
  modules: number;
  functions: number;
  /** The functions on the posting lists the index chose, once read. */
  candidates?: number;
  /** Those of them whose features may match, once read: those checked. */
  matchable?: number;
  /** The functions checked so far. */
  checked: number;
  /** The functions checked with a structural match, satisfying the
   * constraints or not. */
  structural: number;
  /** The matches, which satisfy the constraints, and the functions they
   * are in. */
  matches: number;
  matched: number;
  requests: number;
  bytes: number;
  seconds: number;
}

export class PublishedCorpus {
  readonly functions: number;
  readonly modules: number;
  readonly id: string;
  readonly label: string;
  private readonly fetcher: RangeFetcher;
  private readonly pool: SessionPool;

  /** A corpus read by fetcher, as open() opens the one configured. */
  constructor(
    fetcher: RangeFetcher,
    pool: SessionPool,
    functions: number,
    modules: number,
    id = "",
    label = "",
  ) {
    this.fetcher = fetcher;
    this.pool = pool;
    this.functions = functions;
    this.modules = modules;
    this.id = id;
    this.label = label;
  }

  /** Opens a configured corpus, with a worker per core (up to 8). */
  static async open(
    corpus: CorpusConfig,
    signal?: AbortSignal,
  ): Promise<PublishedCorpus> {
    const aborted = () => new DOMException("Aborted", "AbortError");
    if (signal?.aborted) throw aborted();
    const base = corpus.data.replace(/\/$/, "");
    const manifest = await (
      await fetch(`${base}/manifest.json`, { cache: "no-cache", signal })
    ).json();
    if (signal?.aborted) throw aborted();
    const fetcher = await RangeFetcher.open(corpus.data, corpus.id, manifest.build);
    const header = await fetcher.fetchFile("header.bin.zst");
    if (signal?.aborted) throw aborted();
    const workers = Math.max(1, Math.min(navigator.hardwareConcurrency || 4, 8));
    const { pool, functions, modules } = await SessionPool.start(
      workers,
      wasmUrl("metaphir.js"),
      header,
    );
    if (signal?.aborted) {
      pool.dispose();
      throw aborted();
    }
    return new PublishedCorpus(
      fetcher,
      pool,
      functions,
      modules,
      corpus.id,
      corpus.label,
    );
  }

  /** Stops this corpus's workers; its IndexedDB cache is kept. */
  dispose(): void {
    this.pool.dispose();
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
    const rejections = new Map<string, Rejection>();
    const progress: Progress = {
      stage: "starting",
      warnings: [],
      rejections: [],
      modules: this.modules,
      functions: this.functions,
      checked: 0,
      structural: 0,
      matches: 0,
      matched: 0,
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
    const packs = new Map<number, Matchable>();
    const irOf = (fn: number) => async () => {
      const pack = packs.get(fn)!;
      let frame: Uint8Array | undefined;
      await fetcher.fetchRanges([pack], (_, bytes) => (frame = bytes));
      const printed = await pool.coordinator.printFunction(frame!, pack.slot);
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
        progress.candidates = candidates;
        if (candidates > CANDIDATE_PROMPT)
          pause({ kind: "candidates", candidates });
      },
      onCandidates: (candidates: number, matchable: Matchable[]) => {
        progress.candidates = candidates;
        progress.matchable = matchable.length;
        for (const m of matchable) packs.set(m.function, m);
      },
      onCompiled: (warnings: Note[]) => {
        progress.warnings = warnings;
      },
      onMatched: (
        fn: number,
        lines: string,
        rejected: Rejected[],
        structural: boolean,
        where?: { module: string; name: string },
      ) => {
        progress.checked++;
        if (structural) progress.structural++;
        // A constraint of several variants counts once per function.
        const counted = new Set<string>();
        for (const r of rejected) {
          const key = rejectionKey(r);
          if (counted.has(key)) continue;
          counted.add(key);
          let known = rejections.get(key);
          if (known) {
            known.functions++;
            known.reason ||= r.reason;
          } else {
            known = { ...r, functions: 1, samples: [] };
            rejections.set(key, known);
          }
          // The function, opened with the structural match rejected.
          if (where && known.samples.length < REJECTION_SAMPLES)
            known.samples.push({
              ...makeMatch(fn, where.module, where.name, r.bindings ?? "", r.instructions ?? ""),
              ir: irOf(fn),
            });
        }
        if (rejected.length)
          progress.rejections = [...rejections.values()].map((r) => ({
            ...r,
            samples: [...r.samples],
          }));
        const found = lines
          .split("\n")
          .filter(Boolean)
          .map((line, i) => ({ ...parseMatch(fn + i / 1e6, line), ir: irOf(fn) }));
        progress.matches += found.length;
        if (found.length) progress.matched++;
        progress.fraction = progress.checked / Math.max(progress.matchable ?? 0, 1);
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
