# MetaphIR evaluation (llvm-opt-benchmark)

## Setup

|  |  |
|---|---|
| MetaphIR | `60392545555eba789f0806e6cd43bfff74e202cd` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-o2-final`: 68843 modules, 11.90 GB |
| Functions | 4771730 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | 3037 CPU-seconds (summed per module, benchmark and test files together) |
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
| pr204089 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr204927 | 1973 | 1973 | 1973 | 100.00% | 4343 | 1973 | 62.48% |
| pr204928 | 1266 | 1266 | 1266 | 100.00% | 5163 | 1266 | 39.38% |
| pr205383 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207462 | 31 | 31 | 31 | 100.00% | 212 | 31 | 25.51% |
| pr207564 | 52 | 52 | 52 | 100.00% | 54 | 52 | 98.11% |
| pr209322 | 0 | 0 | 0 | 100.00% | 68175 | 0 | 0.00% |
| pr210499 | 10 | 10 | 10 | 100.00% | 5524 | 10 | 0.36% |
| pr212132 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213313 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213709 | 9 | 9 | 9 | 100.00% | 9 | 9 | 100.00% |
| pr214376 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214381 | 9 | 9 | 9 | 100.00% | 14 | 9 | 78.26% |
| pr214517 | 24 | 24 | 24 | 100.00% | 475 | 24 | 9.62% |
| pr214541 | 18 | 18 | 18 | 100.00% | 284 | 18 | 11.92% |
| pr215122 | 32 | 32 | 32 | 100.00% | 168 | 32 | 32.00% |
| pr215130 | 3 | 3 | 3 | 100.00% | 14 | 3 | 35.29% |
| pr216046 | 57 | 57 | 57 | 100.00% | 1680 | 57 | 6.56% |
| pr216436 | 44 | 44 | 44 | 100.00% | 52 | 44 | 91.67% |
| pr216470 | 333 | 333 | 333 | 100.00% | 3817 | 333 | 16.05% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 3861 | 3861 | 3861 | 0 | 0 | 100.00% | 100.00% | 100.00% | 20 |
| MetaphIR | without pr204089 | 3861 | 3861 | 3861 | 0 | 0 | 100.00% | 100.00% | 100.00% | 19 |
| daggrep | all | 3861 | 89984 | 3861 | 86123 | 0 | 4.29% | 100.00% | 8.23% | 6 |
| daggrep | without pr204089 | 3861 | 89984 | 3861 | 86123 | 0 | 4.29% | 100.00% | 8.23% | 5 |

## RQ3: Index

|  |  |
|---|---|
| Index build | 142.44 s |
| Index build without value facts | 113.00 s |
| Median functions whose packs are fetched | 0.02% |
| Median modules read | 0.51% |

Matching with the index found the same functions as matching without it (0 differences).

Left after pruning, per pattern. Packs checked is the number of functions whose features may match — the packs a published query fetches; files read is the number of modules it reads.

| Pattern | Packs checked | Files read |
|---|---|---|
| pr204089 | 521 (0.01%) | 232 (0.33%) |
| pr204927 | 17996 (0.38%) | 5095 (7.20%) |
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
| pr209322 | 19 | 68782 |
| pr212132_case1 | 893 | 1118 |
| pr212132_case2 | 1935 | 2162 |
| pr216046 | 1532 | 2167 |

Candidate filtering by variant. `--no-constraint-prefilter` keeps the feature prefilter but does not evaluate the variants' constraints on a candidate's features, so a function passes when its features can match structurally even if a constraint would reject every match; it checks more packs. The no-value-facts index keeps more coarse candidates, but the fine features reject most of them before packs, so packs and modules read change only where a constraint reads value facts. A full scan reads every function and file.

| Pattern | Index packs | Index files | No-VF packs | No-VF files | No-constraint packs | No-constraint files |
|---|---|---|---|---|---|---|
| pr204089 | 521 (0.01%) | 232 (0.33%) | 521 (0.01%) | 232 (0.33%) | 521 (0.01%) | 232 (0.33%) |
| pr204927 | 17996 (0.38%) | 5095 (7.20%) | 17996 (0.38%) | 5095 (7.20%) | 19167 (0.40%) | 5344 (7.55%) |
| pr204928 | 3987 (0.08%) | 703 (0.99%) | 3987 (0.08%) | 703 (0.99%) | 6209 (0.13%) | 721 (1.02%) |
| pr205383_sub | 21 (0.00%) | 20 (0.03%) | 21 (0.00%) | 20 (0.03%) | 29 (0.00%) | 22 (0.03%) |
| pr205383_xor | 7 (0.00%) | 6 (0.01%) | 7 (0.00%) | 6 (0.01%) | 23 (0.00%) | 9 (0.01%) |
| pr207462 | 4885 (0.10%) | 1551 (2.19%) | 4885 (0.10%) | 1551 (2.19%) | 5433 (0.11%) | 1818 (2.57%) |
| pr207462_mul | 31 (0.00%) | 5 (0.01%) | 31 (0.00%) | 5 (0.01%) | 91 (0.00%) | 26 (0.04%) |
| pr207564 | 2494 (0.05%) | 1479 (2.09%) | 2494 (0.05%) | 1479 (2.09%) | 5398 (0.11%) | 2529 (3.57%) |
| pr209322 | 19 (0.00%) | 8 (0.01%) | 68782 (1.44%) | 12101 (17.10%) | 68782 (1.44%) | 12101 (17.10%) |
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
| pr204089 | 521 | 232 | 0.91 | 26.20 | 43.07 | 0.91 | 0.89 |
| pr204927 | 17996 | 5095 | 3.26 | 26.00 | 64.52 | 3.11 | 3.20 |
| pr204928 | 3987 | 703 | 1.46 | 26.04 | 65.11 | 1.45 | 1.71 |
| pr205383 | 28 | 26 | 0.90 | 51.46 | 86.59 | 0.90 | 0.95 |
| pr207462 | 4916 | 1556 | 2.25 | 51.30 | 42.54 | 2.22 | 2.41 |
| pr207564 | 2494 | 1479 | 1.37 | 26.29 | 21.72 | 1.39 | 1.64 |
| pr209322 | 19 | 8 | 0.86 | 25.92 | 21.44 | 4.37 | 4.41 |
| pr210499 | 2959 | 1631 | 2.04 | 26.79 | 86.71 | 1.98 | 1.98 |
| pr212132 | 2828 | 1887 | 3.23 | 51.67 | 44.12 | 3.26 | 3.40 |
| pr213313 | 747 | 247 | 0.85 | 26.09 | 43.11 | 0.81 | 0.84 |
| pr213709 | 6312 | 2211 | 1.81 | 26.02 | 43.52 | 1.81 | 2.46 |
| pr214376 | 1086 | 341 | 1.17 | 25.95 | 21.15 | 1.16 | 1.22 |
| pr214381 | 253 | 164 | 0.69 | 25.32 | 21.52 | 0.66 | 0.98 |
| pr214517 | 819 | 312 | 0.93 | 26.71 | 21.35 | 0.91 | 1.18 |
| pr214541 | 396 | 223 | 0.63 | 26.32 | 20.68 | 0.60 | 0.71 |
| pr215122 | 6931 | 2083 | 2.04 | 26.05 | 21.89 | 1.95 | 2.88 |
| pr215130 | 349 | 158 | 0.90 | 26.61 | 22.39 | 0.88 | 0.93 |
| pr216046 | 1532 | 409 | 1.37 | 26.46 | 21.21 | 1.54 | 1.66 |
| pr216436 | 663 | 361 | 1.04 | 25.70 | 21.14 | 0.95 | 1.37 |
| pr216470 | 14000 | 3778 | 2.83 | 26.29 | 43.86 | 2.77 | 3.08 |
| **median** | 1309.0 | 385.0 | 1.27 | 26.25 | 32.46 | 1.42 | 1.65 |
| **total** | 68836 | 22904 | 30.53 | 599.17 | 777.65 | 33.62 | 37.89 |

## WebAssembly

The production site in headless Chromium, one cold browser context per pattern, download throttled to 10 MB/s (`eval/scripts/web_ablate.mjs`). Each cell is the median of the pattern's runs; bytes are those read for the query, without the corpus header. Runs that did not finish: Full 0, No constraints 0.

| Pattern | Full time | Full read | No constraints time | No constraints read |
|---|---|---|---|---|
| pr204089 | 10.8 s | 97 MB | 14.4 s | 131 MB |
| pr204927 | 283.5 s | 1825 MB | 358.5 s | 2194 MB |
| pr204928 | 56.2 s | 343 MB | 65.5 s | 370 MB |
| pr205383_sub | 5.3 s | 45 MB | 5.3 s | 46 MB |
| pr205383_xor | 3.1 s | 25 MB | 3.3 s | 26 MB |
| pr207462 | 86.7 s | 819 MB | 92.2 s | 873 MB |
| pr207462_mul | 1.1 s | 7 MB | 1.7 s | 12 MB |
| pr207564 | 57.3 s | 539 MB | 78.2 s | 736 MB |
| pr209322 | 89.7 s | 852 MB | 382.6 s | 3564 MB |
| pr210499 | 125.9 s | 1169 MB | 206.6 s | 1925 MB |
| pr212132_case1 | 37.7 s | 357 MB | 38.6 s | 366 MB |
| pr212132_case2 | 47.8 s | 456 MB | 51.0 s | 486 MB |
| pr213313 | 7.6 s | 68 MB | 7.6 s | 68 MB |
| pr213709 | 91.3 s | 863 MB | 132.8 s | 1256 MB |
| pr214376 | 16.2 s | 151 MB | 24.0 s | 226 MB |
| pr214381 | 19.4 s | 183 MB | 23.5 s | 223 MB |
| pr214517 | 28.4 s | 269 MB | 30.6 s | 289 MB |
| pr214541 | 8.2 s | 73 MB | 9.0 s | 81 MB |
| pr215122 | 95.5 s | 907 MB | 156.3 s | 1483 MB |
| pr215130 | 5.9 s | 52 MB | 6.2 s | 55 MB |
| pr216046 | 25.0 s | 233 MB | 29.3 s | 274 MB |
| pr216436 | 24.5 s | 229 MB | 44.0 s | 410 MB |
| pr216470 | 133.3 s | 1254 MB | 144.3 s | 1362 MB |
| **median** | 28.4 s | 269 MB | 38.6 s | 366 MB |
| **mean** | 54.8 s | 470 MB | 82.8 s | 715 MB |
| **max** | 283.5 s | 1825 MB | 382.6 s | 3564 MB |

