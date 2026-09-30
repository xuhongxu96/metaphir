// Links to a pattern carry it in the hash: "#patternz=<compressed>" (see
// patternCompress.ts), or "#pattern=<URL-encoded text>" where the browser
// cannot compress, as links did before.

import { canCompress, compressPattern, decompressPattern } from "./patternCompress.ts";

/** The hash of a link to pattern. */
export async function patternHash(pattern: string, compress = canCompress()): Promise<string> {
  if (compress) {
    try {
      return `#patternz=${await compressPattern(pattern)}`;
    } catch {
      // The text, then.
    }
  }
  return `#pattern=${encodeURIComponent(pattern)}`;
}

/** The pattern a link's hash carries, if it carries one that reads. */
export async function readPatternHash(hash: string): Promise<string | undefined> {
  const [, key, value] = /^#(patternz?)=(.*)$/s.exec(hash) ?? [];
  try {
    if (key === "patternz") return await decompressPattern(value);
    if (key === "pattern") return decodeURIComponent(value);
  } catch {
    // Not a link of ours.
  }
  return undefined;
}
