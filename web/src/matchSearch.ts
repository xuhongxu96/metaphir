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
