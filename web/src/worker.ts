// A Web Worker with a Session of its own: the pool sends it method calls
// and it answers each with the result.

import { loadModule, runStage, type Session } from "./session.ts";

let session: Session | undefined;

type Call = { id: number; method: string; args: unknown[] };

const methods: Record<string, (...args: any[]) => unknown> = {
  async init(moduleUrl: string, header: Uint8Array, mode = 0) {
    const module = await loadModule(moduleUrl);
    session = new module.Session(header);
    session.setMode(mode);
    const error = session.error();
    if (error) throw new Error(error);
    return { functions: session.numFunctions(), modules: session.numModules() };
  },
  compile: (pattern: string, name: string) => session!.compile(pattern, name),
  stage: (name) => runStage(session!, name),
  add: (file: string, offset: number, bytes: Uint8Array) =>
    session!.add(file, offset, bytes),
  matchable: () => session!.matchable(),
  numCandidates: () => session!.numCandidates(),
  match: (fn: number, frame: Uint8Array, slot: number) => session!.match(fn, frame, slot),
  moduleOf: (fn: number) => session!.moduleOf(fn),
  printFunction: (frame: Uint8Array, slot: number) => session!.printFunction(frame, slot),
};

self.onmessage = async (event: MessageEvent<Call>) => {
  const { id, method, args } = event.data;
  try {
    const result = await methods[method](...args);
    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({ id, error: String((error as Error).message ?? error) });
  }
};
