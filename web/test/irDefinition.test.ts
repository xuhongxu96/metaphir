import { test } from "node:test";
import assert from "node:assert/strict";
import { findDefinition } from "../src/irDefinition.ts";

const ir = `define i32 @f(i32 noundef %0, ptr %p.1) {
entry:
  %1 = add i32 %0, 1
  %10 = mul i32 %1, %1
  %accumulator.tr13 = sub i32 %10, %0
  br label %exit
exit:
  %"quoted name" = add i32 %1, 2
  ret i32 %accumulator.tr13
}`;

test("finds where an instruction is defined, not where it is used", () => {
  assert.deepEqual(findDefinition(ir, "%1"), { line: 3, column: 3, length: 2 });
  assert.deepEqual(findDefinition(ir, "%accumulator.tr13"), { line: 5, column: 3, length: 17 });
  assert.deepEqual(findDefinition(ir, '%"quoted name"'), { line: 8, column: 3, length: 14 });
});

test("does not take a longer name for the one looked for", () => {
  assert.deepEqual(findDefinition(ir, "%10"), { line: 4, column: 3, length: 3 });
});

test("finds arguments on the define line", () => {
  assert.deepEqual(findDefinition(ir, "%0"), { line: 1, column: 27, length: 2 });
  assert.deepEqual(findDefinition(ir, "%p.1"), { line: 1, column: 35, length: 4 });
});

test("finds block labels", () => {
  assert.deepEqual(findDefinition(ir, "%exit"), { line: 7, column: 1, length: 4 });
});

test("finds the first local value of a longer value", () => {
  assert.deepEqual(findDefinition(ir, "ptr %p.1"), { line: 1, column: 35, length: 4 });
});

test("finds nothing for constants, globals and unknown names", () => {
  assert.equal(findDefinition(ir, "-1"), undefined);
  assert.equal(findDefinition(ir, "@g"), undefined);
  assert.equal(findDefinition(ir, "%nope"), undefined);
});
