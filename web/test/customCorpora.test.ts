import { test } from "node:test";
import assert from "node:assert/strict";
import {
  addCorpus,
  checkEntry,
  newCustomId,
  normalizeDataUrl,
  parseStored,
  removeCorpus,
  updateCorpus,
  withCustom,
  type CustomCorpus,
} from "../src/customCorpora.ts";

const BUILD = "https://huggingface.co/buckets/me/b/resolve/builds/x/abc";

test("a build URL is kept; a trailing slash and manifest.json are dropped", () => {
  assert.equal(normalizeDataUrl(BUILD), BUILD);
  assert.equal(normalizeDataUrl(` ${BUILD}/ `), BUILD);
  assert.equal(normalizeDataUrl(`${BUILD}/manifest.json?download=true#x`), BUILD);
});

test("bucket pages and hf:// links name the resolve URL", () => {
  assert.equal(normalizeDataUrl("https://huggingface.co/buckets/me/b/tree/builds/x/abc"), BUILD);
  assert.equal(normalizeDataUrl("https://huggingface.co/buckets/me/b/tree/main/builds/x/abc"), BUILD);
  assert.equal(normalizeDataUrl("hf://buckets/me/b/resolve/builds/x/abc"), BUILD);
});

test("rejects empty, malformed and insecure links", () => {
  assert.throws(() => normalizeDataUrl("  "), /Enter/);
  assert.throws(() => normalizeDataUrl("not a url"), /not a URL/);
  assert.throws(() => normalizeDataUrl("http://example.com/x"), /https/);
  assert.throws(() => normalizeDataUrl("ftp://example.com/x"), /https/);
  assert.equal(normalizeDataUrl("http://localhost:8080/data/"), "http://localhost:8080/data");
});

const mine: CustomCorpus[] = [{ id: "u-aaaaaa", label: "Mine", data: BUILD }];

test("checkEntry rejects blank names and duplicates", () => {
  assert.throws(() => checkEntry(" ", BUILD, []), /name/);
  assert.throws(() => checkEntry("mine", "https://a.example/z", mine), /already a corpus/);
  assert.throws(() => checkEntry("Other", `${BUILD}/`, mine), /already in the list/);
  assert.deepEqual(checkEntry(" Other ", "https://a.example/z/", mine), {
    label: "Other",
    data: "https://a.example/z",
  });
});

test("create, update and delete", () => {
  const added = addCorpus(mine, { id: "u-bbbbbb", label: "Two", data: "https://b.example" });
  assert.deepEqual(added.map((c) => c.id), ["u-aaaaaa", "u-bbbbbb"]);
  const changed = updateCorpus(added, "u-bbbbbb", { label: "Deux", data: "https://c.example" });
  assert.deepEqual(changed[1], { id: "u-bbbbbb", label: "Deux", data: "https://c.example" });
  assert.deepEqual(changed[0], mine[0]);
  assert.deepEqual(removeCorpus(changed, "u-aaaaaa").map((c) => c.id), ["u-bbbbbb"]);
  assert.equal(mine.length, 1, "inputs are not changed");
});

test("new ids avoid existing and site ids", () => {
  const values = [0, 0, 0.5];
  let i = 0;
  const id = newCustomId(
    [{ id: "u-000000", label: "a", data: "https://a" }],
    new Set(),
    () => values[i++],
  );
  assert.match(id, /^u-[0-9a-z]{6}$/);
  assert.notEqual(id, "u-000000");
});

test("the stored list drops what is malformed", () => {
  assert.deepEqual(parseStored(null), []);
  assert.deepEqual(parseStored("{"), []);
  assert.deepEqual(parseStored('{"a":1}'), []);
  const stored = JSON.stringify([
    mine[0],
    mine[0],
    { id: "bad id", label: "x", data: BUILD },
    { id: "u-c", label: "", data: BUILD },
    { id: "u-d", label: "x", data: "javascript:alert(1)" },
    { id: "u-e", label: "x" },
    null,
    { id: "u-f", label: "F", data: "https://f.example" },
  ]);
  assert.deepEqual(parseStored(stored).map((c) => c.id), ["u-aaaaaa", "u-f"]);
});

test("the site's config gets the user's corpora after its own", () => {
  const site = {
    default: "o2-final",
    corpora: [{ id: "o2-final", label: "O2 final", data: "https://s.example" }],
  };
  const merged = withCustom(site, [...mine, { id: "o2-final", label: "Clash", data: "https://z" }]);
  assert.deepEqual(merged.corpora.map((c) => c.id), ["o2-final", "u-aaaaaa"]);
  assert.equal(merged.default, "o2-final");
  assert.equal(site.corpora.length, 1);
});
