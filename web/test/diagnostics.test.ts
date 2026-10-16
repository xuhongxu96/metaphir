import assert from "node:assert/strict";
import { test } from "node:test";
import { parseDiagnostics } from "../src/diagnostics.ts";

test("reads located diagnostics", () => {
  const text =
    "pattern.mpir:4:16: error: matcher 'addi8' requires type 'i8'\n" +
    "%r = addi8 i?n ?a, ?b\n" +
    "               ^\n" +
    "metaphir-match: pattern.mpir:2:1: warning: unused ?y\n";
  assert.deepEqual(parseDiagnostics(text), [
    { line: 4, column: 16, severity: "error", message: "matcher 'addi8' requires type 'i8'" },
    { line: 2, column: 1, severity: "warning", message: "unused ?y" },
  ]);
});

test("ignores messages without a location", () => {
  assert.deepEqual(parseDiagnostics("error: the index is out of date"), []);
});
