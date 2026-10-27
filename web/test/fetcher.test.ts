import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { RangeFetcher } from "../src/fetcher.ts";

test("waits when the server asks it to slow down", async () => {
  const file = Uint8Array.from({ length: 1 << 20 }, (_, i) => (i * 7) & 0xff);
  let throttled = 0;
  const seen = new Set<string>();
  // Each range is refused once, as a rate limit would.
  const server = createServer((request, response) => {
    const range = /bytes=(\d+)-(\d+)/.exec(request.headers.range ?? "")!;
    if (!seen.has(range[0])) {
      seen.add(range[0]);
      throttled++;
      response.writeHead(429, { "retry-after": "0" });
      response.end();
      return;
    }
    const start = Number(range[1]);
    const end = Number(range[2]);
    response.writeHead(206);
    response.end(file.subarray(start, end + 1));
  });
  await new Promise<void>((done) => server.listen(0, "127.0.0.1", done));
  const port = (server.address() as { port: number }).port;
  try {
    const fetcher = await RangeFetcher.open(`http://127.0.0.1:${port}`, "corpus", "test");
    const ranges = [0, 300_000, 900_000].map((offset) => ({
      file: "packs.bin",
      offset,
      size: 1000,
    }));
    const read = new Map<number, Uint8Array>();
    await fetcher.fetchRanges(ranges, (range, bytes) => read.set(range.offset, bytes));
    for (const range of ranges)
      assert.deepEqual(read.get(range.offset), file.subarray(range.offset, range.offset + 1000));
    assert.ok(throttled > 0);
    assert.equal(fetcher.stats.throttled, throttled);
  } finally {
    server.close();
  }
});
