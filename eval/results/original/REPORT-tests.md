# MetaphIR evaluation (test suite)

## Setup

|  |  |
|---|---|
| MetaphIR | `49e9ffbe518635f99881268395a8cb9706fe798c` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-original`: 1912 test files, 0.02 GB |
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
| pr204089 | 2 | 3 | 2 | 80.00% | 6 | 2 | 50.00% |
| pr204927 | 5 | 5 | 5 | 100.00% | 7 | 5 | 83.33% |
| pr204928 | 5 | 5 | 5 | 100.00% | 7 | 5 | 83.33% |
| pr205383 | 5 | 4 | 4 | 88.89% | 16 | 5 | 47.62% |
| pr207462 | 3 | 3 | 3 | 100.00% | 6 | 3 | 66.67% |
| pr207564 | 5 | 6 | 5 | 90.91% | 7 | 5 | 83.33% |
| pr209322 | 15 | 19 | 14 | 82.35% | 607 | 15 | 4.82% |
| pr210499 | 8 | 8 | 8 | 100.00% | 10 | 8 | 88.89% |
| pr212132 | 5 | 5 | 5 | 100.00% | 5 | 3 | 60.00% |
| pr213313 | 10 | 10 | 10 | 100.00% | 10 | 10 | 100.00% |
| pr213709 | 17 | 17 | 17 | 100.00% | 27 | 17 | 77.27% |
| pr214376 | 14 | 13 | 13 | 96.30% | 18 | 14 | 87.50% |
| pr214381 | 5 | 7 | 5 | 83.33% | 12 | 5 | 58.82% |
| pr214517 | 3 | 3 | 3 | 100.00% | 3 | 2 | 66.67% |
| pr214541 | 5 | 5 | 5 | 100.00% | 15 | 5 | 50.00% |
| pr215122 | 8 | 8 | 8 | 100.00% | 11 | 8 | 84.21% |
| pr215130 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr216046 | 9 | 9 | 9 | 100.00% | 15 | 9 | 75.00% |
| pr216436 | 4 | 4 | 4 | 100.00% | 6 | 4 | 80.00% |
| pr216470 | 7 | 7 | 7 | 100.00% | 19 | 7 | 53.85% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 135 | 141 | 132 | 9 | 3 | 93.62% | 97.78% | 95.65% | 14 |
| MetaphIR | without pr204089 | 133 | 138 | 130 | 8 | 3 | 94.20% | 97.74% | 95.94% | 14 |
| daggrep | all | 135 | 807 | 132 | 675 | 3 | 16.36% | 97.78% | 28.03% | 2 |
| daggrep | without pr204089 | 133 | 801 | 130 | 671 | 3 | 16.23% | 97.74% | 27.84% | 2 |

This report scores only the test suite functions. The index and query-time measurements (RQ3) are one run over the whole corpus and cannot be split by source; see `REPORT.md`.

