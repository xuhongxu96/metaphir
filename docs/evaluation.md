# Evaluation

The evaluation compares the functions each pattern matches (P) with the
functions where the instrumented InstCombine fold fires (G). It runs over
68,843 llvm-opt-benchmark modules plus the upstream InstCombine and
InstSimplify test suites, and includes the daggrep baseline (see
[`eval/baselines/daggrep/`](../eval/baselines/daggrep/README.md)).

There are three corpora, each a different cut point:

| Corpus | Results | Made with | |
|---|---|---|---|
| `eval/corpus-original` | `eval/results/original` | raw `original/*.bc`, no `opt` | untouched, O0-ish IR |
| `eval/corpus-thinlto-prelink` | `eval/results/thinlto-prelink` | `prepare_corpus.py --kind thinlto-prelink` | every module through O2's simplification stage, as ThinLTO's pre-link step writes it, with the evaluated folds disabled |
| `eval/corpus-o2-final` | `eval/results/o2-final` | `prepare_corpus.py --kind o2-final` | every module at the end of the standard O2 pipeline, with the evaluated folds disabled |

Every corpus contains the same benchmark modules (68,843; the two `velox`
modules with invalid debug info are omitted) and the **entire top-level
InstCombine and InstSimplify test suites**: 1,718 + 194 `.ll` files, copied
raw as `InstCombine__<file>.ll` / `InstSimplify__<file>.ll`. Tests that do not
parse standalone are skipped and logged (currently one:
`InstSimplify/bitcast-vector-fold.ll`). Modules per corpus: 68,843 + 1,912 =
70,755.

## Ground truth

Each corpus is scored twice:

- **Direct** (`gt/`): one `instcombine` pass on the corpus IR, reporting
  firings rooted at instructions of that input. This is what a pattern matched
  on the corpus can see.
- **Real scenario** (`gt-pipeline/`): the e2e `default<O2>` run on the raw
  original IR, reporting every function where a fold fires (including
  `instsimplify` passes and pipeline-created instructions).

`original` collects both. `thinlto-prelink` and `o2-final` collect their own
direct `gt/` and are also scored against `original/gt-pipeline`. Reports:
`REPORT.md`/`summary.json` are direct; `REPORT-pipeline.md`/
`summary-pipeline.json` are real scenario. Both score the llvm-opt-benchmark
modules only; the upstream test files (`InstCombine__*.ll`,
`InstSimplify__*.ll`) are scored separately in `REPORT-tests.md`, against the
direct ground truth only (a test file is not a real-scenario input).

## Preparing a corpus and running every step

```sh
# o2-final and thinlto-prelink preprocess the benchmark modules
uv run eval/scripts/prepare_corpus.py --kind o2-final \
  --bench-root <llvm-opt-benchmark> --jobs 80
uv run eval/scripts/prepare_corpus.py --kind thinlto-prelink \
  --bench-root <llvm-opt-benchmark> --jobs 80

# original copies the raw modules (by default, the exact set of o2-final)
uv run eval/scripts/prepare_corpus.py --kind original \
  --bench-root <llvm-opt-benchmark> --jobs 80

eval/scripts/run_all.sh original 80       # its gt-pipeline is the real-scenario reference
eval/scripts/run_all.sh o2-final 80
eval/scripts/run_all.sh thinlto-prelink 80
```

The two `velox` modules with invalid debug info still fail `opt`; pass
`--allow-known-failures` to accept exactly those two (the module count is
still asserted at 68,843).

`run_all.sh` writes everything into `eval/results/<corpus>`, one subdirectory
per kind:

| Path | Contents | Written by |
|---|---|---|
| `gt/` | `<pr>_G.functions`: the functions each fold fires in (direct) | `run_eval.py gt` |
| `gt-pipeline/` | the same for the e2e O2 run on original | `run_eval.py gt --passes 'default<O2>' --firings all` |
| `metaphir-index/` | `<pr>_P.functions`: the functions MetaphIR's patterns match, using the index | `run_baseline.py metaphir-index` |
| `metaphir-scan/` | the same, without the index | `run_baseline.py metaphir-scan` |
| `daggrep/` | the baseline's predictions | `run_baseline.py daggrep` |
| `ablation-*/` | MetaphIR without value facts in the index, or without the constraint prefilter | `run_baseline.py metaphir-index` |
| `metrics/<tool>.txt` | precision, recall and F1 per PR (direct) | `run_eval.py metrics --tool <tool>` |
| `metrics/<tool>-pipeline.txt` | the same against `original/gt-pipeline` | `run_eval.py metrics --tool <tool> --gt ... --gt-dir gt-pipeline` |
| `logs/` | every step's output, including the index build, `check-index` and `metaphir-index stats` | |
| `REPORT.md`, `summary.json` | the direct summary on the llvm-opt-benchmark modules | `report.py` |
| `REPORT-pipeline.md`, `summary-pipeline.json` | the real-scenario summary | `report.py --gt ... --gt-dir gt-pipeline --suffix -pipeline` |
| `REPORT-tests.md`, `summary-tests.json` | the direct summary on the upstream test files only; no index or timing sections (those are one whole-corpus run) | `report.py --source tests` |

