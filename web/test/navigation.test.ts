import { test } from "node:test";
import assert from "node:assert/strict";
import { bindingValue } from "../src/bindings.ts";
import { irLink, patternLink, tokenAt } from "../src/navigation.ts";

const ir = `define i1 @f(i2 %x) {
  %neg = sub i2 0, %x
  %lowbit = and i2 %x, %neg
  %r = icmp eq i2 %lowbit, 0
  ret i1 %r
}`;
const pattern = [
  ";; treatIntAsVec(true)",
  "%neg = neg i?bits ?x",
  "%and = and:?and:c i?bits %neg, ?x",
  "%cmp = icmp:?anch ?pred i?bits %and, ?c",
  "ret i1 ?r",
];
const bindings = "{?anch = %r, ?and = %lowbit, ?bits = 2, ?x = %x}";
// Pattern lines 2 to 5 matched IR lines 2 to 5.
const links = [
  { name: "%neg", patternLine: 2, irLine: 2 },
  { name: "%and", patternLine: 3, irLine: 3 },
  { name: "%cmp", patternLine: 4, irLine: 4 },
  // An instruction without a result is named by its opcode.
  { name: "ret", patternLine: 5, irLine: 5 },
];
/** Where a click on the pattern at line and column goes, and from what. */
const at = (line: number, column: number) =>
  patternLink({ line, column, text: pattern[line - 1], links, bindings, ir });

test("finds the name under the cursor", () => {
  const line = "%and = and i?bits ?x, %neg";
  assert.equal(tokenAt(line, 1)?.text, "%and");
  assert.equal(tokenAt(line, 4)?.text, "%and");
  assert.equal(tokenAt(line, 5)?.text, "%and", "just after it, as a click lands");
  assert.deepEqual(tokenAt(line, 20), { text: "?x", column: 19, length: 2 });
  assert.equal(tokenAt(line, 24)?.text, "%neg");
  assert.equal(tokenAt(line, 8), undefined, "the opcode");
  assert.equal(tokenAt('%"a b" = add', 3)?.text, '%"a b"');
});

test("finds the value bound to a variable", () => {
  assert.equal(bindingValue(bindings, "?and"), "%lowbit");
  assert.equal(bindingValue(bindings, "?bits"), "2");
  assert.equal(bindingValue(bindings, "?a"), undefined, "not a prefix of ?anch");
});

test("a variable goes to where its value is defined", () => {
  assert.deepEqual(at(3, 13), {
    from: { column: 12, length: 4 },
    to: { line: 3, column: 3, length: 7 },
  });
  assert.deepEqual(at(3, 32)?.to, { line: 1, column: 17, length: 2 });
});

test("an instruction's name goes to the instruction it matched", () => {
  // Used on line 3, defined on line 2.
  assert.deepEqual(at(3, 27), {
    from: { column: 26, length: 4 },
    to: { line: 2, column: 3, length: 19 },
  });
});

test("an instruction's own name goes to the instruction it matched", () => {
  assert.deepEqual(at(4, 2), {
    from: { column: 1, length: 4 },
    to: { line: 4, column: 3, length: 26 },
  });
});

test("an instruction without a result goes by its opcode", () => {
  assert.deepEqual(at(5, 2), {
    from: { column: 1, length: 3 },
    to: { line: 5, column: 3, length: 9 },
  });
});

test("the rest of a line goes nowhere", () => {
  assert.equal(at(3, 8), undefined, "the opcode of a named instruction");
  assert.equal(at(3, 21), undefined, "a variable bound to a constant");
  assert.equal(at(4, 40), undefined, "a variable not bound");
  assert.equal(at(1, 5), undefined, "a line that matched nothing");
});

test("a value in the IR goes to where it is defined", () => {
  const line = ir.split("\n")[2];
  assert.deepEqual(irLink({ column: 21, text: line, ir }), {
    from: { column: 20, length: 2 },
    to: { line: 1, column: 17, length: 2 },
  });
  assert.equal(irLink({ column: 14, text: line, ir }), undefined, "the opcode");
});
