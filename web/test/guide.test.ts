// Checks the pattern guide with the WebAssembly metaphir-match
// (scripts/build_wasm.sh): each pattern shown matches the IR beside it,
// binding what the IR marks; each operator's example and idiom's pattern
// compiles or matches; and the reference lists every built-in constraint
// operator (metaphir/IR/*.def), and every meta flag and matcher of the
// standard library (metaphir/StdLib/stdlib.mpir).

import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { test } from "node:test";
import {
  ARGUMENTS,
  DEMOS,
  IDIOMS,
  IDIOM_DECLARATIONS,
  MATCHERS,
  META_FLAGS,
  OPERATORS,
  TRY,
  marked,
  unmarked,
} from "../src/guide.ts";
import { runMatcher } from "../src/wasmMatcher.ts";

const repo = resolve(import.meta.dirname, "../..");
const tool = join(repo, "web/public/wasm/metaphir-match.js");
const skip = !existsSync(tool);

/** Each match of pattern in a function of instructions. */
async function matchesOf(pattern: string, instructions: string, module = "") {
  const body = instructions
    .split("\n")
    .map((line) => `  ${line}\n`)
    .join("");
  const ir = `${module}\ndefine void @f(${ARGUMENTS}) {\n${body}  ret void\n}\n`;
  const result = await runMatcher(tool, [{ path: "f.ll", bytes: new TextEncoder().encode(ir) }], pattern + "\n");
  assert.equal(result.status, 0, `${pattern}\n${result.err}`);
  assert.equal(result.err, "", pattern);
  const lines = result.out.split("\n").filter(Boolean);
  assert.ok(lines.length > 0, `${pattern}\nmatches nothing in\n${instructions}`);
  // The bindings, and the instructions matched.
  return lines.map((line) => line.split("\t").slice(2) as [string, string]);
}

/** Whether a match's bindings, as printed, bind ?x to what marks it. */
function binds(bindings: string, of: string, text: string, kind?: string): boolean {
  const value = new RegExp(`[{ ]\\${of} = (\\[[^\\]]*\\]|[^,}]*)`).exec(bindings)?.[1];
  if (value === undefined) return false;
  // A flag's presence is true; an array's elements are in the mark; a block
  // is printed %entry, and labelled entry:.
  if (value === "true") return true;
  if (kind === "block") return value === `%${text}`;
  return value
    .replace(/^\[|\]$/g, "")
    .split(", ")
    .every((element) => text.includes(element));
}

test("each demonstration matches its IR, binding what is marked", { skip }, async () => {
  for (const demo of [...DEMOS, ...TRY.map((t) => ({ ...t, id: t.title, module: undefined, cases: undefined }))]) {
    if (demo.cases) continue;
    const found = (await matchesOf(unmarked(demo.pattern), unmarked(demo.matches), demo.module)).map(([b]) => b);
    // The marks of what each meta variable binds: an array's elements are
    // marked one by one.
    const marks = new Map<string, { text: string; kind?: string }>();
    for (const m of marked(demo.matches).filter((part) => part.of)) {
      const known = marks.get(m.of!);
      marks.set(m.of!, { text: known ? `${known.text} ${m.text}` : m.text, kind: m.kind });
    }
    assert.ok(
      found.some((bindings) => [...marks].every(([of, m]) => binds(bindings, of, m.text, m.kind))),
      `${demo.id}: no match binds the marks\n${found.join("\n")}`,
    );
  }
});

test("each case matches just the instructions it says, binding what it says", { skip }, async () => {
  for (const demo of DEMOS.filter((d) => d.cases))
    for (const c of demo.cases!) {
      const lines = await matchesOf(unmarked(c.pattern), unmarked(demo.matches), demo.module);
      // Each match, by the instruction it matched: {%r@1 = #0} is the first.
      const matched = lines.map(([bindings, instructions]) => ({
        at: Number(/= #(\d+)/.exec(instructions)![1]),
        bindings,
      }));
      assert.deepEqual(matched.map((m) => m.at).sort(), c.matches, c.pattern);
      c.binds?.forEach((bound, i) =>
        assert.ok(matched.find((m) => m.at === c.matches[i])!.bindings.includes(bound), `${c.pattern}: ${bound}`),
      );
    }
});

test("each operator's example matches", { skip }, async () => {
  for (const o of OPERATORS) await matchesOf(`${o.on}\n;; ${o.example}`, o.matches);
});

test("each idiom matches its IR", { skip }, async () => {
  for (const idiom of IDIOMS) await matchesOf(idiom.pattern, idiom.matches, IDIOM_DECLARATIONS);
});
/** The names in text that the regular expression's first group finds. */
const namesIn = (text: string, re: RegExp) => new Set([...text.matchAll(re)].map((m) => m[1]));

const differ = (listed: Iterable<string>, defined: Set<string>) => {
  const shown = new Set(listed);
  return {
    missing: [...defined].filter((name) => !shown.has(name)),
    unknown: [...shown].filter((name) => !defined.has(name)),
  };
};

test("lists every built-in constraint operator", () => {
  const builtIn = new Set<string>();
  for (const def of ["ConstraintOperators", "ConstantClasses", "CmpPredicateOperators"]) {
    const text = readFileSync(join(repo, `metaphir/IR/${def}.def`), "utf8");
    const code = text.split("\n").filter((l) => !/^\s*(\/\/|#include)/.test(l));
    for (const name of namesIn(code.join("\n"), /"([^"]+)"/g)) builtIn.add(name);
  }
  assert.ok(builtIn.size > 80, `only ${builtIn.size} operators read`);
  // The operators an entry writes: those called, and those written as symbols.
  const written = OPERATORS.flatMap((o) => o.entries.map(([w]) => w));
  const listed = written.flatMap((w) => [
    ...[...w.matchAll(/(\w+)\(/g)].map((m) => m[1]),
    ...(w.replace(/"[^"]*"/g, "").match(/==|!=|&&|\|\||[!+*-]/g) ?? []),
  ]);
  assert.deepEqual(differ(listed, builtIn), { missing: [], unknown: [] });
});

test("lists every meta flag and matcher of the standard library", () => {
  const stdlib = readFileSync(join(repo, "metaphir/StdLib/stdlib.mpir"), "utf8");
  const flags = namesIn(stdlib, /^metaflag(?::\w+)* (:\w+)\(/gm);
  const listed = META_FLAGS.flatMap((g) => g.entries.map(([w]) => w)).filter(
    (w) => /^:\w+$/.test(w) && w !== ":c" && w !== ":o",
  );
  assert.deepEqual(differ(listed, flags), { missing: [], unknown: [] });
  const matchers = namesIn(stdlib, /^match(?::c)? (\w+)/gm);
  assert.deepEqual(differ(MATCHERS.flatMap((g) => g.entries.map(([w]) => w)), matchers), {
    missing: [],
    unknown: [],
  });
});
