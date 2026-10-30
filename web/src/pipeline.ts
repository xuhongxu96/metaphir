// Runs a query against a published corpus: each stage of the WebAssembly
// session says which bytes the next one reads, which the fetcher reads and
// hands back. The functions that may match are then matched as the frames
// holding their packs arrive, by as many matchers as there are. A QueryControl pauses or stops
// the query between stages and between the functions it matches.

import type { ByteRange, RangeFetcher } from "./fetcher.ts";

/** Something said about the pattern, at its line and column (from 1), or
 * at 0 and 0 when not in the pattern. */
export interface Note {
  message: string;
  line: number;
  column: number;
}

/** A constraint, printed, that rejected all the structural matches of a
 * function; reason says why it could not be evaluated, or is empty if it
 * was false. */
export interface Rejected extends Note {
  reason: string;
  /** The first structural match it rejected, printed as a match is (see
   * parseMatch): its bindings and the instructions it matched. */
  bindings?: string;
  instructions?: string;
}

/** What a stage reads next; compiling also gives the pattern's warnings. */
export type StageResult = { ranges: ByteRange[]; warnings?: Note[] } | { error: string };
/** A function's matches; and if it has none, the constraints that rejected
 * its structural matches, with the module and name of the function; and
 * whether it has any structural match. */
export type MatchResult =
  | {
      lines: string;
      rejected?: Rejected[];
      structural?: boolean;
      module?: string;
      function?: string;
    }
  | { error: string };

/** A function whose features may match: the frame of packs its pack is
 * in, and its slot in the frame. */
export interface Matchable extends ByteRange {
  function: number;
  slot: number;
}

/** The session that runs the stages. */
export interface Coordinator {
  compile(pattern: string, name: string): Promise<StageResult>;
  stage(name: StageName): Promise<StageResult>;
  add(file: string, offset: number, bytes: Uint8Array): Promise<void>;
  matchable(): Promise<Matchable[]>;
  numCandidates(): Promise<number>;
}

/** A session that matches functions, one at a time. */
export interface Matcher {
  compile(pattern: string, name: string): Promise<StageResult>;
  match(fn: number, frame: Uint8Array, slot: number): Promise<MatchResult>;
}

export type StageName =
  | "findLists"
  | "findCandidates"
  | "findFeatures"
  | "filterCandidates";

const STAGES: [StageName, string][] = [
  ["findLists", "reading the posting keys"],
  ["findCandidates", "reading the posting lists"],
  ["findFeatures", "reading the candidates' index entries"],
  ["filterCandidates", "reading the candidates' features"],
];

/**
 * Pauses, resumes and stops a query from outside it: the query waits while
 * paused, before each stage and each function it matches, and ends once
 * stopped, when the functions being matched are. Once run to the end, it
 * pauses no more.
 */
export class QueryControl {
  private resumed?: Promise<void>;
  private wake?: () => void;
  private stop_ = false;
  private toEnd = false;

  get paused(): boolean {
    return this.resumed !== undefined;
  }
  get stopped(): boolean {
    return this.stop_;
  }

  pause(): void {
    if (!this.stop_ && !this.toEnd) this.resumed ??= new Promise((resolve) => (this.wake = resolve));
  }
  resume(): void {
    const wake = this.wake;
    this.resumed = this.wake = undefined;
    wake?.();
  }
  /** Resumes, and ignores pausing from now on. */
  runToEnd(): void {
    this.toEnd = true;
    this.resume();
  }
  stop(): void {
    this.stop_ = true;
    this.resume();
  }

  /** Waits while paused; whether the query goes on. */
  async proceed(): Promise<boolean> {
    while (this.resumed) await this.resumed;
    return !this.stop_;
  }
}

export interface QueryEvents {
  /** A stage started. */
  onStage?(description: string): void;
  /** Bytes of the current stage read over the network, of those to read. */
  onFetch?(read: number, total: number): void;
  /** The functions on the lists, before their features are read. */
  onListed?(candidates: number): void;
  /** The functions on the lists, and those whose features may match. */
  onCandidates?(candidates: number, matchable: Matchable[]): void;
  /** The pattern compiled, with these warnings. */
  onCompiled?(warnings: Note[]): void;
  /** A function could not be read or matched, such as one whose IR the
   * corpus holds but LLVM rejects; the query goes on without it. */
  onSkipped?(fn: number, message: string): void;
  /** Function was matched; lines are its matches, possibly none, and
   * rejected the constraints that rejected its structural matches, in the
   * function named where; structural tells whether it has any. */
  onMatched?(
    fn: number,
    lines: string,
    rejected: Rejected[],
    structural: boolean,
    where?: { module: string; name: string },
  ): void;
}

