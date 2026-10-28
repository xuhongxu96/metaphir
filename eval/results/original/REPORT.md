# MetaphIR evaluation (llvm-opt-benchmark)

## Setup

|  |  |
|---|---|
| MetaphIR | `49e9ffbe518635f99881268395a8cb9706fe798c` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-original`: 68843 modules, 17.35 GB |
| Functions | 28726665 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | 447862 CPU-seconds (summed per module, benchmark and test files together) |
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
| pr204089 | 1483 | 67623 | 1276 | 3.69% | 140797 | 1277 | 1.80% |
| pr204927 | 1692 | 4354 | 1384 | 45.78% | 4774 | 1384 | 42.81% |
| pr204928 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr205383 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207462 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207564 | 9 | 17 | 7 | 53.85% | 17 | 7 | 53.85% |
| pr209322 | 49 | 60 | 49 | 89.91% | 195366 | 49 | 0.05% |
| pr210499 | 3 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |
| pr212132 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213313 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213709 | 4 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |
| pr214376 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214381 | 1 | 0 | 0 | 0.00% | 4 | 0 | 0.00% |
| pr214517 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214541 | 13 | 340 | 13 | 7.37% | 603 | 13 | 4.22% |
| pr215122 | 14 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |
| pr215130 | 0 | 0 | 0 | 100.00% | 1 | 0 | 0.00% |
| pr216046 | 3 | 3 | 3 | 100.00% | 1644 | 3 | 0.36% |
| pr216436 | 54 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |
| pr216470 | 11 | 0 | 0 | 0.00% | 0 | 0 | 0.00% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 3336 | 72397 | 2732 | 69665 | 604 | 3.77% | 81.89% | 7.21% | 9 |
| MetaphIR | without pr204089 | 1853 | 4774 | 1456 | 3318 | 397 | 30.50% | 78.58% | 43.94% | 9 |
| daggrep | all | 3336 | 343206 | 2733 | 340473 | 603 | 0.80% | 81.92% | 1.58% | 7 |
| daggrep | without pr204089 | 1853 | 202409 | 1456 | 200953 | 397 | 0.72% | 78.58% | 1.43% | 7 |

## RQ3: Index

|  |  |
|---|---|
| Index build | 374.75 s |
| Index build without value facts | 320.69 s |
| Median functions whose packs are fetched | 0.00% |
| Median modules read | 0.02% |

Matching with the index found the same functions as matching without it (0 differences).

Left after pruning, per pattern. Packs checked is the number of functions whose features may match — the packs a published query fetches; files read is the number of modules it reads.

| Pattern | Packs checked | Files read |
|---|---|---|
| pr204089 | 282668 (0.98%) | 26983 (38.14%) |
| pr204927 | 4598 (0.02%) | 1404 (1.98%) |
| pr204928 | 5 (0.00%) | 1 (0.00%) |
| pr205383_sub | 2 (0.00%) | 1 (0.00%) |
| pr205383_xor | 2 (0.00%) | 1 (0.00%) |
| pr207462 | 170 (0.00%) | 82 (0.12%) |
| pr207462_mul | 4 (0.00%) | 2 (0.00%) |
| pr207564 | 96 (0.00%) | 72 (0.10%) |
| pr209322 | 81 (0.00%) | 38 (0.05%) |
| pr210499 | 9 (0.00%) | 1 (0.00%) |
| pr212132_case1 | 4 (0.00%) | 2 (0.00%) |
| pr212132_case2 | 2 (0.00%) | 1 (0.00%) |
| pr213313 | 10 (0.00%) | 2 (0.00%) |
| pr213709 | 301 (0.00%) | 184 (0.26%) |
| pr214376 | 54 (0.00%) | 14 (0.02%) |
| pr214381 | 114 (0.00%) | 73 (0.10%) |
| pr214517 | 3 (0.00%) | 1 (0.00%) |
| pr214541 | 681 (0.00%) | 336 (0.47%) |
| pr215122 | 5489 (0.02%) | 947 (1.34%) |
| pr215130 | 12 (0.00%) | 9 (0.01%) |
| pr216046 | 1529 (0.01%) | 538 (0.76%) |
| pr216436 | 4 (0.00%) | 1 (0.00%) |
| pr216470 | 202 (0.00%) | 145 (0.20%) |

Value facts change these patterns only; the other 20 are unchanged. These patterns' constraints read value facts, so their counts above cannot be reproduced without them.

| Pattern | Packs | Packs w/o value facts |
|---|---|---|
| pr209322 | 81 | 195973 |
| pr212132_case1 | 4 | 5 |
| pr216046 | 1529 | 2299 |

Candidate filtering by variant. `--no-constraint-prefilter` keeps the feature prefilter but does not evaluate the variants' constraints on a candidate's features, so a function passes when its features can match structurally even if a constraint would reject every match; it checks more packs. The no-value-facts index keeps more coarse candidates, but the fine features reject most of them before packs, so packs and modules read change only where a constraint reads value facts. A full scan reads every function and file.

| Pattern | Index packs | Index files | No-VF packs | No-VF files | No-constraint packs | No-constraint files |
|---|---|---|---|---|---|---|
| pr204089 | 282668 (0.98%) | 26983 (38.14%) | 282668 (0.98%) | 26983 (38.14%) | 282668 (0.98%) | 26983 (38.14%) |
| pr204927 | 4598 (0.02%) | 1404 (1.98%) | 4598 (0.02%) | 1404 (1.98%) | 4995 (0.02%) | 1612 (2.28%) |
| pr204928 | 5 (0.00%) | 1 (0.00%) | 5 (0.00%) | 1 (0.00%) | 6 (0.00%) | 1 (0.00%) |
| pr205383_sub | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) |
| pr205383_xor | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) | 13 (0.00%) | 1 (0.00%) |
| pr207462 | 170 (0.00%) | 82 (0.12%) | 170 (0.00%) | 82 (0.12%) | 171 (0.00%) | 82 (0.12%) |
| pr207462_mul | 4 (0.00%) | 2 (0.00%) | 4 (0.00%) | 2 (0.00%) | 6 (0.00%) | 2 (0.00%) |
| pr207564 | 96 (0.00%) | 72 (0.10%) | 96 (0.00%) | 72 (0.10%) | 364 (0.00%) | 269 (0.38%) |
| pr209322 | 81 (0.00%) | 38 (0.05%) | 195973 (0.68%) | 27833 (39.34%) | 195973 (0.68%) | 27833 (39.34%) |
| pr210499 | 9 (0.00%) | 1 (0.00%) | 9 (0.00%) | 1 (0.00%) | 9 (0.00%) | 1 (0.00%) |
| pr212132_case1 | 4 (0.00%) | 2 (0.00%) | 5 (0.00%) | 2 (0.00%) | 6 (0.00%) | 2 (0.00%) |
| pr212132_case2 | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) | 2 (0.00%) | 1 (0.00%) |
| pr213313 | 10 (0.00%) | 2 (0.00%) | 10 (0.00%) | 2 (0.00%) | 10 (0.00%) | 2 (0.00%) |
| pr213709 | 301 (0.00%) | 184 (0.26%) | 301 (0.00%) | 184 (0.26%) | 1437 (0.01%) | 526 (0.74%) |
| pr214376 | 54 (0.00%) | 14 (0.02%) | 54 (0.00%) | 14 (0.02%) | 59 (0.00%) | 16 (0.02%) |
| pr214381 | 114 (0.00%) | 73 (0.10%) | 114 (0.00%) | 73 (0.10%) | 186 (0.00%) | 132 (0.19%) |
| pr214517 | 3 (0.00%) | 1 (0.00%) | 3 (0.00%) | 1 (0.00%) | 4 (0.00%) | 1 (0.00%) |
| pr214541 | 681 (0.00%) | 336 (0.47%) | 681 (0.00%) | 336 (0.47%) | 717 (0.00%) | 358 (0.51%) |
| pr215122 | 5489 (0.02%) | 947 (1.34%) | 5489 (0.02%) | 947 (1.34%) | 8793 (0.03%) | 1481 (2.09%) |
| pr215130 | 12 (0.00%) | 9 (0.01%) | 12 (0.00%) | 9 (0.01%) | 56 (0.00%) | 41 (0.06%) |
| pr216046 | 1529 (0.01%) | 538 (0.76%) | 2299 (0.01%) | 843 (1.19%) | 2299 (0.01%) | 843 (1.19%) |
| pr216436 | 4 (0.00%) | 1 (0.00%) | 4 (0.00%) | 1 (0.00%) | 25 (0.00%) | 12 (0.02%) |
| pr216470 | 202 (0.00%) | 145 (0.20%) | 202 (0.00%) | 145 (0.20%) | 230 (0.00%) | 151 (0.21%) |

## RQ3 and RQ4: Query time

Wall-clock seconds per PR (summed over its pattern files), each run over the whole corpus with 80 threads or processes, the median of 3 runs. The corpus fits in the machine's page cache, so these are warm-cache numbers.

Packs checked and files read are summed over a PR's pattern files (modules may repeat); they are the candidates a published query reads for the pattern.

| PR | Packs checked | Files read | MetaphIR, indexed | MetaphIR, full scan | daggrep | MetaphIR, index w/o value facts | MetaphIR, indexed, no constraint prefilter |
|---|---|---|---|---|---|---|---|
| pr204089 | 282668 | 26983 | 12.55 | 37.87 | 63.19 | 11.91 | 12.21 |
| pr204927 | 4598 | 1404 | 3.41 | 37.26 | 89.97 | 3.47 | 3.45 |
| pr204928 | 5 | 1 | 0.64 | 37.17 | 87.59 | 0.63 | 0.62 |
| pr205383 | 4 | 2 | 0.99 | 74.89 | 117.29 | 0.98 | 0.99 |
| pr207462 | 174 | 84 | 1.20 | 72.69 | 58.41 | 1.21 | 1.21 |
| pr207564 | 96 | 72 | 0.69 | 37.38 | 30.19 | 0.59 | 1.10 |
| pr209322 | 81 | 38 | 2.86 | 36.70 | 30.91 | 9.94 | 10.63 |
| pr210499 | 9 | 1 | 2.06 | 37.24 | 119.03 | 1.90 | 2.07 |
| pr212132 | 6 | 3 | 0.98 | 74.69 | 60.41 | 0.99 | 0.99 |
| pr213313 | 10 | 2 | 0.49 | 37.91 | 59.39 | 0.49 | 0.50 |
| pr213709 | 301 | 184 | 1.09 | 37.21 | 57.89 | 1.04 | 2.01 |
| pr214376 | 54 | 14 | 0.50 | 37.19 | 29.93 | 0.52 | 0.52 |
| pr214381 | 114 | 73 | 1.30 | 35.98 | 29.62 | 1.32 | 1.40 |
| pr214517 | 3 | 1 | 0.50 | 36.62 | 29.70 | 0.49 | 0.49 |
| pr214541 | 681 | 336 | 1.75 | 36.75 | 30.00 | 1.77 | 1.79 |
| pr215122 | 5489 | 947 | 2.33 | 37.65 | 28.95 | 2.28 | 2.68 |
| pr215130 | 12 | 9 | 0.55 | 37.02 | 30.55 | 0.54 | 0.61 |
| pr216046 | 1529 | 538 | 2.27 | 36.27 | 29.88 | 2.39 | 2.39 |
| pr216436 | 4 | 1 | 0.50 | 36.10 | 29.03 | 0.50 | 0.49 |
| pr216470 | 202 | 145 | 0.94 | 36.88 | 59.14 | 0.86 | 0.94 |
| **median** | 88.5 | 55.0 | 1.04 | 37.20 | 44.40 | 1.02 | 1.15 |
| **total** | 296040 | 30838 | 37.59 | 851.46 | 1071.07 | 43.83 | 47.08 |

