import assert from "node:assert/strict";
import { test } from "node:test";
import { definitionLine, moduleInstructionLines, parseReport } from "../src/yourIR.ts";

test("reads metaphir-match --explain's report of each function", () => {
  const report = [
    "target 0: @f",
    "  match 0:",
    "    {?c = 1, ?x = %a}",
    "  match 1:",
    "    {?c = 1, ?x = %b}",
    "target 1: @g",
    "  no match",
    "  constraint not satisfied: (== ?c 1)",
    "    rejected: {?c = 2, ?x = %a}\t{%r@1 = #0}",
    "  constraint not satisfied: (== (+ ?x 1) 2) (cannot evaluate: expected an integer)",
    "    rejected: {?c = 2, ?x = %a}\t{%r@1 = #0}",
    "target 2: @h",
    "  no match",
    "  no structural match: it has no `add`",
    "",
  ].join("\n");
  const rejected = (constraint: string, reason: string) => ({
    constraint,
    reason,
    bindings: "{?c = 2, ?x = %a}",
    instructions: "{%r@1 = #0}",
  });
  assert.deepEqual(parseReport(report), [
    { fn: "@f", matches: 2, rejected: [], structure: [] },
    {
      fn: "@g",
      matches: 0,
      rejected: [rejected("(== ?c 1)", ""), rejected("(== (+ ?x 1) 2)", "expected an integer")],
      structure: [],
    },
    { fn: "@h", matches: 0, rejected: [], structure: ["it has no `add`"] },
  ]);
});

test("counts a function's instruction lines in the module", () => {
  const module = [
    "; a module",
    "define i32 @f(i32 %a) {",
    "  %r = add i32 %a, 1",
    "  ret i32 %r",
    "}",
    "",
    "define i32 @g(i32 %a) {",
    "entry:",
    "  ret i32 %a",
    "}",
  ].join("\n");
  assert.equal(definitionLine(module, "@g"), 7);
  assert.deepEqual(moduleInstructionLines(module, "@f"), [3, 4]);
  assert.deepEqual(moduleInstructionLines(module, "@g"), [9]);
  assert.deepEqual(moduleInstructionLines(module, "@missing"), []);
});
