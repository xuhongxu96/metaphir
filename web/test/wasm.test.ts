// Runs the WebAssembly builds (scripts/build_wasm.sh) the way the site does,
// against a corpus published by the native tools (from build/), and checks
// that they find what the native metaphir-match finds.
//
// Environment: METAPHIR_BUILD (build/), LLVM_BIN (llvm-project/build/bin).

import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync, mkdirSync, statSync, openSync, readSync, closeSync } from "node:fs";
import { createServer, type Server } from "node:http";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { RangeFetcher } from "../src/fetcher.ts";
import { runQuery, type Coordinator, type Matcher } from "../src/pipeline.ts";
import { loadModule, runStage, type MetaphIRModule, type Session } from "../src/session.ts";
import { runMatcher } from "../src/wasmMatcher.ts";
import { instructionLines } from "../src/engine.ts";

const repo = resolve(import.meta.dirname, "../..");
const build = process.env.METAPHIR_BUILD ?? join(repo, "build");
const llvmBin = process.env.LLVM_BIN ?? join(repo, "llvm-project/build/bin");
const wasm = join(repo, "web/public/wasm");

const SOURCES: Record<string, string> = {
  "uses.ll": `
@shared = global i32 0
@single = global i32 0
define i32 @load_shared() {
  %v = load i32, ptr @shared
  ret i32 %v
}
define void @store_shared() {
  store i32 1, ptr @shared
  ret void
}
define i32 @load_single() {
  %v = load i32, ptr @single
  %w = add i32 %v, 1
  ret i32 %w
}
`,
  "sub/other.ll": `
@0 = global i32 0
@1 = global i32 0
define i32 @load_unnamed(i32 %x) {
  %v = load i32, ptr @1
  %w = add i32 %v, %x
  ret i32 %w
}
`,
};
const PATTERNS = [
  "%v = load i32, ptr ?p\n;; hasOneUse(?p)\n",
  "%w = add i32 ?a, ?b\n",
  "%w = mul i32 ?a, ?b\n",
];

let work: string;
let server: Server;
let base: string;
let module: MetaphIRModule;
let requests = 0;

function tool(name: string, ...args: string[]): string {
  return execFileSync(join(build, "tools", name), args, {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  });
}

