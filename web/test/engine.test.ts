import { test } from "node:test";
import assert from "node:assert/strict";
import {
  CANDIDATE_PROMPT,
  MATCH_BATCH,
  PublishedCorpus,
  type Progress,
} from "../src/engine.ts";
import type { RangeFetcher } from "../src/fetcher.ts";
import type { SessionPool } from "../src/pool.ts";
import { QueryControl } from "../src/pipeline.ts";
import { FakeCorpus, settle } from "./fakes.ts";

function open(fake: FakeCorpus): PublishedCorpus {
  const pool = { coordinator: fake.coordinator, sessions: [fake.matcher(), fake.matcher()] };
  return new PublishedCorpus(
    fake.fetcher as unknown as RangeFetcher,
    pool as unknown as SessionPool,
    fake.functions,
    1,
  );
}

test("a stage is not shown as done once its bytes are read", async () => {
  const fake = new FakeCorpus(3);
  const reports: Progress[] = [];
  await open(fake).match("p", (p) => reports.push(p), () => {}, new QueryControl());
  // The session works on what was read before the next stage starts: how
  // long for is not known.
  const read = reports.filter((p) => p.stage.startsWith("reading"));
  assert.ok(read.length > 0);
  for (const p of read) assert.notEqual(p.fraction, 1, `${p.stage}: ${p.fraction}`);
  assert.equal(reports.at(-1)!.stage, "done");
});

test(`pauses after every ${MATCH_BATCH} matches until continued`, async () => {
  const fake = new FakeCorpus(MATCH_BATCH * 2 + 50);
  const control = new QueryControl();
  const reports: Progress[] = [];
  const done = open(fake).match("p", (p) => reports.push(p), () => {}, control);
  await settle();
  const first = reports.at(-1)!;
  assert.ok(control.paused);
  assert.deepEqual(first.paused, { kind: "matches", matches: MATCH_BATCH });
  // The matchers finish the functions they had begun.
  assert.ok(first.matches >= MATCH_BATCH && first.matches < MATCH_BATCH + 2, `${first.matches}`);
  const seen = reports.length;
  control.resume();
  await settle();
  // At once, not with the next match.
  assert.equal(reports[seen].paused, undefined, "reported as going on");
  assert.equal(reports[seen].matches, reports[seen - 1].matches);
  assert.ok(control.paused);
  assert.ok(reports.at(-1)!.matches >= MATCH_BATCH * 2);
  control.resume();
  await done;
  assert.equal(reports.at(-1)!.stage, "done");
  assert.equal(reports.at(-1)!.matches, MATCH_BATCH * 2 + 50);
});

test("runs to the end without pausing at later matches", async () => {
  const fake = new FakeCorpus(MATCH_BATCH * 3);
  const control = new QueryControl();
  const reports: Progress[] = [];
  const done = open(fake).match("p", (p) => reports.push(p), () => {}, control);
  await settle();
  assert.ok(control.paused);
  const seen = reports.length;
  control.runToEnd();
  await done;
  assert.ok(reports.slice(seen).every((p) => !p.paused));
  assert.equal(reports.at(-1)!.stage, "done");
  assert.equal(reports.at(-1)!.matches, MATCH_BATCH * 3);
});

test("asks before reading the features of too many candidates", async () => {
  const fake = new FakeCorpus(CANDIDATE_PROMPT + 1);
  const control = new QueryControl();
  const reports: Progress[] = [];
  const done = open(fake).match("p", (p) => reports.push(p), () => {}, control);
  await settle();
  assert.ok(control.paused);
  assert.deepEqual(reports.at(-1)!.paused, {
    kind: "candidates",
    candidates: CANDIDATE_PROMPT + 1,
  });
  assert.deepEqual(fake.stages, ["findLists", "findCandidates"]);
  control.stop();
  await done;
  assert.equal(reports.at(-1)!.stage, "stopped");
  assert.deepEqual(fake.matched, []);
});

test("does not ask about few candidates", async () => {
  const fake = new FakeCorpus(3);
  const control = new QueryControl();
  const reports: Progress[] = [];
  await open(fake).match("p", (p) => reports.push(p), () => {}, control);
  assert.ok(reports.every((p) => !p.paused));
  assert.equal(reports.at(-1)!.stage, "done");
});
