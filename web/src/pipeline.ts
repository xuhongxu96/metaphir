// Runs a query against a published corpus: each stage of the WebAssembly
// session says which bytes the next one reads, which the fetcher reads and
// hands back. The functions that may match are then matched as their packs
// arrive, by as many matchers as there are.

import type { ByteRange, RangeFetcher } from "./fetcher.ts";

export type StageResult = { ranges: ByteRange[] } | { error: string };
export type MatchResult = { lines: string } | { error: string };

export interface Matchable extends ByteRange {
  function: number;
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
  match(fn: number, frame: Uint8Array): Promise<MatchResult>;
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

export interface QueryEvents {
  /** A stage started. */
  onStage?(description: string): void;
  /** Bytes of the current stage read over the network, of those to read. */
  onFetch?(read: number, total: number): void;
  /** The functions on the lists, and those whose features may match. */
  onCandidates?(candidates: number, matchable: Matchable[]): void;
  /** Function was matched; lines are its matches, possibly none. */
  onMatched?(fn: number, lines: string): void;
}

/** Packs read per batch, so matching starts before all have arrived. */
const PACK_BATCH = 256;

export async function runQuery(
  pattern: string,
  name: string,
  coordinator: Coordinator,
  matchers: Matcher[],
  fetcher: RangeFetcher,
  events: QueryEvents = {},
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
  for (const [stage, description] of STAGES) {
    events.onStage?.(description);
    await read(ranges);
    ranges = check(await coordinator.stage(stage));
  }
  const matchable = await coordinator.matchable();
  events.onCandidates?.(await coordinator.numCandidates(), matchable);
  events.onStage?.("matching");

  // Each matcher takes the next pack once it is done with its last.
  const queue: { fn: number; frame: Uint8Array }[] = [];
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
      if (failure) return;
      const next = queue.shift();
      if (!next) {
        if (!reading) return;
        await new Promise<void>((resolve) => waiting.push(resolve));
        continue;
      }
      const result = await matcher.match(next.fn, next.frame);
      if ("error" in result) {
        failure ??= new Error(result.error);
        wakeAll();
        return;
      }
      events.onMatched?.(next.fn, result.lines);
    }
  };
  const workers = matchers.map(work);
  const byOffset = new Map(matchable.map((m) => [m.offset, m.function]));
  try {
    for (let start = 0; start < matchable.length && !failure; start += PACK_BATCH)
      await fetcher.fetchRanges(
        matchable.slice(start, start + PACK_BATCH),
        (range, frame) => {
          queue.push({ fn: byOffset.get(range.offset)!, frame });
          wakeAll();
        },
      );
  } finally {
    reading = false;
    wakeAll();
  }
  await Promise.all(workers);
  if (failure) throw failure;
}
