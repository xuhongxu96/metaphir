// Going from a name Ctrl/⌘+clicked in a pattern to where it is defined: a
// composite matcher ('match name'), a metaflag ('metaflag :name') or a
// constraint ('constraint name'), in the pattern itself or in stdlib.mpir.

import type { Definition } from "./irDefinition.ts";
import { wordAt, type NavLink } from "./navigation.ts";

export type DefinitionKind = "matcher" | "metaflag" | "constraint";

/** Where a name is defined, and as what. */
export interface NamedDefinition extends Definition {
  kind: DefinitionKind;
  name: string;
}

const KINDS: Record<string, DefinitionKind> = {
  match: "matcher",
  metaflag: "metaflag",
  constraint: "constraint",
};
// 'match:c name', 'metaflag:i:o :name(...)', 'constraint name(...)'.
const DEFINITION = /^(\s*(match|metaflag|constraint)(?::\w+)*\s+:?)([A-Za-z_][\w.]*)/;

/** The definitions in the text of a pattern or library, in order. */
export function definitionsIn(text: string): NamedDefinition[] {
  const definitions: NamedDefinition[] = [];
  text.split("\n").forEach((line, i) => {
    const found = DEFINITION.exec(line);
    if (found)
      definitions.push({
        kind: KINDS[found[2]],
        name: found[3],
        line: i + 1,
        column: found[1].length + 1,
        length: found[3].length,
      });
  });
  return definitions;
}

/** The name at column of a line (or just before it), and what it names by
 * where it is: after ':' a metaflag, before '(' a constraint, else a
 * matcher. */
export function referenceAt(
  text: string,
  column: number,
): { kind: DefinitionKind; name: string; column: number; length: number } | undefined {
  const word = wordAt(text, column);
  if (!word) return undefined;
  const before = text[word.column - 2] ?? "";
  // Part of a meta variable or value, such as ?x or %a: not a name.
  if (/[?%@$\w]/.test(before)) return undefined;
  const kind: DefinitionKind =
    before === ":"
      ? "metaflag"
      : /^\s*\(/.test(text.slice(word.column - 1 + word.length))
        ? "constraint"
        : "matcher";
  return { kind, name: word.text, column: word.column, length: word.length };
}

/** Where a definition is: in the pattern, or in the library. */
export type DefinitionFile = "pattern" | "stdlib";

/** The link from the name at column of a line to its definition: the first
 * of files (in order) defining it as what it names. */
export function definitionLink(
  text: string,
  column: number,
  files: [DefinitionFile, NamedDefinition[]][],
): (NavLink & { file: DefinitionFile }) | undefined {
  const reference = referenceAt(text, column);
  if (!reference) return undefined;
  for (const [file, definitions] of files) {
    const to = definitions.find((d) => d.kind === reference.kind && d.name === reference.name);
    if (to)
      return {
        file,
        from: { column: reference.column, length: reference.length },
        to: { line: to.line, column: to.column, length: to.length },
      };
  }
  return undefined;
}
