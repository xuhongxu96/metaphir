// What the page shows of a query: a line, its numbers and how far it is.

import { count, type Pause, type Progress } from "./engine.ts";

export interface Status {
  /** What is going on, or what went wrong. */
  text: string;
  /** Labelled values, such as how many matches there are. */
  details?: [string, string][];
  /** How many matches there are so far. */
  matches?: number;
  error?: boolean;
  /** How far a run is, from 0 to 1; undefined while not known. */
  fraction?: number;
  running?: boolean;
  /** Why a running query waits to be continued or stopped. */
  pause?: Pause;
}

function headline(progress: Progress): string {
  const pause = progress.paused;
  if (!pause) return progress.stage;
  // The matches of the functions being matched when the query paused are
  // counted too, so the line says what the counter does.
  return pause.kind === "matches"
    ? `paused at ${count(progress.matches, "match", "matches")}`
    : `paused: ${count(pause.candidates, "candidate function")}`;
}

/** The status of a query, of local files or of the published corpus. */
export function describe(progress: Progress, local: boolean): Status {
  const details: [string, string][] = [];
  if (!local && progress.matchable)
    details.push([
      "functions",
      `${progress.matched.toLocaleString()} of ${progress.matchable.toLocaleString()} matched`,
    ]);
  details.push(["matches", progress.matches.toLocaleString()]);
  if (!local) details.push(["read", `${(progress.bytes / 1e6).toFixed(1)} MB`]);
  details.push(["time", `${progress.seconds.toFixed(1)} s`]);
  return {
    text: headline(progress),
    details,
    matches: progress.matches,
    fraction: progress.fraction,
    running: progress.stage !== "done" && progress.stage !== "stopped",
    pause: progress.paused,
  };
}
