# MetaphIR evaluation (llvm-opt-benchmark)

## Setup

|  |  |
|---|---|
| MetaphIR | `f1c6f0d5d63a4bce1596d16b1bca03b6b514e971 (with uncommitted changes)` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-before-ic1`: 68843 modules, 14.36 GB |
| Functions | 28426878 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | 358994 CPU-seconds (summed per module, benchmark and test files together) |
| Tool failures | MetaphIR 0, daggrep 0 |

## RQ1: Expressiveness

23 patterns, 75 instruction lines, 20 constraint lines, at most 6 instructions per pattern. Patterns using each feature (`eval/scripts/pattern_stats.py`):

| Feature | Patterns |
|---|---|
| constant_class | 10 |
| commutative | 12 |
| one_use | 13 |
| stdlib_composite | 9 |
| value_tracking | 8 |
| intrinsic | 6 |
| own_composite | 1 |
| or_self | 1 |

Baseline: see `eval/baselines/EXPRESSIVENESS.md` (daggrep expresses 3 of 23 patterns exactly).

## RQ2 and RQ4: Accuracy

Functions where each fold fires (G) and where each tool's patterns match (P).

| PR | \|G\| | MetaphIR \|P\| | TP | F1 | daggrep \|P\| | TP | F1 |
|---|---|---|---|---|---|---|---|
| pr204089 | 12456 | 163682 | 11975 | 13.60% | 232519 | 12057 | 9.84% |
| pr204927 | 1061 | 5646 | 853 | 25.44% | 9330 | 854 | 16.44% |
| pr204928 | 2 | 1 | 0 | 0.00% | 4 | 0 | 0.00% |
| pr205383 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207462 | 4 | 0 | 0 | 0.00% | 40 | 0 | 0.00% |
| pr207564 | 12 | 30 | 7 | 33.33% | 30 | 7 | 33.33% |
| pr209322 | 171 | 181 | 171 | 97.16% | 175684 | 171 | 0.19% |
| pr210499 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr212132 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213313 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213709 | 5 | 4 | 4 | 88.89% | 4 | 4 | 88.89% |
| pr214376 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214381 | 0 | 1 | 0 | 0.00% | 13 | 0 | 0.00% |
| pr214517 | 1 | 0 | 0 | 0.00% | 31 | 0 | 0.00% |
| pr214541 | 22 | 328 | 21 | 12.00% | 1023 | 22 | 4.21% |
| pr215122 | 22 | 1 | 1 | 8.70% | 7 | 1 | 6.90% |
| pr215130 | 0 | 0 | 0 | 100.00% | 1 | 0 | 0.00% |
| pr216046 | 0 | 0 | 0 | 100.00% | 1641 | 0 | 0.00% |
| pr216436 | 52 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |
| pr216470 | 81 | 4 | 4 | 9.41% | 11 | 7 | 15.22% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 13889 | 169878 | 13036 | 156842 | 853 | 7.67% | 93.86% | 14.19% | 7 |
| MetaphIR | without pr204089 | 1433 | 6196 | 1061 | 5135 | 372 | 17.12% | 74.04% | 27.81% | 7 |
| daggrep | all | 13889 | 420338 | 13123 | 407215 | 766 | 3.12% | 94.48% | 6.04% | 5 |
| daggrep | without pr204089 | 1433 | 187819 | 1066 | 186753 | 367 | 0.57% | 74.39% | 1.13% | 5 |

## RQ3: Index

|  |  |
|---|---|
| Index build | 237.53 s |
| Index build without value facts | 207.56 s |
| Median functions whose packs are fetched | 0.00% |
| Median modules read | 0.06% |

Matching with the index found the same functions as matching without it (0 differences).

Left after pruning, per pattern. Packs checked is the number of functions whose features may match — the packs a published query fetches; files read is the number of modules it reads.

| Pattern | Packs checked | Files read |
|---|---|---|
| pr204089 | 253162 (0.89%) | 29141 (41.19%) |
| pr204927 | 7292 (0.03%) | 3319 (4.69%) |
| pr204928 | 23 (0.00%) | 17 (0.02%) |
| pr205383_sub | 6 (0.00%) | 4 (0.01%) |
| pr205383_xor | 2 (0.00%) | 1 (0.00%) |
| pr207462 | 314 (0.00%) | 181 (0.26%) |
| pr207462_mul | 7 (0.00%) | 5 (0.01%) |
| pr207564 | 812 (0.00%) | 717 (1.01%) |
| pr209322 | 200 (0.00%) | 44 (0.06%) |
| pr210499 | 9 (0.00%) | 1 (0.00%) |
| pr212132_case1 | 4 (0.00%) | 2 (0.00%) |
| pr212132_case2 | 2 (0.00%) | 1 (0.00%) |
| pr213313 | 157 (0.00%) | 86 (0.12%) |
| pr213709 | 477 (0.00%) | 309 (0.44%) |
| pr214376 | 68 (0.00%) | 31 (0.04%) |
| pr214381 | 434 (0.00%) | 264 (0.37%) |
| pr214517 | 11 (0.00%) | 9 (0.01%) |
| pr214541 | 982 (0.00%) | 496 (0.70%) |
| pr215122 | 4686 (0.02%) | 928 (1.31%) |
| pr215130 | 14 (0.00%) | 10 (0.01%) |
| pr216046 | 759 (0.00%) | 338 (0.48%) |
| pr216436 | 4 (0.00%) | 1 (0.00%) |
| pr216470 | 622 (0.00%) | 323 (0.46%) |

Value facts change these patterns only; the other 20 are unchanged. These patterns' constraints read value facts, so their counts above cannot be reproduced without them.

| Pattern | Packs | Packs w/o value facts |
|---|---|---|
| pr209322 | 200 | 176291 |
| pr212132_case1 | 4 | 5 |
| pr216046 | 759 | 2231 |

Candidate filtering by variant. `--no-constraint-prefilter` keeps the feature prefilter but does not evaluate the variants' constraints on a candidate's features, so a function passes when its features can match structurally even if a constraint would reject every match; it checks more packs. The no-value-facts index keeps more coarse candidates, but the fine features reject most of them before packs, so packs and modules read change only where a constraint reads value facts. A full scan reads every function and file.

| Pattern | Index packs | Index files | No-VF packs | No-VF files | No-constraint packs | No-constraint files |
|---|---|---|---|---|---|---|
| pr204089 | 253162 (0.89%) | 29141 (41.19%) | 253162 (0.89%) | 29141 (41.19%) | 253162 (0.89%) | 29141 (41.19%) |
| pr204927 | 7292 (0.03%) | 3319 (4.69%) | 7292 (0.03%) | 3319 (4.69%) | 8631 (0.03%) | 3873 (5.47%) |
| pr204928 | 23 (0.00%) | 17 (0.02%) | 23 (0.00%) | 17 (0.02%) | 25 (0.00%) | 18 (0.03%) |
| pr205383_sub | 6 (0.00%) | 4 (0.01%) | 6 (0.00%) | 4 (0.01%) | 8 (0.00%) | 4 (0.01%) |
| pr205383_xor | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) | 13 (0.00%) | 1 (0.00%) |
| pr207462 | 314 (0.00%) | 181 (0.26%) | 314 (0.00%) | 181 (0.26%) | 340 (0.00%) | 192 (0.27%) |
| pr207462_mul | 7 (0.00%) | 5 (0.01%) | 7 (0.00%) | 5 (0.01%) | 11 (0.00%) | 7 (0.01%) |
| pr207564 | 812 (0.00%) | 717 (1.01%) | 812 (0.00%) | 717 (1.01%) | 2478 (0.01%) | 1615 (2.28%) |
| pr209322 | 200 (0.00%) | 44 (0.06%) | 176291 (0.62%) | 26998 (38.16%) | 176291 (0.62%) | 26998 (38.16%) |
| pr210499 | 9 (0.00%) | 1 (0.00%) | 9 (0.00%) | 1 (0.00%) | 9 (0.00%) | 1 (0.00%) |
| pr212132_case1 | 4 (0.00%) | 2 (0.00%) | 5 (0.00%) | 2 (0.00%) | 6 (0.00%) | 2 (0.00%) |
| pr212132_case2 | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) |
| pr213313 | 157 (0.00%) | 86 (0.12%) | 157 (0.00%) | 86 (0.12%) | 157 (0.00%) | 86 (0.12%) |
| pr213709 | 477 (0.00%) | 309 (0.44%) | 477 (0.00%) | 309 (0.44%) | 9229 (0.03%) | 1954 (2.76%) |
| pr214376 | 68 (0.00%) | 31 (0.04%) | 68 (0.00%) | 31 (0.04%) | 78 (0.00%) | 37 (0.05%) |
| pr214381 | 434 (0.00%) | 264 (0.37%) | 434 (0.00%) | 264 (0.37%) | 698 (0.00%) | 415 (0.59%) |
| pr214517 | 11 (0.00%) | 9 (0.01%) | 11 (0.00%) | 9 (0.01%) | 40 (0.00%) | 16 (0.02%) |
| pr214541 | 982 (0.00%) | 496 (0.70%) | 982 (0.00%) | 496 (0.70%) | 1309 (0.00%) | 699 (0.99%) |
| pr215122 | 4686 (0.02%) | 928 (1.31%) | 4686 (0.02%) | 928 (1.31%) | 9375 (0.03%) | 1993 (2.82%) |
| pr215130 | 14 (0.00%) | 10 (0.01%) | 14 (0.00%) | 10 (0.01%) | 60 (0.00%) | 44 (0.06%) |
| pr216046 | 759 (0.00%) | 338 (0.48%) | 2231 (0.01%) | 837 (1.18%) | 2231 (0.01%) | 837 (1.18%) |
| pr216436 | 4 (0.00%) | 1 (0.00%) | 4 (0.00%) | 1 (0.00%) | 127 (0.00%) | 75 (0.11%) |
| pr216470 | 622 (0.00%) | 323 (0.46%) | 622 (0.00%) | 323 (0.46%) | 776 (0.00%) | 415 (0.59%) |

## RQ3 and RQ4: Query time

Wall-clock seconds per PR (summed over its pattern files), each run over the whole corpus with 80 threads or processes, the median of 3 runs. The corpus fits in the machine's page cache, so these are warm-cache numbers.

Packs checked and files read are summed over a PR's pattern files (modules may repeat); they are the candidates a published query reads for the pattern.

| PR | Packs checked | Files read | MetaphIR, indexed | MetaphIR, full scan | daggrep | MetaphIR, index w/o value facts | MetaphIR, indexed, no constraint prefilter |
|---|---|---|---|---|---|---|---|
| pr204089 | 253162 | 29141 | 11.88 | 25.89 | 46.95 | 12.06 | 11.94 |
| pr204927 | 7292 | 3319 | 4.26 | 23.72 | 63.89 | 4.24 | 4.26 |
| pr204928 | 23 | 17 | 0.43 | 23.92 | 63.34 | 0.44 | 0.41 |
| pr205383 | 8 | 5 | 0.84 | 47.96 | 83.91 | 0.83 | 0.84 |
| pr207462 | 321 | 186 | 1.42 | 48.18 | 42.76 | 1.47 | 1.57 |
| pr207564 | 812 | 717 | 1.32 | 23.64 | 20.66 | 1.34 | 1.99 |
| pr209322 | 200 | 44 | 2.49 | 23.69 | 23.33 | 9.38 | 9.44 |
| pr210499 | 9 | 1 | 1.94 | 23.78 | 85.26 | 1.80 | 1.91 |
| pr212132 | 6 | 3 | 0.79 | 47.48 | 42.86 | 0.79 | 0.78 |
| pr213313 | 157 | 86 | 0.57 | 23.97 | 42.55 | 0.56 | 0.56 |
| pr213709 | 477 | 309 | 1.78 | 24.40 | 42.40 | 1.81 | 4.27 |
| pr214376 | 68 | 31 | 0.45 | 23.71 | 21.62 | 0.45 | 0.49 |
| pr214381 | 434 | 264 | 1.89 | 24.47 | 21.12 | 1.85 | 2.06 |
| pr214517 | 11 | 9 | 0.41 | 23.83 | 21.26 | 0.42 | 0.43 |
| pr214541 | 982 | 496 | 1.97 | 23.64 | 22.06 | 2.02 | 2.25 |
| pr215122 | 4686 | 928 | 2.33 | 23.91 | 21.40 | 2.30 | 3.79 |
| pr215130 | 14 | 10 | 0.42 | 23.91 | 20.86 | 0.45 | 0.51 |
| pr216046 | 759 | 338 | 1.97 | 23.97 | 21.23 | 2.31 | 2.33 |
| pr216436 | 4 | 1 | 0.43 | 23.93 | 20.77 | 0.43 | 0.56 |
| pr216470 | 622 | 323 | 0.80 | 23.93 | 42.01 | 0.81 | 0.80 |
| **median** | 260.5 | 136.0 | 1.37 | 23.92 | 32.67 | 1.41 | 1.74 |
| **total** | 270047 | 36228 | 38.39 | 551.93 | 770.23 | 45.76 | 51.20 |

