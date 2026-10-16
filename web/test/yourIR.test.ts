import assert from "node:assert/strict";
import { test } from "node:test";
import { definitionLine, moduleInstructionLines, parseReport } from "../src/yourIR.ts";

test("reads metaphir-match's report of each function", () => {
  const report = [
    "target 0: @f",
    "  match 0:",
    "    {?c = 1, ?x = %a}",
    "  match 1:",
    "    {?c = 1, ?x = %b}",
    "target 1: @g",
    "  no match",
    "  constraint not satisfied: (== ?c 1)",
    "  constraint not satisfied: (== (+ ?x 1) 2) (cannot evaluate: expected an integer)",
    "target 2: @h",
    "  no match",
    "",
  ].join("\n");
  assert.deepEqual(parseReport(report), [
    { fn: "@f", matches: 2, rejected: [] },
    {
      fn: "@g",
      matches: 0,
      rejected: [
        { constraint: "(== ?c 1)", reason: "" },
        { constraint: "(== (+ ?x 1) 2)", reason: "expected an integer" },
      ],
    },
    { fn: "@h", matches: 0, rejected: [] },
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
