import { test } from "node:test";
import assert from "node:assert/strict";
import { BlockCache } from "../src/blocks.ts";

test("finds ranges in blocks that later blocks overlap", async () => {
  const cache = await BlockCache.open("corpus", "test");
  const bytes = Uint8Array.from({ length: 1000 }, (_, i) => i & 0xff);
  cache.put("features.bin", 0, bytes);
  // Many later, smaller blocks start within the first, before the range.
  for (let start = 500; start < 540; start += 2)
    cache.put("features.bin", start, bytes.slice(start, start + 2));
  const block = await cache.get("features.bin", 541, 100);
  assert.ok(block);
  assert.equal(block.start, 0);
  assert.equal(await cache.get("features.bin", 990, 20), undefined);
  assert.equal(await cache.get("packs.bin", 0, 1), undefined);
});
