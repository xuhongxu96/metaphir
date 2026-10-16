import { test } from "node:test";
import assert from "node:assert/strict";
import { parseMatch } from "../src/engine.ts";
import { filterMatches } from "../src/matchSearch.ts";

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
