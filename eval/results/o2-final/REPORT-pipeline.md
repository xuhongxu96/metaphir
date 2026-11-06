# MetaphIR evaluation (llvm-opt-benchmark)

## Setup

|  |  |
|---|---|
| MetaphIR | `de162aa9294ce92e7089772b0ca661f473a31321` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-o2-final`: 68843 modules, 11.90 GB |
| Functions | 4776770 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | `eval/results/original/gt-pipeline`, 352280 CPU-seconds (summed per module, benchmark and test files together) |
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
| pr204089 | 15487 | 9 | 0 | 0.00% | 10 | 0 | 0.00% |
| pr204927 | 753 | 1973 | 505 | 37.05% | 4343 | 518 | 20.33% |
| pr204928 | 138 | 1266 | 136 | 19.37% | 5163 | 137 | 5.17% |
| pr205383 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207462 | 29 | 31 | 29 | 96.67% | 212 | 29 | 24.07% |
| pr207564 | 37 | 52 | 28 | 62.92% | 54 | 28 | 61.54% |
| pr209322 | 26 | 0 | 0 | 0.00% | 68204 | 1 | 0.00% |
| pr210499 | 13 | 10 | 7 | 60.87% | 5524 | 7 | 0.25% |
| pr212132 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213313 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213709 | 8 | 9 | 8 | 94.12% | 9 | 8 | 94.12% |
| pr214376 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214381 | 7 | 9 | 7 | 87.50% | 14 | 7 | 66.67% |
| pr214517 | 13 | 24 | 13 | 70.27% | 475 | 13 | 5.33% |
| pr214541 | 23 | 18 | 12 | 58.54% | 284 | 12 | 7.82% |
| pr215122 | 23 | 32 | 18 | 65.45% | 168 | 18 | 18.85% |
| pr215130 | 3 | 3 | 3 | 100.00% | 14 | 3 | 35.29% |
| pr216046 | 0 | 57 | 0 | 0.00% | 1680 | 0 | 0.00% |
| pr216436 | 42 | 44 | 32 | 74.42% | 52 | 34 | 72.34% |
| pr216470 | 151 | 333 | 135 | 55.79% | 3817 | 138 | 6.96% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 16753 | 3870 | 933 | 2937 | 15820 | 24.11% | 5.57% | 9.05% | 5 |
| MetaphIR | without pr204089 | 1266 | 3861 | 933 | 2928 | 333 | 24.16% | 73.70% | 36.40% | 5 |
| daggrep | all | 16753 | 90023 | 953 | 89070 | 15800 | 1.06% | 5.69% | 1.79% | 4 |
| daggrep | without pr204089 | 1266 | 90013 | 953 | 89060 | 313 | 1.06% | 75.28% | 2.09% | 4 |

## RQ3: Index

|  |  |
|---|---|
| Index build | 131.38 s |
| Index build without value facts | 103.62 s |
| Median functions whose packs are fetched | 0.02% |
| Median modules read | 0.51% |

Matching with the index found the same functions as matching without it (0 differences).

Left after pruning, per pattern. Packs checked is the number of functions whose features may match — the packs a published query fetches; files read is the number of modules it reads.

| Pattern | Packs checked | Files read |
|---|---|---|
| pr204089 | 539 (0.01%) | 240 (0.34%) |
| pr204927 | 17998 (0.38%) | 5097 (7.20%) |
| pr204928 | 3987 (0.08%) | 703 (0.99%) |
| pr205383_sub | 21 (0.00%) | 20 (0.03%) |
| pr205383_xor | 7 (0.00%) | 6 (0.01%) |
| pr207462 | 4885 (0.10%) | 1551 (2.19%) |
| pr207462_mul | 31 (0.00%) | 5 (0.01%) |
| pr207564 | 2494 (0.05%) | 1479 (2.09%) |
| pr209322 | 19 (0.00%) | 8 (0.01%) |
| pr210499 | 2959 (0.06%) | 1631 (2.31%) |
| pr212132_case1 | 893 (0.02%) | 721 (1.02%) |
| pr212132_case2 | 1935 (0.04%) | 1166 (1.65%) |
| pr213313 | 747 (0.02%) | 247 (0.35%) |
| pr213709 | 6312 (0.13%) | 2211 (3.12%) |
| pr214376 | 1086 (0.02%) | 341 (0.48%) |
| pr214381 | 253 (0.01%) | 164 (0.23%) |
| pr214517 | 819 (0.02%) | 312 (0.44%) |
| pr214541 | 396 (0.01%) | 223 (0.32%) |
| pr215122 | 6931 (0.15%) | 2083 (2.94%) |
| pr215130 | 349 (0.01%) | 158 (0.22%) |
| pr216046 | 1532 (0.03%) | 409 (0.58%) |
| pr216436 | 663 (0.01%) | 361 (0.51%) |
| pr216470 | 14000 (0.29%) | 3778 (5.34%) |

Value facts change these patterns only; the other 19 are unchanged. These patterns' constraints read value facts, so their counts above cannot be reproduced without them.

| Pattern | Packs | Packs w/o value facts |
|---|---|---|
| pr209322 | 19 | 68811 |
| pr212132_case1 | 893 | 1118 |
| pr212132_case2 | 1935 | 2162 |
| pr216046 | 1532 | 2167 |

Candidate filtering by variant. `--no-constraint-prefilter` keeps the feature prefilter but does not evaluate the variants' constraints on a candidate's features, so a function passes when its features can match structurally even if a constraint would reject every match; it checks more packs. The no-value-facts index keeps more coarse candidates, but the fine features reject most of them before packs, so packs and modules read change only where a constraint reads value facts. A full scan reads every function and file.

| Pattern | Index packs | Index files | No-VF packs | No-VF files | No-constraint packs | No-constraint files |
|---|---|---|---|---|---|---|
| pr204089 | 539 (0.01%) | 240 (0.34%) | 539 (0.01%) | 240 (0.34%) | 539 (0.01%) | 240 (0.34%) |
| pr204927 | 17998 (0.38%) | 5097 (7.20%) | 17998 (0.38%) | 5097 (7.20%) | 19169 (0.40%) | 5346 (7.56%) |
| pr204928 | 3987 (0.08%) | 703 (0.99%) | 3987 (0.08%) | 703 (0.99%) | 6209 (0.13%) | 721 (1.02%) |
| pr205383_sub | 21 (0.00%) | 20 (0.03%) | 21 (0.00%) | 20 (0.03%) | 29 (0.00%) | 22 (0.03%) |
| pr205383_xor | 7 (0.00%) | 6 (0.01%) | 7 (0.00%) | 6 (0.01%) | 23 (0.00%) | 9 (0.01%) |
| pr207462 | 4885 (0.10%) | 1551 (2.19%) | 4885 (0.10%) | 1551 (2.19%) | 5433 (0.11%) | 1818 (2.57%) |
| pr207462_mul | 31 (0.00%) | 5 (0.01%) | 31 (0.00%) | 5 (0.01%) | 91 (0.00%) | 26 (0.04%) |
| pr207564 | 2494 (0.05%) | 1479 (2.09%) | 2494 (0.05%) | 1479 (2.09%) | 5398 (0.11%) | 2529 (3.57%) |
| pr209322 | 19 (0.00%) | 8 (0.01%) | 68811 (1.44%) | 12111 (17.12%) | 68811 (1.44%) | 12111 (17.12%) |
| pr210499 | 2959 (0.06%) | 1631 (2.31%) | 2959 (0.06%) | 1631 (2.31%) | 2959 (0.06%) | 1631 (2.31%) |
| pr212132_case1 | 893 (0.02%) | 721 (1.02%) | 1118 (0.02%) | 759 (1.07%) | 1128 (0.02%) | 766 (1.08%) |
| pr212132_case2 | 1935 (0.04%) | 1166 (1.65%) | 2162 (0.05%) | 1292 (1.83%) | 2170 (0.05%) | 1297 (1.83%) |
| pr213313 | 747 (0.02%) | 247 (0.35%) | 747 (0.02%) | 247 (0.35%) | 747 (0.02%) | 247 (0.35%) |
| pr213709 | 6312 (0.13%) | 2211 (3.12%) | 6312 (0.13%) | 2211 (3.12%) | 13146 (0.28%) | 4142 (5.85%) |
| pr214376 | 1086 (0.02%) | 341 (0.48%) | 1086 (0.02%) | 341 (0.48%) | 1213 (0.03%) | 409 (0.58%) |
| pr214381 | 253 (0.01%) | 164 (0.23%) | 253 (0.01%) | 164 (0.23%) | 899 (0.02%) | 454 (0.64%) |
| pr214517 | 819 (0.02%) | 312 (0.44%) | 819 (0.02%) | 312 (0.44%) | 1262 (0.03%) | 519 (0.73%) |
| pr214541 | 396 (0.01%) | 223 (0.32%) | 396 (0.01%) | 223 (0.32%) | 590 (0.01%) | 319 (0.45%) |
| pr215122 | 6931 (0.15%) | 2083 (2.94%) | 6931 (0.15%) | 2083 (2.94%) | 21137 (0.44%) | 5041 (7.12%) |
| pr215130 | 349 (0.01%) | 158 (0.22%) | 349 (0.01%) | 158 (0.22%) | 506 (0.01%) | 203 (0.29%) |
| pr216046 | 1532 (0.03%) | 409 (0.58%) | 2167 (0.05%) | 607 (0.86%) | 2167 (0.05%) | 607 (0.86%) |
| pr216436 | 663 (0.01%) | 361 (0.51%) | 663 (0.01%) | 361 (0.51%) | 3688 (0.08%) | 1195 (1.69%) |
| pr216470 | 14000 (0.29%) | 3778 (5.34%) | 14000 (0.29%) | 3778 (5.34%) | 15260 (0.32%) | 3983 (5.63%) |

## RQ3 and RQ4: Query time

Wall-clock seconds per PR (summed over its pattern files), each run over the whole corpus with 80 threads or processes, the median of 3 runs. The corpus fits in the machine's page cache, so these are warm-cache numbers.

Packs checked and files read are summed over a PR's pattern files (modules may repeat); they are the candidates a published query reads for the pattern.

| PR | Packs checked | Files read | MetaphIR, indexed | MetaphIR, full scan | daggrep | MetaphIR, index w/o value facts | MetaphIR, indexed, no constraint prefilter |
|---|---|---|---|---|---|---|---|
| pr204089 | 539 | 240 | 0.88 | 26.44 | 43.51 | 0.92 | 0.91 |
| pr204927 | 17998 | 5097 | 3.20 | 26.46 | 64.60 | 3.17 | 3.12 |
| pr204928 | 3987 | 703 | 1.49 | 26.34 | 65.99 | 1.48 | 1.70 |
| pr205383 | 28 | 26 | 0.95 | 52.66 | 86.63 | 0.96 | 0.96 |
| pr207462 | 4916 | 1556 | 2.25 | 51.26 | 43.74 | 2.27 | 2.37 |
| pr207564 | 2494 | 1479 | 1.34 | 25.53 | 22.44 | 1.40 | 1.65 |
| pr209322 | 19 | 8 | 0.83 | 26.11 | 22.25 | 4.24 | 4.36 |
| pr210499 | 2959 | 1631 | 2.03 | 26.21 | 87.84 | 1.92 | 2.02 |
| pr212132 | 2828 | 1887 | 3.22 | 51.85 | 44.11 | 3.31 | 3.38 |
| pr213313 | 747 | 247 | 0.83 | 26.09 | 43.78 | 0.80 | 0.81 |
| pr213709 | 6312 | 2211 | 1.81 | 25.93 | 43.36 | 1.78 | 2.44 |
| pr214376 | 1086 | 341 | 1.15 | 26.22 | 21.73 | 1.16 | 1.27 |
| pr214381 | 253 | 164 | 0.70 | 26.23 | 21.64 | 0.74 | 1.00 |
| pr214517 | 819 | 312 | 0.93 | 25.96 | 21.46 | 0.88 | 1.22 |
| pr214541 | 396 | 223 | 0.68 | 26.60 | 22.27 | 0.67 | 0.78 |
| pr215122 | 6931 | 2083 | 2.05 | 26.39 | 21.87 | 2.01 | 2.92 |
| pr215130 | 349 | 158 | 0.83 | 25.97 | 21.26 | 0.91 | 0.94 |
| pr216046 | 1532 | 409 | 1.33 | 25.95 | 21.49 | 1.60 | 1.59 |
| pr216436 | 663 | 361 | 0.93 | 25.88 | 21.76 | 0.95 | 1.31 |
| pr216470 | 14000 | 3778 | 2.73 | 26.35 | 43.64 | 2.70 | 2.98 |
| **median** | 1309.0 | 385.0 | 1.24 | 26.22 | 32.90 | 1.44 | 1.62 |
| **total** | 68856 | 22914 | 30.14 | 600.45 | 785.38 | 33.87 | 37.75 |

