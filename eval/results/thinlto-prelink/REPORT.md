# MetaphIR evaluation (llvm-opt-benchmark)

## Setup

|  |  |
|---|---|
| MetaphIR | `49e9ffbe518635f99881268395a8cb9706fe798c` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-thinlto-prelink`: 68843 modules, 12.51 GB |
| Functions | 4832829 |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | 71976 CPU-seconds (summed per module, benchmark and test files together) |
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
| pr204089 | 1134 | 11 | 2 | 0.35% | 12 | 2 | 0.35% |
| pr204927 | 2011 | 2012 | 2011 | 99.98% | 4373 | 2011 | 63.00% |
| pr204928 | 1266 | 1266 | 1266 | 100.00% | 5163 | 1266 | 39.38% |
| pr205383 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr207462 | 31 | 31 | 31 | 100.00% | 205 | 31 | 26.27% |
| pr207564 | 52 | 52 | 52 | 100.00% | 54 | 52 | 98.11% |
| pr209322 | 0 | 0 | 0 | 100.00% | 67777 | 0 | 0.00% |
| pr210499 | 10 | 10 | 10 | 100.00% | 5527 | 10 | 0.36% |
| pr212132 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213313 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr213709 | 13 | 9 | 9 | 81.82% | 9 | 9 | 81.82% |
| pr214376 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr214381 | 9 | 9 | 9 | 100.00% | 14 | 9 | 78.26% |
| pr214517 | 24 | 24 | 24 | 100.00% | 479 | 24 | 9.54% |
| pr214541 | 18 | 18 | 18 | 100.00% | 252 | 18 | 13.33% |
| pr215122 | 32 | 32 | 32 | 100.00% | 165 | 32 | 32.49% |
| pr215130 | 3 | 3 | 3 | 100.00% | 21 | 3 | 25.00% |
| pr216046 | 0 | 0 | 0 | 100.00% | 1680 | 0 | 0.00% |
| pr216436 | 44 | 44 | 44 | 100.00% | 52 | 44 | 91.67% |
| pr216470 | 338 | 338 | 338 | 100.00% | 3820 | 338 | 16.26% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 4985 | 3859 | 3849 | 10 | 1136 | 99.74% | 77.21% | 87.04% | 17 |
| MetaphIR | without pr204089 | 3851 | 3848 | 3847 | 1 | 4 | 99.97% | 99.90% | 99.94% | 17 |
| daggrep | all | 4985 | 89603 | 3849 | 85754 | 1136 | 4.30% | 77.21% | 8.14% | 4 |
| daggrep | without pr204089 | 3851 | 89591 | 3847 | 85744 | 4 | 4.29% | 99.90% | 8.23% | 4 |

## RQ3: Index

|  |  |
|---|---|
| Index build | 146.82 s |
| Index build without value facts | 112.56 s |
| Median functions whose packs are fetched | 0.02% |
| Median modules read | 0.50% |

Matching with the index found the same functions as matching without it (0 differences).

Left after pruning, per pattern. Packs checked is the number of functions whose features may match — the packs a published query fetches; files read is the number of modules it reads.

| Pattern | Packs checked | Files read |
|---|---|---|
| pr204089 | 555 (0.01%) | 250 (0.35%) |
| pr204927 | 18052 (0.37%) | 5071 (7.17%) |
| pr204928 | 3962 (0.08%) | 696 (0.98%) |
| pr205383_sub | 13 (0.00%) | 12 (0.02%) |
| pr205383_xor | 6 (0.00%) | 5 (0.01%) |
| pr207462 | 3541 (0.07%) | 1239 (1.75%) |
| pr207462_mul | 31 (0.00%) | 5 (0.01%) |
| pr207564 | 2423 (0.05%) | 1392 (1.97%) |
| pr209322 | 19 (0.00%) | 8 (0.01%) |
| pr210499 | 1799 (0.04%) | 1043 (1.47%) |
| pr212132_case1 | 805 (0.02%) | 666 (0.94%) |
| pr212132_case2 | 1797 (0.04%) | 1071 (1.51%) |
| pr213313 | 582 (0.01%) | 137 (0.19%) |
| pr213709 | 2002 (0.04%) | 1120 (1.58%) |
| pr214376 | 1094 (0.02%) | 352 (0.50%) |
| pr214381 | 239 (0.00%) | 153 (0.22%) |
| pr214517 | 860 (0.02%) | 319 (0.45%) |
| pr214541 | 385 (0.01%) | 224 (0.32%) |
| pr215122 | 5481 (0.11%) | 1415 (2.00%) |
| pr215130 | 338 (0.01%) | 161 (0.23%) |
| pr216046 | 1535 (0.03%) | 411 (0.58%) |
| pr216436 | 602 (0.01%) | 317 (0.45%) |
| pr216470 | 12888 (0.27%) | 3506 (4.96%) |

Value facts change these patterns only; the other 19 are unchanged. These patterns' constraints read value facts, so their counts above cannot be reproduced without them.

| Pattern | Packs | Packs w/o value facts |
|---|---|---|
| pr209322 | 19 | 68384 |
| pr212132_case1 | 805 | 1022 |
| pr212132_case2 | 1797 | 2010 |
| pr216046 | 1535 | 2167 |

Candidate filtering by variant. `--no-constraint-prefilter` keeps the feature prefilter but does not evaluate the variants' constraints on a candidate's features, so a function passes when its features can match structurally even if a constraint would reject every match; it checks more packs. The no-value-facts index keeps more coarse candidates, but the fine features reject most of them before packs, so packs and modules read change only where a constraint reads value facts. A full scan reads every function and file.

| Pattern | Index packs | Index files | No-VF packs | No-VF files | No-constraint packs | No-constraint files |
|---|---|---|---|---|---|---|
| pr204089 | 555 (0.01%) | 250 (0.35%) | 555 (0.01%) | 250 (0.35%) | 555 (0.01%) | 250 (0.35%) |
| pr204927 | 18052 (0.37%) | 5071 (7.17%) | 18052 (0.37%) | 5071 (7.17%) | 19226 (0.40%) | 5322 (7.52%) |
| pr204928 | 3962 (0.08%) | 696 (0.98%) | 3962 (0.08%) | 696 (0.98%) | 6202 (0.13%) | 714 (1.01%) |
| pr205383_sub | 13 (0.00%) | 12 (0.02%) | 13 (0.00%) | 12 (0.02%) | 17 (0.00%) | 12 (0.02%) |
| pr205383_xor | 6 (0.00%) | 5 (0.01%) | 6 (0.00%) | 5 (0.01%) | 19 (0.00%) | 7 (0.01%) |
| pr207462 | 3541 (0.07%) | 1239 (1.75%) | 3541 (0.07%) | 1239 (1.75%) | 3990 (0.08%) | 1460 (2.06%) |
| pr207462_mul | 31 (0.00%) | 5 (0.01%) | 31 (0.00%) | 5 (0.01%) | 87 (0.00%) | 24 (0.03%) |
| pr207564 | 2423 (0.05%) | 1392 (1.97%) | 2423 (0.05%) | 1392 (1.97%) | 5175 (0.11%) | 2374 (3.36%) |
| pr209322 | 19 (0.00%) | 8 (0.01%) | 68384 (1.41%) | 12032 (17.01%) | 68384 (1.41%) | 12032 (17.01%) |
| pr210499 | 1799 (0.04%) | 1043 (1.47%) | 1799 (0.04%) | 1043 (1.47%) | 1799 (0.04%) | 1043 (1.47%) |
| pr212132_case1 | 805 (0.02%) | 666 (0.94%) | 1022 (0.02%) | 699 (0.99%) | 1033 (0.02%) | 707 (1.00%) |
| pr212132_case2 | 1797 (0.04%) | 1071 (1.51%) | 2010 (0.04%) | 1186 (1.68%) | 2016 (0.04%) | 1191 (1.68%) |
| pr213313 | 582 (0.01%) | 137 (0.19%) | 582 (0.01%) | 137 (0.19%) | 582 (0.01%) | 137 (0.19%) |
| pr213709 | 2002 (0.04%) | 1120 (1.58%) | 2002 (0.04%) | 1120 (1.58%) | 4009 (0.08%) | 1763 (2.49%) |
| pr214376 | 1094 (0.02%) | 352 (0.50%) | 1094 (0.02%) | 352 (0.50%) | 1227 (0.03%) | 424 (0.60%) |
| pr214381 | 239 (0.00%) | 153 (0.22%) | 239 (0.00%) | 153 (0.22%) | 796 (0.02%) | 423 (0.60%) |
| pr214517 | 860 (0.02%) | 319 (0.45%) | 860 (0.02%) | 319 (0.45%) | 1309 (0.03%) | 527 (0.74%) |
| pr214541 | 385 (0.01%) | 224 (0.32%) | 385 (0.01%) | 224 (0.32%) | 558 (0.01%) | 308 (0.44%) |
| pr215122 | 5481 (0.11%) | 1415 (2.00%) | 5481 (0.11%) | 1415 (2.00%) | 14021 (0.29%) | 2926 (4.14%) |
| pr215130 | 338 (0.01%) | 161 (0.23%) | 338 (0.01%) | 161 (0.23%) | 494 (0.01%) | 207 (0.29%) |
| pr216046 | 1535 (0.03%) | 411 (0.58%) | 2167 (0.04%) | 607 (0.86%) | 2167 (0.04%) | 607 (0.86%) |
| pr216436 | 602 (0.01%) | 317 (0.45%) | 602 (0.01%) | 317 (0.45%) | 3669 (0.08%) | 1178 (1.66%) |
| pr216470 | 12888 (0.27%) | 3506 (4.96%) | 12888 (0.27%) | 3506 (4.96%) | 13922 (0.29%) | 3635 (5.14%) |

## RQ3 and RQ4: Query time

Wall-clock seconds per PR (summed over its pattern files), each run over the whole corpus with 80 threads or processes, the median of 3 runs. The corpus fits in the machine's page cache, so these are warm-cache numbers.

Packs checked and files read are summed over a PR's pattern files (modules may repeat); they are the candidates a published query reads for the pattern.

| PR | Packs checked | Files read | MetaphIR, indexed | MetaphIR, full scan | daggrep | MetaphIR, index w/o value facts | MetaphIR, indexed, no constraint prefilter |
|---|---|---|---|---|---|---|---|
| pr204089 | 555 | 250 | 1.04 | 26.08 | 45.42 | 1.06 | 1.06 |
| pr204927 | 18052 | 5071 | 3.40 | 27.33 | 70.21 | 3.32 | 3.37 |
| pr204928 | 3962 | 696 | 1.55 | 28.10 | 70.39 | 1.60 | 1.81 |
| pr205383 | 19 | 17 | 1.12 | 55.03 | 94.21 | 1.08 | 1.12 |
| pr207462 | 3572 | 1244 | 2.25 | 53.96 | 47.76 | 2.24 | 2.34 |
| pr207564 | 2423 | 1392 | 1.54 | 27.58 | 23.37 | 1.54 | 1.78 |
| pr209322 | 19 | 8 | 0.96 | 27.57 | 24.58 | 4.67 | 4.76 |
| pr210499 | 1799 | 1043 | 2.10 | 28.01 | 94.75 | 2.04 | 2.06 |
| pr212132 | 2602 | 1737 | 3.42 | 55.26 | 47.53 | 3.55 | 3.54 |
| pr213313 | 582 | 137 | 0.84 | 27.86 | 46.80 | 0.86 | 0.84 |
| pr213709 | 2002 | 1120 | 1.49 | 28.00 | 46.78 | 1.54 | 1.94 |
| pr214376 | 1094 | 352 | 1.35 | 27.30 | 24.07 | 1.37 | 1.48 |
| pr214381 | 239 | 153 | 0.85 | 28.11 | 23.28 | 0.86 | 1.15 |
| pr214517 | 860 | 319 | 1.02 | 27.18 | 23.41 | 1.06 | 1.35 |
| pr214541 | 385 | 224 | 0.78 | 27.98 | 23.61 | 0.81 | 0.86 |
| pr215122 | 5481 | 1415 | 1.93 | 27.70 | 23.23 | 1.90 | 2.52 |
| pr215130 | 338 | 161 | 1.01 | 26.92 | 23.34 | 0.99 | 1.07 |
| pr216046 | 1535 | 411 | 1.58 | 27.23 | 23.63 | 1.80 | 1.80 |
| pr216436 | 602 | 317 | 1.02 | 27.23 | 23.70 | 1.04 | 1.57 |
| pr216470 | 12888 | 3506 | 3.00 | 27.83 | 45.68 | 2.98 | 3.04 |
| **median** | 1314.5 | 381.5 | 1.42 | 27.77 | 35.00 | 1.54 | 1.79 |
| **total** | 59009 | 19573 | 32.25 | 632.26 | 845.75 | 36.33 | 39.45 |