/** Frames of packs read per batch, so matching starts before all have
 * arrived. */
const PACK_BATCH = 256;

export async function runQuery(
  pattern: string,
  name: string,
  coordinator: Coordinator,
  matchers: Matcher[],
  fetcher: Pick<RangeFetcher, "fetchBlocks" | "fetchRanges">,
  events: QueryEvents = {},
  control = new QueryControl(),
): Promise<void> {
  const check = (result: StageResult): ByteRange[] => {
    if ("error" in result) throw new Error(result.error);
    return result.ranges;
  };
  // The session gets whole blocks, fewer than the ranges they hold.
  const read = async (ranges: ByteRange[]) => {
    const added: Promise<void>[] = [];
    await fetcher.fetchBlocks(
      ranges,
      (block) => {
        added.push(coordinator.add(block.file, block.start, block.bytes));
      },
      events.onFetch,
    );
    await Promise.all(added);
  };

  events.onStage?.("compiling the pattern");
  const compiled = await Promise.all([
    coordinator.compile(pattern, name),
    ...matchers.map((m) => m.compile(pattern, name)),
  ]);
  let ranges = check(compiled[0]);
  for (const result of compiled.slice(1)) check(result);
  // Every session compiled the same pattern, with the same warnings.
  events.onCompiled?.(("warnings" in compiled[0] && compiled[0].warnings) || []);
  for (const [stage, description] of STAGES) {
    if (!(await control.proceed())) return;
    events.onStage?.(description);
    await read(ranges);
    ranges = check(await coordinator.stage(stage));
    if (stage === "findCandidates") events.onListed?.(await coordinator.numCandidates());
  }
  if (!(await control.proceed())) return;
  const matchable = await coordinator.matchable();
  events.onCandidates?.(await coordinator.numCandidates(), matchable);
  events.onStage?.("matching");

  // Each matcher takes the next function once it is done with its last.
  const queue: { fn: number; frame: Uint8Array; slot: number }[] = [];
  let reading = true;
  let waiting: (() => void)[] = [];
  const wakeAll = () => {
    const woken = waiting;
    waiting = [];
    for (const resume of woken) resume();
  };
  let failure: Error | undefined;
  const work = async (matcher: Matcher) => {
    for (;;) {
      if (failure || !(await control.proceed())) return;
      const next = queue.shift();
      if (!next) {
        if (!reading) return;
        await new Promise<void>((resolve) => waiting.push(resolve));
        continue;
      }
      const result = await matcher.match(next.fn, next.frame, next.slot);
      if ("error" in result) {
        events.onSkipped?.(next.fn, result.error);
        continue;
      }
      const where =
        result.module !== undefined && result.function !== undefined
          ? { module: result.module, name: result.function }
          : undefined;
      events.onMatched?.(
        next.fn,
        result.lines,
        result.rejected ?? [],
        result.structural ?? false,
        where,
      );
    }
  };
  const workers = matchers.map(work);
  // A frame holds the packs of a few functions: it is read once, and each
  // of them matched.
  const frames = new Map<number, { range: Matchable; of: Matchable[] }>();
  for (const m of matchable) {
    const frame = frames.get(m.offset);
    if (frame) frame.of.push(m);
    else frames.set(m.offset, { range: m, of: [m] });
  }
  const toRead = [...frames.values()].map((f) => f.range);
  try {
    for (
      let start = 0;
      start < toRead.length && !failure && (await control.proceed());
      start += PACK_BATCH
    )
      await fetcher.fetchRanges(toRead.slice(start, start + PACK_BATCH), (range, frame) => {
        for (const m of frames.get(range.offset)!.of)
          queue.push({ fn: m.function, frame, slot: m.slot });
        wakeAll();
      });
  } finally {
    reading = false;
    wakeAll();
  }
  await Promise.all(workers);
  if (failure) throw failure;
}
