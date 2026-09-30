# MetaphIR

A domain-specific language for matching LLVM IR patterns, built to describe
the preconditions of InstCombine folds and measure them against LLVM itself.
See the [Wiki](https://github.com/xuhongxu96/metaphir/wiki) for the language.

```
; (X u/ 2) + (X u% 2), in either order
%div = udiv i?n ?x, 2
%rem = urem i?n ?x, 2
%sum = add:?anch:c i?n %div, %rem
;; ugt(?n, 1) && isKnownNonZero(?x)
```

## Building

MetaphIR builds against a pinned, patched LLVM checkout in `llvm-project/`:

```sh
scripts/prepare_llvm.sh release        # or: debug
cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build -j
```

`prepare_llvm.sh` fetches the pinned commit, applies `eval/patches/`, builds
and installs LLVM into `llvm-project/build-<type>`, and points
`llvm-project/build` at it. It refuses to discard local changes to
`llvm-project` beyond the patches unless given `--force`.

CMake options:

| Option | Default | |
|---|---|---|
| `LLVM_DIR` | `llvm-project/build/install/lib/cmake/llvm` | LLVM to build against |
| `METAPHIR_LLVM_UTILS_DIR` | `llvm-project/build/bin` | `llvm-lit`, `FileCheck`, `not` |
| `METAPHIR_WERROR` | `ON` | warnings are errors |
| `METAPHIR_USE_SANITIZER` | (none) | e.g. `address` |

Building against `llvm-project/build-debug/lib/cmake/llvm` enables LLVM's
ABI-breaking checks, which catch unchecked `llvm::Error`s.

## Tools

| Tool | |
|---|---|
| `metaphir-match <pattern> <.ll/.bc file or directory>...` | matches a pattern against every function |
| `metaphir-index build <directory> -o <index>` | indexes a corpus for `metaphir-match --index`; `dump` and `stats <pattern>` inspect an index; `publish <index> -o <directory>` publishes it for the web |
| `metaphir-parse <pattern>` | parses and prints a pattern |
| `metaphir-lex [--line-numbers] <file>` | prints the tokens of a file |

### Matching a corpus

`metaphir-match --matches-only` prints one tab-separated line per match (file,
`@function`, bindings), and `-j N` then matches N files at once.
`--print-instructions` adds the instructions each match matched: every
pattern instruction, by its result name (or opcode) and pattern line, with
the position of the IR instruction it matched among its function's, as in
`{%div@2 = #0, %sum@4 = #3}`. Instructions expanded from a composite matcher
(such as `neg`, however deeply nested) have the line of the instruction
using it in the pattern, and names that show the expansion (`%r$twice`). Each
function is first summarized by its features: the signatures of its
instructions (kind, flags and types), the operand edges between them, the
values they share, the globals they use, and facts about the values at each
instruction kind's operands, such as small constants, constant classes, use
counts and, when indexing, value-tracking facts. A pattern variant is only
matched where the function can have a match: its instructions must be there,
their types must agree on the pattern's type variables, and no constraint may
be false on the facts.

Constraints are checked with the same evaluator as on the IR
(`metaphir/Matching/ConstraintEvaluator.h`), in a domain where anything the
index cannot tell is unknown; each operator's IR, recording and index
semantics sit together in `metaphir/Matching/Operators/`.

`metaphir-index build` stores the features of a whole corpus
(`--no-value-facts` skips value tracking, for a faster build), with posting
lists from each coarse feature (instruction kind, edge, sibling pair, global)
to the functions that have it. `--index` intersects the pattern's shortest
lists to find its candidate functions, then checks those alone: other files
are skipped without being read, and matching files are loaded lazily, with
only the candidate functions materialized. Files changed since indexing, or
not indexed, are matched in full; `--trust-index` instead matches only the
indexed candidates, without listing the input directories or checking the
other files for changes. `--summary` prints how much was matched.

```sh
metaphir-index build -j 32 corpus -o corpus.mpidx
metaphir-match --matches-only -j 32 --index corpus.mpidx pattern.mpir corpus
```

### Matching on the web

`metaphir-index publish` turns an indexed corpus into files a static website
matches by byte ranges over HTTP, each function packed on its own; `web/`
is that website, with MetaphIR built for WebAssembly
(`scripts/build_wasm.sh`). `metaphir-match --packs <directory>` matches
published files as the site does. See [web/README.md](web/README.md).

## Layout

| Directory | |
|---|---|
| `metaphir/IR` | the pattern IR: types, values, instruction matchers, constraints, `PatternLowering` |
| `metaphir/Parser` | lexer and parser; `metaphir/StdLib/stdlib.mpir` is embedded and loaded into every context |
| `metaphir/Matching` | matching lowered patterns against LLVM IR and evaluating constraints |
| `metaphir/Index` | corpus indexes: per-function features for skipping what a pattern cannot match, and function packs |
| `metaphir/Web` | corpora published for matching by byte ranges over HTTP |
| `web` | the website, and the WebAssembly build |
| `tools` | the command-line tools |
| `test` | unit tests (gtest) and lit tests (`.ll`) |
| `eval` | evaluation against InstCombine: patterns, harness, results and report |

## Testing

`ctest` runs the unit tests, one lit suite over `test/`, and
`test/scripts/differential.py`, which checks that the prefilter, `-j`,
`--index` and `--packs` never change what `metaphir-match` finds, and, once
`scripts/build_wasm.sh` has run, the WebAssembly builds' tests in `web/test`. Lit tests carry
FileCheck directives generated by `scripts/update_test_check.py`, which
rewrites them from the current tool output; tests marked
`NOTE: CHECK lines are written by hand` are left alone.

## Evaluation

The evaluation compares where each pattern matches (P) with where the
instrumented InstCombine fold fires (G) over a corpus of about 50,000
modules; see `eval/PRs.md` and `eval/NON_100_F1_INVESTIGATION.md`.

```sh
uv run eval/scripts/prepare_corpus.py --bench-root <llvm-opt-benchmark>/local
uv run eval/scripts/run_eval.py gt -j 32       # ground truth, slow
uv run eval/scripts/run_eval.py index -j 32    # eval/corpus.mpidx, about a minute
uv run eval/scripts/run_eval.py pattern -j 32 --index  # predictions
uv run eval/scripts/run_eval.py metrics
```

Without `--index`, `pattern` runs `metaphir-match` once per module as before.
`check-index` compares the two on a sample of the corpus and every module with
ground-truth anchors.
