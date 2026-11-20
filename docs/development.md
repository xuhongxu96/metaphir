# Development

## Building

MetaphIR builds against a pinned, patched LLVM checkout in `llvm-project/`:

```sh
scripts/prepare_llvm.sh release        # or: debug
cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build -j
```

### `scripts/prepare_llvm.sh`

Fetches the pinned LLVM commit, applies `eval/patches/` (needed only for the
evaluation), builds and installs LLVM into `llvm-project/build-<type>`, and
links `llvm-project/build` to it.

```
scripts/prepare_llvm.sh [debug|release] [--force] [--source-only] [--libraries-only] [--prune]
```

| Argument | |
|---|---|
| `debug` \| `release` | build type (default: `$LLVM_BUILD_TYPE`, else `release`) |
| `--force` | discard changes in `llvm-project` that are not saved in `eval/patches/` |
| `--source-only` | stop once the source is patched (e.g. for `scripts/build_wasm.sh` alone) |
| `--libraries-only` | build LLVM's libraries and only the tools MetaphIR's tests run, not all of LLVM's tools |
| `--prune` | keep only the install and those tools of the build, e.g. to cache it (as CI does) |

| Environment variable | Default | |
|---|---|---|
| `LLVM_BUILD_TYPE` | `Release` | build type when none is given |
| `LLVM_BUILD_DIR` | `llvm-project/build-<type>` | build directory |
| `CACHE_DIR` | ccache's default | ccache directory; LLVM's build uses ccache when it is installed |
| `JOBS` | `nproc` | parallel build jobs |

> [!NOTE]
> The script resets `llvm-project` before applying the patches, so it stops
> if the checkout has changes not saved in `eval/patches/`; pass `--force` to
> discard them.

### CMake options

| Option | Default | |
|---|---|---|
| `LLVM_DIR` | `llvm-project/build/install/lib/cmake/llvm` | LLVM to build against |
| `METAPHIR_LLVM_UTILS_DIR` | `llvm-project/build/bin` | where `llvm-lit`, `FileCheck`, `not`, `split-file` and `llvm-as` are |
| `METAPHIR_USE_SANITIZER` | (none) | sanitizer to build MetaphIR with, e.g. `address` |

## Layout

| Directory | |
|---|---|
| `metaphir/IR` | the language's vocabulary, from `.def` tables: instruction matchers and their flags, metaflags, constraint operators, keywords, primitive types, sorts, settings |
| `metaphir/Parser` | lexer, and the parser, which emits the `mpir` dialect; `metaphir/StdLib/stdlib.mpir` is embedded and parsed before every pattern |
| `metaphir/Dialect` | the dialects patterns are compiled through (see below), and the surface printer, which prints `mpir` in the pattern language |
| `metaphir/Transforms` | the passes between them |
| `metaphir/Exec` | what runs the result: the match plan interpreter, the constraint evaluator, index queries on features; `CompiledPattern` runs the whole pipeline |
| `metaphir/Matching` | the LLVM side: function features, constraint values and their coercions, and each operator's semantics (`Operators/`) |
| `metaphir/Index` | corpus indexes: per-function features for skipping what a pattern cannot match, and function packs |
| `metaphir/Web` | corpora published for matching by byte ranges over HTTP |
| `web` | the website, and the WebAssembly build |
| `tools` | the command-line tools |
| `test` | unit tests (gtest) and lit tests (`.mlir`, `.mpir`, `.ll`) |
| `eval` | evaluation against InstCombine: patterns, harness, results and report |

## How a pattern is compiled

Patterns are MLIR. The parser emits a module of the surface dialect, and
passes compile it into a match plan and an index query:

| Dialect | |
|---|---|
| `mpir` | patterns: instruction matchers (`mpir.inst`), uses of `match` matchers (`mpir.use`), meta variables, types, and `match`, `constraint` and `metaflag` definitions |
| `mpir_expr` | constraint expressions, shared by the other three |
| `mpir_plan` | match plans: what to check of which instruction, in order, with choices (`either`) |
| `mpir_index` | index queries: the features each way a match can go (`variant`) needs, its constraints on them, and the posting lists to read (`retrieve`) |

The passes run in three stages, a directory of `metaphir/Transforms` each,
with its tests under the same directory of `test/Transforms`:

| Stage | Passes | Reads | Writes |
|---|---|---|---|
| `Lowering` | `mpir-desugar-metaflags`, `mpir-expand-matchers`, `mpir-lower-alternatives`, `mpir-check-bindings` (together `mpir-lower`) | surface `mpir`: metaflags, `mpir.use`, `:c` and `:o` | lowered `mpir`: every choice a match makes is an `mpir.alt` |
| `ToPlan` | `mpir-to-plan` | lowered `mpir` | adds an `mpir_plan.matcher` after each pattern |
| `ToIndex` | `mpir-to-index`, then `mpir-index-structuralize`, `mpir-index-retrieval`, `mpir-index-factor` | lowered `mpir`; then `mpir_index` | adds an `mpir_index.query` after each pattern; then rewrites it |

Each stage declares its passes in its `Passes.td`: what each reads and writes,
and the dialects it depends on. [passes.md](passes.md) is generated from them
(`METAPHIR_UPDATE_GOLDEN=1 ctest -R MetaphIR.pass-docs` rewrites it).

`metaphir-opt` runs any of them on MLIR text, as `mlir-opt` does; it is what
the pass tests under `test/Transforms` run, on what `metaphir-parse --emit=mlir` prints:

```sh
metaphir-parse --emit=mlir pattern.mpir |
  metaphir-opt --mpir-lower --mpir-to-index --mpir-index-retrieval
```

## Testing

| Suite | Run with | |
|---|---|---|
| unit tests (gtest) | `ctest` | |
| lit tests over `test/` | `ctest` | |
| `test/scripts/differential.py` | `ctest` | checks that the prefilter, `-j`, `--index` and `--packs` never change what `metaphir-match` finds |
| `eval/scripts` unit tests | `ctest` | |
| `web/test` | `npm test` in `web/` | the site's code, and that the WebAssembly builds find what the native tools find; run after `scripts/build_wasm.sh`, with Node 22.18 or later |

`npm test` compares with the native tools in `METAPHIR_BUILD` (default:
`build/`) and the LLVM tools in `LLVM_BIN` (default: `llvm-project/build/bin`).

CI (`.github/workflows/ci.yml`) runs all of them, and checks the C++
formatting, on each push to `main` and each pull request. It builds the
pinned LLVM, and LLVM's libraries for WebAssembly, once, and restores them
from GitHub's cache while their commit, patches and build scripts stay the
same. Compiles go through ccache, whose directory is cached too.

Tests sit under the directory of what they test, mirroring `metaphir/`
(`Parser`, `Dialect`, `Transforms`, `Exec`, `Index`, `Matching`, ...), and
`test/Tools` holds what the tools themselves do (inputs, options, output). A
gtest is `<Name>Test.cpp`; a lit test is named in kebab-case after what it
covers, with the suffix of what it holds:

| Suffix | Holds | Typically runs |
|---|---|---|
| `.mlir` | MLIR, one pass's input | `metaphir-opt` |
| `.mpir` | patterns only, or a `split-file` bundle of them | `metaphir-lex`, `metaphir-parse`, a pipeline into `metaphir-opt` |
| `.ll` | LLVM IR too: a `split-file` bundle of patterns and IR | `metaphir-match`, `metaphir-index` |

Lit tests carry FileCheck directives generated by
`scripts/update_test_check.py`, which rewrites them from the current tool
output. Tests marked `NOTE: CHECK lines are written by hand` are left alone.
