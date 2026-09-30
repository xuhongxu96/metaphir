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
