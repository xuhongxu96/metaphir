// Searching the matches: each word of the query must be found, whatever
// its case, in the match's module, function or bindings.

import type { Match } from "./engine.ts";

export function filterMatches(matches: Match[], query: string): Match[] {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return matches;
  return matches.filter((match) => {
    const text = `${match.module}\t${match.fn}\t${match.bindings}`.toLowerCase();
    return words.every((word) => text.includes(word));
  });
}