Reports cite the MetaphIR commit they were generated at, marked "(with
uncommitted changes)" when the code differs from `HEAD`. `report.py --commit
<rev>` cites that revision instead, so a rewritten history or a dirty tree
need not change the reports.

Each `<pr>_P_timing.txt` records the wall-clock time of each pattern file over
the whole corpus (the median of `--repeat` runs; `run_all.sh` uses 3), and the
candidate counts from `metaphir-match --summary`:
`checked[<pattern>]` (functions whose features may match, i.e. the packs a
published query fetches), `files_read[<pattern>]` (modules read), and their
totals.

Query time alone understates the cost of the web client: for every checked
function the browser fetches that function's pack, and it reads the modules in
`files_read`. `REPORT.md` shows packs checked and files read in the RQ3 table
and next to the query times; `summary.json` has them per PR in
`candidate_counts` and per pattern in `index.per_pattern_candidates`.

The same counts are recorded for the ablations. `REPORT.md` compares the
index, the index without value facts, and matching with
`--no-constraint-prefilter`. That option keeps the feature prefilter but does
not evaluate the variants' constraints on a candidate's features: a function
passes when its features can match structurally, even if a constraint would
reject every match, so more packs are checked. The no-value-facts index changes
packs only for the patterns whose constraints read value facts (pr209322, both
pr212132 cases, pr216046); for the others the fine features select the same
packs. The full scan reads every function and file. Every timing is the median
of 3 runs.

## Running steps one by one

```sh
# direct GT
uv run eval/scripts/run_eval.py gt --corpus eval/corpus-o2-final \
  --results eval/results/o2-final --gt-dir gt -j 80
# real-scenario GT (original only)
uv run eval/scripts/run_eval.py gt --corpus eval/corpus-original \
  --results eval/results/original --gt-dir gt-pipeline \
  --passes 'default<O2>' --firings all -j 80

uv run eval/scripts/run_eval.py index --corpus eval/corpus-o2-final \
  --index eval/corpus-o2-final.mpidx -j 80

uv run eval/scripts/run_baseline.py metaphir-index --corpus eval/corpus-o2-final \
  --index eval/corpus-o2-final.mpidx --results eval/results/o2-final -j 80 --pr pr214541

# direct metrics, and real-scenario metrics against original's pipeline GT
uv run eval/scripts/run_eval.py metrics --corpus eval/corpus-o2-final \
  --results eval/results/o2-final --gt-dir gt --tool metaphir-index --pr pr214541
uv run eval/scripts/run_eval.py metrics --corpus eval/corpus-o2-final \
  --results eval/results/o2-final --gt eval/results/original --gt-dir gt-pipeline \
  --tool metaphir-index --pr pr214541
