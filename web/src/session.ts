// The WebAssembly module's Session (see web/wasm/Bindings.cpp), and loading
// the module.

import type { Matchable, MatchResult, StageName, StageResult } from "./pipeline.ts";

export interface Session {
  error(): string;
  numFunctions(): number;
  numModules(): number;
  add(file: string, offset: number, bytes: Uint8Array): void;
  compile(pattern: string, name: string): StageResult;
  findLists(): StageResult;
  findCandidates(): StageResult;
  findFeatures(): StageResult;
  filterCandidates(): StageResult;
  numCandidates(): number;
  matchable(): Matchable[];
  match(fn: number, frame: Uint8Array, slot: number): MatchResult;
  moduleOf(fn: number): string;
  printFunction(frame: Uint8Array, slot: number): PrintedFunction | { error: string };
  delete(): void;
}

/** A function's IR, and the line of each of its instructions (from 1). */
export interface PrintedFunction {
  ir: string;
  lines: number[];
}

export interface MetaphIRModule {
  Session: new (header: Uint8Array) => Session;
}

export function runStage(session: Session, name: StageName): StageResult {
  return session[name]();
}

/** Where the module whose script is at url finds its files, such as its
 * .wasm: beside the script, with the same version (see wasmUrl). */
export const locateBeside = (url: string) => (path: string) => {
  // In tests, the script is a file path.
  if (!URL.canParse(url)) return url.slice(0, url.lastIndexOf("/") + 1) + path;
  const located = new URL(path, url);
  located.search = new URL(url).search;
  return located.href;
};

/** Loads the module built by scripts/build_wasm.sh from url. */
export async function loadModule(url: string): Promise<MetaphIRModule> {
  const { default: create } = await import(/* @vite-ignore */ url);
  return create({ locateFile: locateBeside(url) });
}
