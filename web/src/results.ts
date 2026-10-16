// What a source has found (the corpus or your IR): each keeps
// its own, so switching between them shows each's last results again.

import { useState } from "react";
import type { Diagnostic } from "./diagnostics.ts";
import type { Match } from "./engine.ts";
import type { Status } from "./status.ts";
import type { FunctionResult } from "./yourIR.ts";

export function useResults(initial: Status) {
  const [matches, setMatches] = useState<Match[]>([]);
  const [selected, setSelected] = useState<Match>();
  // The functions without a match, and why (your IR).
  const [misses, setMisses] = useState<FunctionResult[]>([]);
  const [status, setStatus] = useState<Status>(initial);
  // The pattern as last matched, whose lines the matches refer to.
  const [matchedPattern, setMatchedPattern] = useState<string>();
  // What the last run found wrong, until the pattern is edited.
  const [diagnostics, setDiagnostics] = useState<Diagnostic[]>([]);
  // Whether a run is going on: one per source at a time.
  const [running, setRunning] = useState(false);
  return {
    running,
    setRunning,
    matches,
    setMatches,
    selected,
    setSelected,
    misses,
    setMisses,
    status,
    setStatus,
    matchedPattern,
    setMatchedPattern,
    diagnostics,
    setDiagnostics,
  };
}

export type Results = ReturnType<typeof useResults>;
