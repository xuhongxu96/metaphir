import { test } from "node:test";
import assert from "node:assert/strict";
import { findCorpus, parseConfig } from "../src/corpora.ts";

test("parses the list form and its default", () => {
  const config = parseConfig({
    default: "o2-final",
    corpora: [
      { id: "original", label: "Original", data: "https://a" },
      { id: "o2-final", label: "O2 final", description: "final IR", data: "https://b" },
    ],
  });
  assert.equal(config.default, "o2-final");
  assert.equal(config.corpora.length, 2);
  assert.equal(config.corpora[1].description, "final IR");
});

test("an unknown or missing default uses the first corpus", () => {
  const config = parseConfig({
    default: "nope",
    corpora: [
      { id: "original", data: "https://a" },
      { id: "o2-final", data: "https://b" },
    ],
  });
  assert.equal(config.default, "original");
  assert.equal(config.corpora[0].label, "original");
});

test("legacy data is one corpus named original", () => {
  const config = parseConfig({ data: "https://a" });
  assert.equal(config.default, "original");
  assert.deepEqual(config.corpora, [
    { id: "original", label: "Corpus", data: "https://a" },
  ]);
});

test("rejects invalid ids and duplicates", () => {
  assert.throws(() =>
    parseConfig({ corpora: [{ id: "a:b", data: "https://a" }] }),
  );
  assert.throws(() =>
    parseConfig({
      corpora: [
        { id: "a", data: "https://a" },
        { id: "a", data: "https://b" },
      ],
    }),
  );
});

test("rejects an empty corpus list or a missing data URL", () => {
  assert.throws(() => parseConfig({ corpora: [] }));
  assert.throws(() => parseConfig({ corpora: [{ id: "a", data: "" }] }));
});

test("findCorpus falls back to the first", () => {
  const config = parseConfig({
    corpora: [
      { id: "a", data: "https://a" },
      { id: "b", data: "https://b" },
    ],
  });
  assert.equal(findCorpus(config, "b").id, "b");
  assert.equal(findCorpus(config, "missing").id, "a");
  assert.equal(findCorpus(config, null).id, "a");
});

test("an unknown id uses the default corpus", () => {
  const config = parseConfig({
    default: "b",
    corpora: [
      { id: "a", data: "https://a" },
      { id: "b", data: "https://b" },
    ],
  });
  assert.equal(findCorpus(config, "zzz").id, "b");
  assert.equal(findCorpus(config, null).id, "b");
  assert.equal(findCorpus(config, "a").id, "a");
});
