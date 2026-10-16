import { test } from "node:test";
import assert from "node:assert/strict";
import { parseMatch } from "../src/engine.ts";
import { filterMatches, lookalikes } from "../src/matchSearch.ts";

const matches = [
  "abc__abcAig.bc\t@Abc_AigAnd\t{?a = %1, ?b = -1}",
  "abc__abcAig.bc\t@Abc_AigOr\t{?a = %x, ?b = 3}",
  "zlib__inflate.bc\t@inflate\t{?a = %len, ?b = -1}",
].map((line, i) => parseMatch(i, line));
const fns = (query: string) => filterMatches(matches, query).map((m) => m.fn);

test("an empty query keeps every match", () => {
  assert.deepEqual(fns(""), ["@Abc_AigAnd", "@Abc_AigOr", "@inflate"]);
  assert.deepEqual(fns("   "), ["@Abc_AigAnd", "@Abc_AigOr", "@inflate"]);
});

test("finds the module, function or bindings, whatever the case", () => {
  assert.deepEqual(fns("zlib"), ["@inflate"]);
  assert.deepEqual(fns("aigor"), ["@Abc_AigOr"]);
  assert.deepEqual(fns("?b = -1"), ["@Abc_AigAnd", "@inflate"]);
});

test("each word must be found, anywhere", () => {
  assert.deepEqual(fns("abc -1"), ["@Abc_AigAnd"]);
  assert.deepEqual(fns("inflate %x"), []);
});

test("a binding must be one of the match's, variable and value together", () => {
  assert.deepEqual(fns("?b = -1"), ["@Abc_AigAnd", "@inflate"]);
  assert.deepEqual(fns("?a=%x"), ["@Abc_AigOr"]);
  // ?a is bound to %1 and ?b to -1, but not ?a to -1.
  assert.deepEqual(fns("?a = -1"), []);
  // A value is the whole of what is bound.
  assert.deepEqual(fns("?b = 3"), ["@Abc_AigOr"]);
  assert.deepEqual(fns("?a = %l"), []);
  assert.deepEqual(fns("zlib ?b = -1"), ["@inflate"]);
});

test("a binding value with spaces is quoted", () => {
  const vector = [parseMatch(0, 'm.bc\t@f\t{?v = <2 x i32> <i32 1, i32 2>, ?w = 1}')];
  assert.equal(filterMatches(vector, '?v = "<2 x i32> <i32 1, i32 2>"').length, 1);
  assert.equal(filterMatches(vector, '?v = "<2 x i32>"').length, 0);
});

test("finds the matches that print like others", () => {
  const rows = [
    "m.bc\t@f\t{?x = %x}\t{%rem@1 = #3, %cmp@2 = #9}",
    "m.bc\t@f\t{?x = %x}\t{%rem@1 = #7, %cmp@2 = #9}",
    "m.bc\t@f\t{?x = %y}\t{%rem@1 = #4, %cmp@2 = #9}",
    "m.bc\t@g\t{?x = %x}\t{%rem@1 = #3, %cmp@2 = #9}",
  ].map((line, i) => parseMatch(i, line));
  const alike = lookalikes(rows);
  assert.deepEqual(alike.get(rows[0]), { index: 1, count: 2 });
  assert.deepEqual(alike.get(rows[1]), { index: 2, count: 2 });
  assert.equal(alike.has(rows[2]), false);
  assert.equal(alike.has(rows[3]), false);
});