```

`run_eval.py check-index` checks that the index loses no matches. It compares
matching with the index and without it, on a random sample of the corpus and
on every module with ground-truth functions.

| `run_eval.py` option | Steps | |
|---|---|---|
| `--pr <pr>...` | all but `index` | only these PRs, e.g. `--pr pr214541 pr204089` (default: all) |
| `-j <n>` | all | parallel jobs (default: 1) |
| `--corpus <dir>` | all | the corpus directory (required) |
| `--results <dir>` | all but `index` | the corpus's results directory (required) |
| `--gt-dir <name>` | `gt`, `check-index`, `metrics` | ground-truth subdirectory (default: `gt`) |
| `--gt <dir>` | `check-index`, `metrics` | another results directory to score against (e.g. `eval/results/original` with `--gt-dir gt-pipeline`) |
| `--passes <pipeline>` | `gt` | the pipeline whose firings are G (default: `function(instcombine<no-verify-fixpoint>)`) |
| `--committed {ablation,anchor}` | `gt` | `ablation` (default) keeps a firing only if the function's IR changes when that PR's folds are off; `anchor` keeps every reported anchor |
| `--firings {input,all}` | `gt` | `input` roots anchors at input instructions (direct); `all` reports every function-level firing (real scenario) |
| `--index <file>` | `index`, `check-index` | the index to write or use (required) |
| `--tool <tool>` | `metrics` | whose predictions to score (default: `metaphir-index`) |
| `--sample <n>` | `check-index` | random modules to check besides those with ground-truth functions (default: 200) |
| `--seed <n>` | `check-index` | seed for the sample (default: 0) |

| Environment variable | Default | |
|---|---|---|
| `METAPHIR_OPT` | `llvm-project/build/bin/opt` | the instrumented `opt` for `gt` |
| `METAPHIR_MATCH` | `build/tools/metaphir-match` | the matcher for `check-index` and `run_baseline.py` |
| `METAPHIR_INDEX` | `build/tools/metaphir-index` | the indexer for `index` |
| `DAGGREP` | `eval/baselines/daggrep/build/daggrep` | the baseline for `run_baseline.py` |
| `METAPHIR_EVAL_ENABLED` | unset | set by `gt`; while preparing a corpus it must stay unset so the folds are disabled |
| `METAPHIR_EVAL_ABLATE` | unset | set by `gt --committed ablation`; a comma-separated list of PRs whose folds are turned off |
| `METAPHIR_EVAL_ALL_FIRINGS` | unset | set by `gt --firings all`; report every function where a fold fires in the pipeline, not only firings rooted at instructions present when InstCombine started |

### Direct firings vs every firing

A fold firing has a *root* instruction. `gt --firings input` (the default)
reports `ANCHOR <function> <fold>` only when the root is an instruction of the
function at the start of the InstCombine invocation and was not erased. On a
corpus with a single `instcombine` (the direct GT), that is exactly the input
a pattern sees. `gt --firings all` reports the function instead, whichever pass
emits the firing and whether or not the root existed when that pass started.
Use it for the real-scenario GT: the e2e `default<O2>` run on original IR.

Three examples of what only the all-firings mode sees:

1. **Passes outside InstCombine.** `instsimplify` and `loop-instsimplify` run
   the instrumented simplify folds without calling `initAnchors`, so input
   mode reports nothing. On `InstSimplify/cast.ll`:

   ```sh
   # direct (input): no ANCHOR lines
   METAPHIR_EVAL_ENABLED=1 opt -passes='function(instsimplify)' \
     llvm-project/llvm/test/Transforms/InstSimplify/cast.ll -disable-output

   # all firings
   METAPHIR_EVAL_ENABLED=1 METAPHIR_EVAL_ALL_FIRINGS=1 opt \
     -passes='function(instsimplify)' \
     llvm-project/llvm/test/Transforms/InstSimplify/cast.ll -disable-output \
     2>&1 | grep ANCHOR
   ANCHOR sext_of_trunc_nsw pr204089
   ANCHOR zext_of_trunc_nuw pr204089
   ANCHOR zext_of_trunc_nuw_vec pr204089
   ```

2. **A shape another fold creates in the same InstCombine.** `pr214517`'s
   fold (`C << cttz(X, true)` -> `(-X & X) * C`) creates the `X & -X` shape
   that `pr213709` matches. The second firing is rooted at an instruction
   created after `initAnchors`, so input mode drops it; all-firings reports
   the function.

3. **Functions no InstCombine activation sees.** A folding site in a function
   that only `instsimplify` visits (or a function created after the last
   InstCombine) has no `initAnchors` activation, so input mode cannot report
   it. All-firings records `ANCHOR <function> <fold>`, and that function is
   then an unmatched function (FN) when scoring a pattern matched on the
   corpus — a real-scenario gap, not a pattern miss.

The two modes answer different questions: input mode asks "which input sites
would the fold fire on?", all-firings asks "which functions does the fold fire
in during the real pipeline?". The evaluation uses input for every direct
`gt/` and all-firings for `original`'s `gt-pipeline/`:

```sh
# direct
uv run eval/scripts/run_eval.py gt --corpus eval/corpus-o2-final \
  --results eval/results/o2-final --gt-dir gt --firings input -j 80
# real scenario
uv run eval/scripts/run_eval.py gt --corpus eval/corpus-original \
  --results eval/results/original --gt-dir gt-pipeline \
  --passes 'default<O2>' --firings all -j 80
```

### Speculative firings

InstCombine and InstSimplify sometimes ask what an instruction would fold to
before they know they will rewrite anything. `foldOpIntoPhi` simplifies the
operation once per phi incoming value, then gives up if a second incoming value
does not simplify or its edge is critical; `FoldOpIntoSelect`,
`simplifyWithOpsReplaced` and `expandBinOp` behave alike. The fold ran, but the
IR never changed, so a reported anchor does not mean the fold rewrote anything.

`gt --committed ablation` (the default) therefore keeps a firing only if the
function's IR changes when that PR's folds are turned off. For each module with
anchors, `run_eval.py` runs the pipeline once with every fold on and once per
PR with `METAPHIR_EVAL_ABLATE=<pr>`, which makes `foldEnabled` false for that
PR's fold IDs, and compares the two outputs function by function. It needs no
knowledge of where a fold is called from, so a new speculative call site cannot
slip through. `--committed anchor` keeps every anchor.

Two effects to keep in mind:

- A firing that did rewrite the IR, but that another rule would have rewritten
  to the same result, is dropped. G then means "the fold changed the output".
- `gt_seconds` in `gt/timing.txt` includes the ablation runs, so it is several
  times the cost of the anchor run alone.

On `o2-final`, `pr204089` has 1,830 anchored functions and 1,096 that change the
IR; `pr213313` has 13 and 10.

## Comparing the corpora

```sh
uv run eval/scripts/compare_corpora.py
uv run eval/scripts/compare_corpora.py --update-config web/public/config.json
```

`compare_corpora.py` prints direct and real-scenario F1 for the three corpora
and names the best real-scenario corpus. `--update-config` sets the website's
default to it.
