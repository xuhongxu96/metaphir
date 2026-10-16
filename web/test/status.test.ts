import assert from "node:assert/strict";
import { test } from "node:test";
import type { Progress, Rejection } from "../src/engine.ts";
import { describe, linkedRejection, rejectionLink, statusDiagnostics } from "../src/status.ts";

const progress = (matches: number): Progress => ({
  stage: "matching",
  warnings: [],
  rejections: [],
  paused: { kind: "matches", matches: 1000 },
  matches,
  matched: 10,
  matchable: 20,
  candidates: 20,
  requests: 1,
  bytes: 0,
  seconds: 1,
});

test("a pause says as many matches as the counter", () => {
  const status = describe(progress(1003));
  assert.equal(status.text, "paused at 1,003 matches");
  assert.equal(status.matches, 1003);
});

test("rejecting constraints and warnings are marked on the pattern", () => {
  const status = describe({
      ...progress(0),
      warnings: [{ message: "shadowed", line: 1, column: 1 }],
      rejections: [
        { message: "(hasNUses ?x 2)", line: 2, column: 4, reason: "", functions: 3, samples: [] },
        {
          message: "(== (+ ?x 1) 2)",
          line: 3,
          column: 4,
          reason: "not a constant",
          functions: 1,
          samples: [],
        },
        { message: "(isa ?x)", line: 0, column: 0, reason: "", functions: 1, samples: [] },
      ],
  });
  assert.deepEqual(statusDiagnostics(status), [
    { line: 1, column: 1, severity: "warning", message: "shadowed" },
    {
      line: 2,
      column: 4,
      severity: "info",
      message: "(hasNUses ?x 2) rejected the structural matches in 3 functions",
      link: { text: "show in Rejected", target: rejectionLink(status.rejections![0]) },
    },
    {
      line: 3,
      column: 4,
      severity: "warning",
      message: "(== (+ ?x 1) 2) could not be evaluated in 1 function: not a constant",
      link: { text: "show in Rejected", target: rejectionLink(status.rejections![1]) },
    },
  ]);
  // A link leads back to its constraint, read as Monaco reads it.
  const path = (r: Rejection) => decodeURIComponent(rejectionLink(r).replace(/^[a-z]+:/, ""));
  for (const r of status.rejections!) assert.equal(linkedRejection(status.rejections!, path(r)), r);
  assert.equal(linkedRejection(status.rejections!, "rejection/none"), undefined);
});
