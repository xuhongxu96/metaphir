import { test } from "node:test";
import assert from "node:assert/strict";
import { patternHash, readPatternHash } from "../src/share/patternLink.ts";

const pattern = "%r = add i32 ?x, ?y\n;; hasOneUse(?x)\n";

test("links carry the pattern compressed", async () => {
  const hash = await patternHash(pattern);
  assert.match(hash, /^#patternz=[A-Za-z0-9_-]+$/);
  assert.equal(await readPatternHash(hash), pattern);
});

test("without compression, links carry the text", async () => {
  const hash = await patternHash(pattern, false);
  assert.equal(hash, `#pattern=${encodeURIComponent(pattern)}`);
  assert.equal(await readPatternHash(hash), pattern);
});

test("links from before compression still read", async () => {
  assert.equal(await readPatternHash(`#pattern=${encodeURIComponent(pattern)}`), pattern);
});

test("other hashes carry no pattern", async () => {
  assert.equal(await readPatternHash(""), undefined);
  assert.equal(await readPatternHash("#other=1"), undefined);
});

test("a broken link carries no pattern", async () => {
  assert.equal(await readPatternHash("#patternz=!!"), undefined);
});
