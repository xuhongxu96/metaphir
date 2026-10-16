// Matching IR written in the page: metaphir-match, built for WebAssembly,
// runs on it as a module of its own, once for the matches and the
// instructions they matched, and once for its report of each function: why
// one has no match (--explain).

import { instructionLines, makeMatch, parseMatch, wasmUrl, type Match } from "./engine.ts";
import { runMatcher } from "./wasmMatcher.ts";

/** The name of the IR in diagnostics. */
export const IR_FILE = "your.ll";

/** The IR the page starts with. */
export const SAMPLE_IR = `define i32 @inc(i32 %a) {
  %r = add i32 %a, 1
  ret i32 %r
}

define i32 @add2(i32 %a) {
  %r = add i32 %a, 2
  ret i32 %r
}
`;

/** A constraint that rejected a function's structural matches. */
export interface RejectedBy {
  constraint: string;
  /** Why it could not be evaluated; empty if it was false. */
  reason: string;
  /** The first structural match it rejected, as metaphir-match prints a
   * match: its bindings, and the instructions it matched. */
  bindings: string;
  instructions: string;
  /** That match, to open (see rejectedMatch). */
  match?: Match;
}

/** What matching did in a function of the IR. */
export interface FunctionResult {
  /** The function, as "@name". */
  fn: string;
  matches: number;
  /** For a function without a match: the constraints that rejected its
   * structural matches, if it has any. */
  rejected: RejectedBy[];
  /** Else, why it has no structural match. */
  structure: string[];
  /** The function, to open without anything matched. */
  open?: Match;
}

/** The functions of metaphir-match --explain's report, in order. */
export function parseReport(report: string): FunctionResult[] {
  const functions: FunctionResult[] = [];
  for (const line of report.split("\n")) {
    const target = /^target \d+: (@\S+)$/.exec(line);
    if (target) {
      functions.push({ fn: target[1], matches: 0, rejected: [], structure: [] });
      continue;
    }
    const current = functions.at(-1);
    if (!current) continue;
    if (/^ {2}match \d+:$/.test(line)) current.matches++;
    const rejected = /^ {2}constraint not satisfied: (.*?)(?: \(cannot evaluate: (.*)\))?$/.exec(
      line,
    );
    if (rejected)
      current.rejected.push({
        constraint: rejected[1],
        reason: rejected[2] ?? "",
        bindings: "",
        instructions: "",
      });
    const match = /^ {4}rejected: ([^\t]*)\t?(.*)$/.exec(line);
    const last = current.rejected.at(-1);
    if (match && last) {
      last.bindings = match[1];
      last.instructions = match[2];
    }
    const structure = /^ {2}no structural match: (.*)$/.exec(line);
    if (structure) current.structure.push(structure[1]);
  }
  return functions;
}

/** The line, from 1, where fn (as "@name") is defined in module. */
export function definitionLine(module: string, fn: string): number | undefined {
  const index = module
    .split("\n")
    .findIndex((line) => line.startsWith("define ") && line.includes(`${fn}(`));
  return index < 0 ? undefined : index + 1;
}

/** The lines of fn's instructions in module, counted in the module. */
export function moduleInstructionLines(module: string, fn: string): number[] {
  const start = definitionLine(module, fn);
  if (start === undefined) return [];
  const lines = module.split("\n").slice(start - 1);
  const end = lines.findIndex((line) => line.startsWith("}"));
  const body = lines.slice(0, end < 0 ? undefined : end + 1).join("\n");
  return instructionLines(body).map((line) => line + start - 1);
}

export interface IRResult {
  matches: Match[];
  functions: FunctionResult[];
  /** What metaphir-match said besides, such as the pattern's warnings. */
  messages: string;
}

/** The tool's messages, with the files named as the page names them. */
const named = (text: string) =>
  text
    .replace(/^this\.program: /gm, "")
    .replaceAll("/corpus/", "")
    .replaceAll("/pattern.mpir", "pattern.mpir");

/** Matches pattern in ir; throws the tool's errors, for the IR or pattern. */
export async function matchYourIR(ir: string, pattern: string): Promise<IRResult> {
  const files = [{ path: IR_FILE, bytes: new TextEncoder().encode(ir) }];
  const url = wasmUrl("metaphir-match.js");
  // The two runs are independent, each in a module instance of its own.
  const [found, report] = await Promise.all([
    runMatcher(url, files, pattern),
    runMatcher(url, files, pattern, /*explain=*/ true),
  ]);
  for (const run of [found, report])
    if (run.status !== 0) throw new Error(named(run.err) || `failed (${run.status})`);
  const matches = found.out
    .split("\n")
    .filter(Boolean)
    .map((line, i) => withIR(parseMatch(i, line), ir));
  const functions = parseReport(report.out);
  let key = 0;
  for (const f of functions) {
    // The function opened whole: each of its instructions highlighted.
    const whole = makeMatch(key++, IR_FILE, f.fn, "", "");
    whole.instructions = moduleInstructionLines(ir, f.fn).map((_, position) => ({
      name: "",
      position,
    }));
    f.open = withIR(whole, ir);
    for (const by of f.rejected)
      by.match = withIR(makeMatch(key++, IR_FILE, f.fn, by.bindings, by.instructions), ir);
  }
  return { matches, functions, messages: named(found.err) };
}

/** Match, opened in ir, the module it is in. */
function withIR(match: Match, ir: string): Match {
  const lines = moduleInstructionLines(ir, match.fn);
  return { ...match, ir: async () => ({ text: ir, lines }) };
}
