// Workers, each with its own Session: the first coordinates the stages and
// they all match.

import type {
  Coordinator,
  Matchable,
  Matcher,
  MatchResult,
  StageName,
  StageResult,
} from "./pipeline.ts";
import type { PrintedFunction } from "./session.ts";

class WorkerSession implements Coordinator, Matcher {
  private next = 0;
  private pending = new Map<
    number,
    { resolve: (value: any) => void; reject: (error: Error) => void }
  >();

  private readonly worker: Worker;

  constructor(worker: Worker) {
    this.worker = worker;
    worker.onmessage = (event) => {
      const { id, result, error } = event.data;
      const call = this.pending.get(id)!;
      this.pending.delete(id);
      if (error !== undefined) call.reject(new Error(error));
      else call.resolve(result);
    };
  }

  call<T>(method: string, ...args: unknown[]): Promise<T> {
    const id = this.next++;
    return new Promise<T>((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.worker.postMessage({ id, method, args });
    });
  }

  compile = (pattern: string, name: string) =>
    this.call<StageResult>("compile", pattern, name);
  stage = (name: StageName) => this.call<StageResult>("stage", name);
  add = (file: string, offset: number, bytes: Uint8Array) =>
    this.call<void>("add", file, offset, bytes);
  matchable = () => this.call<Matchable[]>("matchable");
  numCandidates = () => this.call<number>("numCandidates");
  match = (fn: number, frame: Uint8Array) =>
    this.call<MatchResult>("match", fn, frame);
  moduleOf = (fn: number) => this.call<string>("moduleOf", fn);
  printFunction = (frame: Uint8Array) =>
    this.call<PrintedFunction | { error: string }>("printFunction", frame);
}

export class SessionPool {
  readonly sessions: WorkerSession[];

  private constructor(sessions: WorkerSession[]) {
    this.sessions = sessions;
  }

  /** Starts size workers, each reading the corpus's header. */
  static async start(
    size: number,
    moduleUrl: string,
    header: Uint8Array,
  ): Promise<{ pool: SessionPool; functions: number; modules: number }> {
    const sessions = Array.from(
      { length: size },
      () =>
        new WorkerSession(
          new Worker(new URL("./worker.ts", import.meta.url), {
            type: "module",
          }),
        ),
    );
    const info = await Promise.all(
      sessions.map((s) =>
        s.call<{ functions: number; modules: number }>(
          "init",
          moduleUrl,
          header,
        ),
      ),
    );
    return { pool: new SessionPool(sessions), ...info[0] };
  }

  get coordinator(): WorkerSession {
    return this.sessions[0];
  }
}
