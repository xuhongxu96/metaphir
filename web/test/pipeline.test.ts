import { test } from "node:test";
import assert from "node:assert/strict";
import { QueryControl, runQuery } from "../src/pipeline.ts";
import { FakeCorpus, settle } from "./fakes.ts";

function run(corpus: FakeCorpus, control: QueryControl, events = {}) {
  return runQuery("p", "p.mpir", corpus.coordinator, [corpus.matcher(), corpus.matcher()],
    corpus.fetcher, events, control);
}

test("reports the candidates before reading their features", async () => {
  const corpus = new FakeCorpus(3);
  const control = new QueryControl();
  let listed: number | undefined;
  let stagesWhenListed: string[] = [];
  await run(corpus, control, {
    onListed: (candidates: number) => {
      listed = candidates;
      stagesWhenListed = [...corpus.stages];
    },
  });
  assert.equal(listed, 3);
  assert.deepEqual(stagesWhenListed, ["findLists", "findCandidates"]);
});

test("waits while paused and goes on once resumed", async () => {
  const corpus = new FakeCorpus(3);
  const control = new QueryControl();
  const done = run(corpus, control, { onListed: () => control.pause() });
  await settle();
  assert.deepEqual(corpus.stages, ["findLists", "findCandidates"]);
  assert.deepEqual(corpus.matched, []);
  control.resume();
  await done;
  assert.equal(corpus.stages.length, 4);
  assert.deepEqual([...corpus.matched].sort(), [0, 1, 2]);
});

test("pausing while matching holds the functions not yet matched", async () => {
  const corpus = new FakeCorpus(10);
  const control = new QueryControl();
  const done = run(corpus, control, {
    onMatched: () => {
      if (corpus.matched.length === 2) control.pause();
    },
  });
  await settle();
  // Each of the two matchers finishes at most the function it had begun.
  assert.ok(corpus.matched.length <= 3, `${corpus.matched.length} matched`);
  control.resume();
  await done;
  assert.equal(corpus.matched.length, 10);
});

test("stops without matching the rest", async () => {
  const corpus = new FakeCorpus(10);
  const control = new QueryControl();
  await run(corpus, control, {
    onMatched: () => {
      if (corpus.matched.length === 2) control.stop();
    },
  });
  assert.ok(corpus.matched.length <= 3, `${corpus.matched.length} matched`);
  assert.ok(control.stopped);
});

test("stops while paused", async () => {
  const corpus = new FakeCorpus(3);
  const control = new QueryControl();
  const done = run(corpus, control, { onListed: () => control.pause() });
  await settle();
  control.stop();
  await done;
  assert.deepEqual(corpus.stages, ["findLists", "findCandidates"]);
  assert.deepEqual(corpus.matched, []);
});

test("runs to the end without pausing again", async () => {
  const corpus = new FakeCorpus(10);
  const control = new QueryControl();
  const done = run(corpus, control, {
    onListed: () => control.pause(),
    onMatched: () => control.pause(),
  });
  await settle();
  control.runToEnd();
  await done;
  assert.equal(corpus.matched.length, 10);
  assert.ok(!control.paused);
});

test("stops after running to the end was asked", async () => {
  const corpus = new FakeCorpus(10);
  const control = new QueryControl();
  const done = run(corpus, control, {
    onListed: () => control.pause(),
    onMatched: () => {
      if (corpus.matched.length === 2) control.stop();
    },
  });
  await settle();
  control.runToEnd();
  await done;
  assert.ok(corpus.matched.length <= 3, `${corpus.matched.length} matched`);
});
