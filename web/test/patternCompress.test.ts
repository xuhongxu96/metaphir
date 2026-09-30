import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import {
  compressPattern,
  decompressPattern,
  restoreTokens,
  substituteTokens,
} from "../src/share/patternCompress.ts";
import { DICTIONARY, DICT_MAX_ENTRIES } from "../src/share/patternDictionary.ts";

const dir = resolve(import.meta.dirname, "../../eval/patterns");
const examples = readdirSync(dir)
  .filter((name) => name.endsWith(".mpir"))
  .map((name) => [name, readFileSync(join(dir, name), "utf8")] as const);

test("the dictionary fits a byte each, without repeats", () => {
  assert.ok(DICTIONARY.length <= DICT_MAX_ENTRIES, `${DICTIONARY.length} entries`);
  const tokens = DICTIONARY.map((entry) => entry.token);
  assert.equal(new Set(tokens).size, tokens.length);
  assert.ok(tokens.every((token) => token.length > 1));
});

test("every example comes back as it was", async () => {
  for (const [name, pattern] of examples)
    assert.equal(await decompressPattern(await compressPattern(pattern)), pattern, name);
});

test("tokens come back as they were, wherever they are", () => {
  // Inside longer words too, where word-bounded tokens are left.
  for (const text of ["%add_result = add i32 ?x, 1", "?xy ?x_ i?bitsy", ";;;; ==="])
    assert.equal(restoreTokens(substituteTokens(text)), text);
});

test("text other than ASCII comes back as it was", async () => {
  const pattern = "; café ✓\n%r = add i32 ?x, ?y\n";
  assert.equal(await decompressPattern(await compressPattern(pattern)), pattern);
});

test("links are shorter than the text URL-encoded", async () => {
  let plain = 0;
  let compressed = 0;
  for (const [name, pattern] of examples) {
    const encoded = encodeURIComponent(pattern).length;
    const link = (await compressPattern(pattern)).length;
    assert.ok(link < encoded, `${name}: ${link} >= ${encoded}`);
    plain += encoded;
    compressed += link;
  }
  // Much shorter, in all.
  assert.ok(compressed * 2 < plain, `${compressed} of ${plain}`);
});

test("rejects what is not a link", async () => {
  await assert.rejects(decompressPattern("not base64url!"));
  await assert.rejects(decompressPattern(""));
  await assert.rejects(decompressPattern("CQ"), /version/);
});
