// Going from a name Ctrl/⌘+clicked to the matched function's IR. In the
// pattern: a variable (?x) goes to where its value is defined, and an
// instruction's name (%a), or the opcode of one without a result, to the
// instruction it matched. In the IR: a value (%x) goes to where it is
// defined. Each link also says what it goes from, to underline.

import { bindingValue } from "./bindings.ts";
import { findDefinition, type Definition } from "./irDefinition.ts";

/** A pattern instruction and the IR instruction it matched, by line. */
export interface Link {
  name: string;
  /** In the pattern, unless the instruction is from a library. */
  patternLine?: number;
  /** In the matched function's IR. */
  irLine?: number;
}

/** The lines links have in the pattern or in the IR. */
export function linkLines(links: Link[], side: "patternLine" | "irLine"): number[] {
  return links.flatMap((link) => (link[side] ? [link[side]] : []));
}

/** Text of a line, from column (from 1). */
export interface Span {
  column: number;
  length: number;
}

const span = ({ column, length }: Span): Span => ({ column, length });

/** What a click goes from, on its line, and where to in the IR. */
export interface NavLink {
  from: Span;
  to: Definition;
}

const NAME = /[?%@](?:"[^"]*"|[-\w.$]+)/g;
const WORD = /[A-Za-z_][\w.]*/g;

/**
 * The name (?x, %a or @g) at column of text, or just before it, where a
 * click after its last character lands.
 */
export function tokenAt(text: string, column: number): (Span & { text: string }) | undefined {
  return matchAt(NAME, text, column);
}

/** What of pattern is at column of text, or just before it. */
function matchAt(pattern: RegExp, text: string, column: number) {
  const at = column - 1;
  for (const found of text.matchAll(pattern))
    if (found.index <= at && at <= found.index + found[0].length)
      return { text: found[0], column: found.index + 1, length: found[0].length };
  return undefined;
}

/** The instruction on line of ir, without its indentation. */
function instructionAt(ir: string, line: number): Definition {
  const text = ir.split("\n")[line - 1] ?? "";
  const start = text.length - text.trimStart().length;
  return { line, column: start + 1, length: text.trim().length };
}

export function patternLink(click: {
  line: number;
  column: number;
  /** The text of the line. */
  text: string;
  links: Link[];
  bindings: string;
  ir: string;
}): NavLink | undefined {
  const { line, column, text, links, bindings, ir } = click;
  const token = tokenAt(text, column);
  if (token?.text.startsWith("?")) {
    const value = bindingValue(bindings, token.text);
    const to = value === undefined ? undefined : findDefinition(ir, value);
    return to && { from: span(token), to };
  }
  if (token?.text.startsWith("%")) {
    const link = links.find((l) => l.name === token.text && l.irLine);
    return link && { from: span(token), to: instructionAt(ir, link.irLine!) };
  }
  // An instruction without a result is named by its opcode, on its line.
  const word = token ? undefined : matchAt(WORD, text, column);
  const link =
    word && links.find((l) => l.name === word.text && l.patternLine === line && l.irLine);
  return link && { from: span(word!), to: instructionAt(ir, link.irLine!) };
}


export function irLink(click: { column: number; text: string; ir: string }): NavLink | undefined {
  const token = tokenAt(click.text, click.column);
  const to = token?.text.startsWith("%") ? findDefinition(click.ir, token.text) : undefined;
  return token && to ? { from: span(token), to } : undefined;
}
