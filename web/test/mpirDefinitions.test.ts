import assert from "node:assert/strict";
import { test } from "node:test";
import { definitionLink, definitionsIn, referenceAt } from "../src/mpirDefinitions.ts";

const LIBRARY = [
  "match:c addLike [nsw, nuw] Binary (?ty ?x, ?y) {",
  "  %ret = add ?ty ?x, ?y",
  "}",
  "constraint isFF(?v) {",
  "  ?v == 255",
  "}",
  "metaflag:i:o :power2(?v) {",
  "  isPower2(?v)",
  "}",
].join("\n");

test("finds matchers, metaflags and constraints defined", () => {
  assert.deepEqual(definitionsIn(LIBRARY), [
    { kind: "matcher", name: "addLike", line: 1, column: 9, length: 7 },
    { kind: "constraint", name: "isFF", line: 4, column: 12, length: 4 },
    { kind: "metaflag", name: "power2", line: 7, column: 15, length: 6 },
  ]);
});

test("tells what a name is by where it is", () => {
  assert.equal(referenceAt("%r = addLike i32 ?x, ?y", 8)?.kind, "matcher");
  assert.equal(referenceAt("%r = add i32 ?x, ?y:power2", 23)?.kind, "metaflag");
  assert.equal(referenceAt(";; isFF(?x) && true", 5)?.kind, "constraint");
  // A meta variable's name is not one.
  assert.equal(referenceAt("%r = add i32 ?x, ?y", 15), undefined);
});

test("links a name to its definition, the pattern's first", () => {
  const library = definitionsIn(LIBRARY);
  const own = definitionsIn("constraint isFF(?v) {\n  ?v == -1\n}");
  const link = definitionLink(";; isFF(?x)", 5, [
    ["pattern", own],
    ["stdlib", library],
  ]);
  assert.deepEqual(link, {
    file: "pattern",
    from: { column: 4, length: 4 },
    to: { line: 1, column: 12, length: 4 },
  });
  assert.equal(definitionLink("%r = addLike i32 ?x, ?y", 8, [["stdlib", library]])?.to.line, 1);
  // A built-in has no definition.
  assert.equal(definitionLink("%r = add:c i32 ?x, ?y", 10, [["stdlib", library]]), undefined);
});
