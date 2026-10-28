# MetaphIR evaluation

## Setup

|  |  |
|---|---|
| MetaphIR | `0a772f14f410598bdd4def2d6e9b33fc741499db` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-o2-final`: 68843 modules + 1912 test files, 11.93 GB |
| Functions | 4776770 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | `eval/results/original/gt-pipeline`, 352280 CPU-seconds (summed per module) |
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
| pr204089 | 15490 | 12 | 3 | 0.04% | 16 | 3 | 0.04% |
| pr204927 | 759 | 1978 | 510 | 37.27% | 4350 | 523 | 20.47% |
| pr204928 | 143 | 1271 | 141 | 19.94% | 5170 | 142 | 5.35% |
| pr205383 | 5 | 4 | 4 | 88.89% | 16 | 5 | 47.62% |
| pr207462 | 31 | 34 | 31 | 95.38% | 218 | 31 | 24.90% |
| pr207564 | 42 | 58 | 33 | 66.00% | 61 | 33 | 64.08% |
| pr209322 | 40 | 19 | 12 | 40.68% | 68811 | 14 | 0.04% |
| pr210499 | 21 | 18 | 15 | 76.92% | 5534 | 15 | 0.54% |
| pr212132 | 5 | 5 | 5 | 100.00% | 5 | 3 | 60.00% |
| pr213313 | 10 | 10 | 10 | 100.00% | 10 | 10 | 100.00% |
| pr213709 | 28 | 26 | 23 | 85.19% | 36 | 23 | 71.88% |
| pr214376 | 14 | 13 | 13 | 96.30% | 18 | 14 | 87.50% |
| pr214381 | 15 | 16 | 12 | 77.42% | 26 | 14 | 68.29% |
| pr214517 | 16 | 27 | 16 | 74.42% | 478 | 15 | 6.07% |
| pr214541 | 28 | 23 | 17 | 66.67% | 299 | 17 | 10.40% |
| pr215122 | 31 | 40 | 26 | 73.24% | 179 | 26 | 24.76% |
| pr215130 | 5 | 3 | 3 | 75.00% | 14 | 3 | 31.58% |
| pr216046 | 2 | 66 | 2 | 5.88% | 1695 | 2 | 0.24% |
| pr216436 | 46 | 48 | 36 | 76.60% | 58 | 38 | 73.08% |
| pr216470 | 158 | 340 | 142 | 57.03% | 3836 | 145 | 7.26% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 16889 | 4011 | 1054 | 2957 | 15835 | 26.28% | 6.24% | 10.09% | 2 |
| MetaphIR | without pr204089 | 1399 | 3999 | 1051 | 2948 | 348 | 26.28% | 75.13% | 38.94% | 2 |
| daggrep | all | 16889 | 90830 | 1076 | 89754 | 15813 | 1.18% | 6.37% | 2.00% | 1 |
| daggrep | without pr204089 | 1399 | 90814 | 1073 | 89741 | 326 | 1.18% | 76.70% | 2.33% | 1 |

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
| pr215122 | 6932 (0.15%) | 2083 (2.94%) |
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
| pr215122 | 6932 (0.15%) | 2083 (2.94%) | 6932 (0.15%) | 2083 (2.94%) | 21137 (0.44%) | 5041 (7.12%) |
| pr215130 | 349 (0.01%) | 158 (0.22%) | 349 (0.01%) | 158 (0.22%) | 506 (0.01%) | 203 (0.29%) |
| pr216046 | 1532 (0.03%) | 409 (0.58%) | 2167 (0.05%) | 607 (0.86%) | 2167 (0.05%) | 607 (0.86%) |
| pr216436 | 663 (0.01%) | 361 (0.51%) | 663 (0.01%) | 361 (0.51%) | 3688 (0.08%) | 1195 (1.69%) |
| pr216470 | 14000 (0.29%) | 3778 (5.34%) | 14000 (0.29%) | 3778 (5.34%) | 15260 (0.32%) | 3983 (5.63%) |

## RQ3 and RQ4: Query time

Wall-clock seconds per PR (summed over its pattern files), each run over the whole corpus with 80 threads or processes, the median of 3 runs. The corpus fits in the machine's page cache, so these are warm-cache numbers.

Packs checked and files read are summed over a PR's pattern files (modules may repeat); they are the candidates a published query reads for the pattern.

| PR | Packs checked | Files read | MetaphIR, indexed | MetaphIR, full scan | daggrep | MetaphIR, index w/o value facts | MetaphIR, indexed, no constraint prefilter |
|---|---|---|---|---|---|---|---|
| pr204089 | 539 | 240 | 1.00 | 26.74 | 44.01 | 1.01 | 0.95 |
| pr204927 | 17998 | 5097 | 3.20 | 27.81 | 64.74 | 3.21 | 3.28 |
| pr204928 | 3987 | 703 | 1.53 | 26.62 | 64.95 | 1.57 | 1.76 |
| pr205383 | 28 | 26 | 1.13 | 51.79 | 85.93 | 1.11 | 1.12 |
| pr207462 | 4916 | 1556 | 2.44 | 53.67 | 43.96 | 2.38 | 2.50 |
| pr207564 | 2494 | 1479 | 1.42 | 26.09 | 22.39 | 1.42 | 1.67 |
| pr209322 | 19 | 8 | 1.00 | 26.84 | 21.97 | 4.41 | 4.43 |
| pr210499 | 2959 | 1631 | 2.14 | 27.15 | 86.54 | 2.05 | 2.15 |
| pr212132 | 2828 | 1887 | 3.37 | 52.36 | 42.83 | 3.50 | 3.59 |
| pr213313 | 747 | 247 | 0.93 | 26.45 | 43.51 | 0.91 | 0.93 |
| pr213709 | 6312 | 2211 | 1.90 | 25.71 | 42.53 | 1.80 | 2.47 |
| pr214376 | 1086 | 341 | 1.19 | 26.82 | 21.71 | 1.15 | 1.28 |
| pr214381 | 253 | 164 | 0.77 | 26.62 | 21.83 | 0.82 | 1.12 |
| pr214517 | 819 | 312 | 0.93 | 26.07 | 21.93 | 0.99 | 1.22 |
| pr214541 | 396 | 223 | 0.76 | 26.60 | 21.50 | 0.74 | 0.80 |
| pr215122 | 6932 | 2083 | 2.06 | 25.48 | 21.48 | 2.07 | 2.92 |
| pr215130 | 349 | 158 | 0.94 | 26.27 | 21.86 | 0.93 | 1.00 |
| pr216046 | 1532 | 409 | 1.44 | 26.96 | 21.50 | 1.67 | 1.64 |
| pr216436 | 663 | 361 | 1.04 | 26.25 | 21.52 | 1.00 | 1.40 |
| pr216470 | 14000 | 3778 | 2.87 | 26.59 | 42.76 | 2.78 | 3.02 |
| **median** | 1309.0 | 385.0 | 1.31 | 26.62 | 32.46 | 1.49 | 1.66 |
| **total** | 68857 | 22914 | 32.08 | 608.89 | 779.45 | 35.53 | 39.26 |

