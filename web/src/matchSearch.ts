// Searching the matches. A binding in the query, "?a = %x" or "?a=%x",
// must be one of the match's bindings: the variable bound to that value,
// whatever its case (a value with spaces is written in double quotes).
// Each other word must be found, whatever its case, in the match's module,
// function or bindings.

import { splitBindings } from "./bindings.ts";
import type { Match } from "./engine.ts";

const BINDING = /(\?[\w.]+)\s*=\s*("[^"]*"|[^\s,}]+)/g;

export function filterMatches(matches: Match[], query: string): Match[] {
  const lower = query.toLowerCase();
  const pairs = [...lower.matchAll(BINDING)].map(
    ([, variable, value]) => `${variable} = ${value.replace(/^"(.*)"$/, "$1")}`,
  );
  const words = lower.replace(BINDING, " ").split(/\s+/).filter(Boolean);
  if (!pairs.length && !words.length) return matches;
  return matches.filter((match) => {
    const bindings = new Set(splitBindings(match.bindings.toLowerCase()));
    const text = `${match.module}\t${match.fn}\t${match.bindings}`.toLowerCase();
    return pairs.every((pair) => bindings.has(pair)) && words.every((word) => text.includes(word));
  });
}

/** Where a match is among those that print the same: the same module,
 * function and bindings, but other instructions matched (ones no variable
 * captures). */
export interface Lookalike {
  /** From 1. */
  index: number;
  count: number;
}

/** The matches that print like others, each with where it is among them. */
export function lookalikes(matches: Match[]): Map<Match, Lookalike> {
  const groups = new Map<string, Match[]>();
  for (const match of matches) {
    const key = `${match.module}\t${match.fn}\t${match.bindings}`;
    const group = groups.get(key);
    if (group) group.push(match);
    else groups.set(key, [match]);
  }
  const result = new Map<Match, Lookalike>();
  for (const group of groups.values())
    if (group.length > 1)
      group.forEach((match, i) => result.set(match, { index: i + 1, count: group.length }));
  return result;
}
