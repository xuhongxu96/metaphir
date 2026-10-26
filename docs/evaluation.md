# Evaluation


The evaluation compares the functions each pattern matches (P) with the
functions where the instrumented InstCombine fold fires (G). It runs over
about 69,000 llvm-opt-benchmark modules and includes the daggrep baseline (see
[`eval/baselines/`](../eval/baselines/README.md)).

There are two corpora:

| Corpus | Results | Made with | |
|---|---|---|---|
| `eval/corpus` | `eval/results/main` | `prepare_corpus.py` | every module, optimized at O2 by the patched `opt` with the evaluated folds disabled |
| `eval/corpus-prelink` | `eval/results/prelink` | `prepare_corpus.py --passes 'thinlto-pre-link<O2>'` | every module, through O2's simplification stage (inlining and the InstCombines in it included), as ThinLTO's pre-link step writes it, with the evaluated folds disabled |

Both get each PR's upstream regression tests. The ground truth always comes
from the main corpus: on `eval/corpus-prelink` the tools are scored against
`eval/results/main/gt`.

To prepare a corpus, then run every step on it:

```sh
uv run eval/scripts/prepare_corpus.py --bench-root <llvm-opt-benchmark> --jobs 80
eval/scripts/run_all.sh eval/corpus eval/corpus.mpidx eval/results/main 80

uv run eval/scripts/prepare_corpus.py --bench-root <llvm-opt-benchmark> \
  --corpus eval/corpus-prelink --passes 'thinlto-pre-link<O2>' --jobs 80
eval/scripts/run_all.sh eval/corpus-prelink eval/corpus-prelink.mpidx \
  eval/results/prelink 80 eval/results/main   # ground truth from main
```

`run_all.sh` writes everything into the results directory, one subdirectory
per kind:

| Path | Contents | Written by |
|---|---|---|
| `gt/` | `<pr>_G.functions`: the functions each fold fires in (main only) | `run_eval.py gt` |
| `metaphir-index/` | `<pr>_P.functions`: the functions MetaphIR's patterns match, using the index | `run_baseline.py metaphir-index` |
| `metaphir-scan/` | the same, without the index | `run_baseline.py metaphir-scan` |
| `daggrep/` | the baseline's predictions | `run_baseline.py daggrep` |
| `ablation-*/` | MetaphIR without value facts in the index, or without the prefilter | `run_baseline.py metaphir-index` |
| `metrics/<tool>.txt` | precision, recall and F1 per PR | `run_eval.py metrics --tool <tool> [--gt <results>]` |
| `logs/` | every step's output, including the index build, `check-index` and `metaphir-index stats` | |
| `REPORT.md`, `summary.json` | the summary of all of the above | `report.py` |

Each `<pr>_P_timing.txt` records the wall-clock time of each pattern file over
the whole corpus.

The steps can also be run one by one. After a pattern changes, only its
predictions and metrics need to run again:

```sh
uv run eval/scripts/run_eval.py gt -j 80                 # gt/
uv run eval/scripts/run_eval.py index -j 80              # eval/corpus.mpidx
uv run eval/scripts/run_baseline.py metaphir-index -j 80 --pr pr214541
uv run eval/scripts/run_eval.py metrics --pr pr214541
```

`run_eval.py check-index` checks that the index loses no matches. It compares
matching with the index and without it, on a random sample of the corpus and
on every module with ground-truth functions.

| `run_eval.py` option | Steps | |
|---|---|---|
| `--pr <pr>...` | all but `index` | only these PRs, e.g. `--pr pr214541 pr204089` (default: all) |
| `-j <n>` | all | parallel jobs (default: 1) |
| `--index <file>` | `index`, `check-index` | the index to write or check (default: `eval/corpus.mpidx`) |
| `--tool <tool>` | `metrics` | whose predictions to score (default: `metaphir-index`) |
| `--sample <n>` | `check-index` | random modules to check besides those with ground-truth functions (default: 200) |
| `--seed <n>` | `check-index` | seed for the sample (default: 0) |
| `--corpus <dir>` | all | the corpus (default: `eval/corpus`) |
| `--results <dir>` | all | the corpus's results directory (default: `eval/results/main`) |

| Environment variable | Default | |
|---|---|---|
| `METAPHIR_OPT` | `llvm-project/build/bin/opt` | the instrumented `opt` for `gt` |
| `METAPHIR_MATCH` | `build/tools/metaphir-match` | the matcher for `check-index` and `run_baseline.py` |
| `METAPHIR_INDEX` | `build/tools/metaphir-index` | the indexer for `index` |
| `DAGGREP` | `eval/baselines/daggrep/build/daggrep` | the baseline for `run_baseline.py` |
