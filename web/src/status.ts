// What the page shows of a query: a line, its numbers and how far it is.

import { count, rejectionKey, type Pause, type Progress, type Rejection } from "./engine.ts";
import { PAGE_SCHEME, type Diagnostic } from "./diagnostics.ts";
import type { Note } from "./pipeline.ts";

/** A labelled value, and what it means, said on hover; one of the values
 * above it at a lower level, which it is counted of, is shown indented. */
export interface Detail {
  label: string;
  value: string;
  hint?: string;
  level?: number;
}

export interface Status {
  /** What is going on, or what went wrong. */
  text: string;
  /** Labelled values, such as how many matches there are. */
  details?: Detail[];
  /** How many matches there are so far. */
  matches?: number;
  /** The pattern's warnings. */
  warnings?: Note[];
  /** The constraints that rejected structural matches. */
  rejections?: Rejection[];
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

/** The corpus's size, before a query narrows it. */
export const corpusDetails = (functions: number, modules: number): Detail[] => [
  { label: "modules in the corpus", value: modules.toLocaleString() },
  { label: "functions in the corpus", value: functions.toLocaleString() },
];

/** What matching found in the functions it checked, at level: how many
 * have a structural match, how many a match, and how many matches. */
export function matchDetails(
  level: number,
  structural: number,
  matched: number,
  matches: number,
): Detail[] {
  return [
    {
      label: "with a structural match",
      value: structural.toLocaleString(),
      hint: "Functions with an instance of the pattern's instructions, whether or not it satisfies the constraints.",
      level,
    },
    {
      label: "with a match",
      value: matched.toLocaleString(),
      hint: "Functions with an instance that satisfies the constraints too.",
      level: level + 1,
    },
    { label: "matches", value: matches.toLocaleString(), hint: "The instances in them." },
  ];
}

/** The status of a query of the published corpus: from the corpus to the
 * matches, each function counted of those above it. */
export function describe(progress: Progress): Status {
  const details = corpusDetails(progress.functions, progress.modules);
  if (progress.candidates !== undefined)
    details.push({
      label: "on the index's lists",
      value: progress.candidates.toLocaleString(),
      hint: "Functions with every instruction and operand of the pattern that the index lists.",
      level: 1,
    });
  if (progress.matchable !== undefined) {
    const checking = progress.checked < progress.matchable;
    details.push(
      {
        label: "whose features may match",
        value: progress.matchable.toLocaleString(),
        hint: "The functions whose features the pattern may match: those checked against it.",
        level: 2,
      },
      // While checking, what was found is of those checked so far.
      ...(checking
        ? [
            {
              label: "checked so far",
              value: progress.checked.toLocaleString(),
              hint: "The functions checked against the pattern so far.",
              level: 3,
            },
          ]
        : []),
      ...matchDetails(checking ? 4 : 3, progress.structural, progress.matched, progress.matches),
    );
  }
  details.push(
    { label: "read", value: `${(progress.bytes / 1e6).toFixed(1)} MB` },
    { label: "time", value: `${progress.seconds.toFixed(1)} s` },
  );
  return {
    text: headline(progress),
    details,
    matches: progress.matches,
    warnings: progress.warnings,
    rejections: progress.rejections,
    fraction: progress.fraction,
    running: progress.stage !== "done" && progress.stage !== "stopped",
    pause: progress.paused,
  };
}

/** Where rejecting constraints are counted, said beside them. */
export const INDEX_HINT = "Counted in the functions checked: those the index rules out are not.";

/** What a constraint that rejected structural matches did, in words. */
export function describeRejection(r: Rejection): string {
  const where = `in ${count(r.functions, "function")}`;
  return r.reason
    ? `${r.message} could not be evaluated ${where}: ${r.reason}`
    : `${r.message} rejected the structural matches ${where}`;
}

/** The page's link to the card of r in the Rejected tab. */
export const rejectionLink = (r: Rejection) =>
  `${PAGE_SCHEME}:rejection/${encodeURIComponent(rejectionKey(r))}`;

/** The rejection rejectionLink linked to, given the link's path. */
export function linkedRejection(rejections: Rejection[], path: string): Rejection | undefined {
  const key = /^rejection\/(.*)$/.exec(path)?.[1];
  return key === undefined ? undefined : rejections.find((r) => rejectionKey(r) === key);
}

/** The warnings and rejecting constraints of status, as diagnostics on the
 * pattern: a constraint that could not be evaluated is a warning. */
export function statusDiagnostics(status: Status): Diagnostic[] {
  const located = (note: Note) => note.line > 0;
  return [
    ...(status.warnings ?? []).filter(located).map((w) => ({
      line: w.line,
      column: w.column,
      severity: "warning" as const,
      message: w.message,
    })),
    ...(status.rejections ?? []).filter(located).map((r) => ({
      line: r.line,
      column: r.column,
      severity: r.reason ? ("warning" as const) : ("info" as const),
      message: describeRejection(r),
      link: { text: "show in Rejected", target: rejectionLink(r) },
    })),
  ];
}