before(async () => {
  work = mkdtempSync(join(tmpdir(), "metaphir-web-"));
  for (const [path, source] of Object.entries(SOURCES)) {
    const ll = join(work, "src", path);
    mkdirSync(join(ll, ".."), { recursive: true });
    writeFileSync(ll, source);
    const bc = join(work, "corpus", path.replace(/\.ll$/, ".bc"));
    mkdirSync(join(bc, ".."), { recursive: true });
    execFileSync(join(llvmBin, "llvm-as"), [ll, "-o", bc]);
  }
  tool("metaphir-index", "build", join(work, "corpus"), "-o", join(work, "corpus.mpidx"));
  tool("metaphir-index", "publish", join(work, "corpus.mpidx"), "-o", join(work, "published"));

  // As a Hugging Face bucket serves files: /resolve/ redirects to the CDN,
  // which serves ranges.
  server = createServer((request, response) => {
    requests++;
    const url = new URL(request.url!, "http://localhost");
    if (url.pathname.startsWith("/resolve/")) {
      response.writeHead(302, { location: url.pathname.replace("/resolve/", "/cdn/") + "?signed=1" });
      response.end();
      return;
    }
    const file = join(work, "published", url.pathname.replace(/^\/cdn\//, ""));
    const size = statSync(file).size;
    const range = /bytes=(\d+)-(\d+)/.exec(request.headers.range ?? "");
    if (!range) {
      response.writeHead(200);
      response.end(readFileSync(file));
      return;
    }
    const start = Number(range[1]);
    const end = Math.min(Number(range[2]), size - 1);
    const bytes = Buffer.alloc(end - start + 1);
    const fd = openSync(file, "r");
    readSync(fd, bytes, 0, bytes.length, start);
    closeSync(fd);
    response.writeHead(206, { "content-range": `bytes ${start}-${end}/${size}` });
    response.end(bytes);
  });
  await new Promise<void>((done) => server.listen(0, "127.0.0.1", done));
  const address = server.address();
  base = `http://127.0.0.1:${typeof address === "object" ? address!.port : 0}/resolve`;
  module = await loadModule(join(wasm, "metaphir.js"));
});

after(() => {
  server?.close();
  rmSync(work, { recursive: true, force: true });
});

function direct(session: Session): Coordinator & Matcher {
  return {
    compile: async (pattern, name) => session.compile(pattern, name),
    stage: async (name) => runStage(session, name),
    add: async (file, offset, bytes) => session.add(file, offset, bytes),
    matchable: async () => session.matchable(),
    numCandidates: async () => session.numCandidates(),
    match: async (fn, frame, slot) => session.match(fn, frame, slot),
  };
}

test("matches the published corpus as metaphir-match --packs does", async () => {
  const fetcher = await RangeFetcher.open(base, "test");
  const header = await fetcher.fetchFile("header.bin.zst");
  const coordinator = new module.Session(header);
  assert.equal(coordinator.error(), "");
  const matchers = [new module.Session(header), new module.Session(header)];
  for (const [i, source] of PATTERNS.entries()) {
    const pattern = join(work, `pattern${i}.mpir`);
    writeFileSync(pattern, source);
    const expected = tool("metaphir-match", "--matches-only", "--print-instructions", "--packs", join(work, "published"), pattern);
    const found = new Map<number, string>();
    await runQuery(source, `pattern${i}.mpir`, direct(coordinator), matchers.map(direct), fetcher, {
      onMatched: (fn, lines, _, structural) => {
        found.set(fn, lines);
        // A match is a structural match too.
        if (lines) assert.ok(structural, `${source}: function ${fn}`);
      },
    });
    const lines = [...found.entries()].sort(([a], [b]) => a - b).map(([, l]) => l).join("");
    assert.equal(lines, expected, source);
  }
  // What was read is not read again.
  const before = requests;
  const found = new Map<number, string>();
  await runQuery(PATTERNS[1], "again.mpir", direct(coordinator), matchers.map(direct), fetcher, {
    onMatched: (fn, lines) => found.set(fn, lines),
  });
  assert.equal(requests - before, 0);
  assert.ok(found.size > 0);
});

test("finds each instruction's line in printed IR", async () => {
  const fetcher = await RangeFetcher.open(base, "test");
  const session = new module.Session(await fetcher.fetchFile("header.bin.zst"));
  const index = readFileSync(join(work, "published", "functions.idx"));
  const packs = readFileSync(join(work, "published", "packs.bin"));
  const functions = index.length / 16 - 1;
  for (let fn = 0; fn < functions; fn++) {
    // Where its pack is: the frame's offset, size and the slot in it (see
    // PackLocation).
    const word = index.readBigUInt64LE(fn * 16 + 8);
    const start = Number(word >> 28n);
    const size = Number((word >> 4n) & 0xffffffn);
    const printed = session.printFunction(packs.subarray(start, start + size), Number(word & 15n));
    assert.ok(!("error" in printed));
    // As your IR's instructions are found, from the text alone.
    assert.deepEqual(instructionLines(printed.ir), printed.lines);
  }
});

test("answers with errors without a header or a pattern", () => {
  const broken = new module.Session(new Uint8Array([1, 2, 3]));
  assert.notEqual(broken.error(), "");
  assert.ok("error" in broken.compile("%r = add i32 ?x, ?y\n", "p.mpir"));
  assert.ok("error" in broken.printFunction(new Uint8Array(), 0));
  assert.ok("error" in broken.findLists());
  assert.ok("error" in broken.match(0, new Uint8Array(), 0));
  assert.equal(broken.numCandidates(), 0);
  assert.deepEqual(broken.matchable(), []);
  broken.delete();
});

test("reports pattern errors", async () => {
  const fetcher = await RangeFetcher.open(base, "test");
  const session = new module.Session(await fetcher.fetchFile("header.bin.zst"));
  await assert.rejects(
    runQuery("%w = frobnicate i32 ?a\n", "bad.mpir", direct(session), [], fetcher),
    /bad\.mpir:1:/,
  );
});

test("matches files in the page as metaphir-match does", async () => {
  const files = Object.keys(SOURCES).map((path) => {
    const bc = path.replace(/\.ll$/, ".bc");
    return { path: bc, bytes: readFileSync(join(work, "corpus", bc)) };
  });
  for (const [i, source] of PATTERNS.entries()) {
    const pattern = join(work, `pattern${i}.mpir`);
    writeFileSync(pattern, source);
    const expected = tool("metaphir-match", "--matches-only", "--print-instructions", pattern, join(work, "corpus"))
      .replaceAll(`${join(work, "corpus")}/`, "");
    const result = await runMatcher(join(wasm, "metaphir-match.js"), files, source);
    assert.equal(result.status, 0, result.err);
    assert.equal(result.out.trimEnd(), expected.trimEnd(), source);
  }
});
