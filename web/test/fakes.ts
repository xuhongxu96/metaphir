// A published corpus in memory, for running queries without WebAssembly or
// a server: every function is a candidate and matchable, and each has one
// match. Its packs are perFrame to a frame.

import type { Block } from "../src/blocks.ts";
import type { ByteRange } from "../src/fetcher.ts";
import type {
  Coordinator,
  Matchable,
  Matcher,
  MatchResult,
  StageName,
  StageResult,
} from "../src/pipeline.ts";

const range = (offset: number): ByteRange => ({ file: "packs.bin", offset, size: 1 });

export class FakeCorpus {
  /** The stages run, in order. */
  readonly stages: StageName[] = [];
  /** The functions matched, in order, and the slots they were matched at. */
  readonly matched: number[] = [];
  readonly slots: number[] = [];
  /** The frames read, by offset. */
  readonly read: number[] = [];
  readonly stats = { requests: 0, bytes: 0, throttled: 0 };

  readonly functions: number;
  readonly perFrame: number;

  constructor(functions: number, perFrame = 1) {
    this.functions = functions;
    this.perFrame = perFrame;
  }

  get coordinator(): Coordinator {
    return {
      compile: async () => ({ ranges: [range(0)] }),
      stage: async (name: StageName): Promise<StageResult> => {
        this.stages.push(name);
        return { ranges: [range(0)] };
      },
      add: async () => {},
      matchable: async (): Promise<Matchable[]> =>
        Array.from({ length: this.functions }, (_, fn) => ({
          ...range(Math.floor(fn / this.perFrame)),
          function: fn,
          slot: fn % this.perFrame,
        })),
      numCandidates: async () => this.functions,
    };
  }

  matcher(): Matcher {
    return {
      compile: async () => ({ ranges: [] }),
      match: async (fn: number, _: Uint8Array, slot: number): Promise<MatchResult> => {
        this.matched.push(fn);
        this.slots[fn] = slot;
        return { lines: `m.bc\t@f${fn}\t{}\n` };
      },
    };
  }

  /** Reads every range as one byte, a block per range. */
  get fetcher() {
    return {
      stats: this.stats,
      fetchBlocks: async (
        ranges: ByteRange[],
        onBlock: (block: Block, within: ByteRange[]) => void,
        onFetch?: (read: number, total: number) => void,
      ) => {
        ranges.forEach((r, i) => {
          onBlock({ file: r.file, start: r.offset, bytes: new Uint8Array(r.size) }, [r]);
          onFetch?.(i + 1, ranges.length);
        });
      },
      fetchRanges: async (
        ranges: ByteRange[],
        onRange: (range: ByteRange, bytes: Uint8Array) => void,
      ) => {
        for (const r of ranges) {
          this.read.push(r.offset);
          onRange(r, new Uint8Array(r.size));
        }
      },
    };
  }
}

/** Resolves once nothing already queued is left to run. */
export const settle = () => new Promise<void>((resolve) => setTimeout(resolve, 10));
