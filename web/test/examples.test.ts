import assert from "node:assert/strict";
import { readdirSync } from "node:fs";
import { test } from "node:test";
import { exampleLabel, hasTitle, pullRequest, pullRequestUrl } from "../src/examples.ts";

test("each example is named by what it folds, and its pull request", () => {
  const names = readdirSync(new URL("../../eval/patterns", import.meta.url))
    .filter((file) => file.endsWith(".mpir"))
    .map((file) => file.slice(0, -".mpir".length));
  assert.ok(names.length > 0);
  for (const name of names) {
    assert.ok(hasTitle(name), `${name} has no title`);
    assert.ok(pullRequest(name), `${name} names no pull request`);
  }
  assert.equal(exampleLabel("pr204089"), "zext/sext(trunc nuw/nsw X) → X (#204089)");
  assert.equal(pullRequest("pr212132_case1"), 212132);
  assert.equal(pullRequestUrl(204089), "https://github.com/llvm/llvm-project/pull/204089");
});
