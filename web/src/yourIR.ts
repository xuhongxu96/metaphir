// Matching IR written in the page: metaphir-match, built for WebAssembly,
// runs on it as a module of its own, once for the matches and the
// instructions they matched, and once for its report of each function: why
// one has no match.

import { instructionLines, parseMatch, wasmUrl, type Match } from "./engine.ts";
import { matchLocalFiles } from "./local.ts";

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

/** What matching did in a function of the IR. */
export interface FunctionResult {
  /** The function, as "@name". */
  fn: string;
  matches: number;
  /** For a function without a match: the constraints that rejected its
   * structural matches, each with why it could not be evaluated, if it
   * could not. None means the pattern's instructions are not there. */
  rejected: { constraint: string; reason: string }[];
}

/** The functions of metaphir-match's full report, in order. */
export function parseReport(report: string): FunctionResult[] {
  const functions: FunctionResult[] = [];
  for (const line of report.split("\n")) {
    const target = /^target \d+: (@\S+)$/.exec(line);
    if (target) {
      functions.push({ fn: target[1], matches: 0, rejected: [] });
      continue;
    }
    const current = functions.at(-1);
    if (!current) continue;
    if (/^ {2}match \d+:$/.test(line)) current.matches++;
    const rejected = /^ {2}constraint not satisfied: (.*?)(?: \(cannot evaluate: (.*)\))?$/.exec(
      line,
    );
    if (rejected) current.rejected.push({ constraint: rejected[1], reason: rejected[2] ?? "" });
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
  const found = await matchLocalFiles(url, files, pattern);
  if (found.status !== 0) throw new Error(named(found.err) || `failed (${found.status})`);
  const report = await matchLocalFiles(url, files, pattern, undefined, /*full=*/ true);
  if (report.status !== 0) throw new Error(named(report.err) || `failed (${report.status})`);
  const matches = found.out
    .split("\n")
    .filter(Boolean)
    .map((line, i) => {
      const match = parseMatch(i, line);
      const lines = moduleInstructionLines(ir, match.fn);
      match.ir = async () => ({ text: ir, lines });
      return match;
    });
  return { matches, functions: parseReport(report.out), messages: named(found.err) };
}
