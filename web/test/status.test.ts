import assert from "node:assert/strict";
import { test } from "node:test";
import type { Progress } from "../src/engine.ts";
import { describe } from "../src/status.ts";

const progress = (matches: number): Progress => ({
  stage: "matching",
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
  const status = describe(progress(1003), false);
  assert.equal(status.text, "paused at 1,003 matches");
  assert.equal(status.matches, 1003);
});
