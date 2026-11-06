# MetaphIR evaluation (test suite)

## Setup

|  |  |
|---|---|
| MetaphIR | `de162aa9294ce92e7089772b0ca661f473a31321` |
| LLVM | `79b321b1238ceaf8261a5b177185a3ec5111918a` + `eval/patches/` |
| Corpus | `eval/corpus-o2-final`: 1912 test files, 0.02 GB |
| Machine | Neoverse-N1 (aarch64), 80 cores, 502 GiB, Ubuntu 22.04.5 LTS, Linux 5.15.0-174-generic |
| Ground truth | 3032 CPU-seconds (summed per module, benchmark and test files together) |
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
| pr204089 | 3 | 3 | 3 | 100.00% | 6 | 3 | 66.67% |
| pr204927 | 5 | 5 | 5 | 100.00% | 7 | 5 | 83.33% |
| pr204928 | 5 | 5 | 5 | 100.00% | 7 | 5 | 83.33% |
| pr205383 | 4 | 4 | 4 | 100.00% | 16 | 4 | 40.00% |
| pr207462 | 3 | 3 | 3 | 100.00% | 6 | 3 | 66.67% |
| pr207564 | 6 | 6 | 6 | 100.00% | 7 | 6 | 92.31% |
| pr209322 | 19 | 19 | 19 | 100.00% | 607 | 19 | 6.07% |
| pr210499 | 8 | 8 | 8 | 100.00% | 10 | 8 | 88.89% |
| pr212132 | 5 | 5 | 5 | 100.00% | 5 | 3 | 60.00% |
| pr213313 | 10 | 10 | 10 | 100.00% | 10 | 10 | 100.00% |
| pr213709 | 17 | 17 | 17 | 100.00% | 27 | 17 | 77.27% |
| pr214376 | 14 | 13 | 13 | 96.30% | 18 | 14 | 87.50% |
| pr214381 | 7 | 7 | 7 | 100.00% | 12 | 7 | 73.68% |
| pr214517 | 3 | 3 | 3 | 100.00% | 3 | 2 | 66.67% |
| pr214541 | 5 | 5 | 5 | 100.00% | 15 | 5 | 50.00% |
| pr215122 | 7 | 7 | 7 | 100.00% | 11 | 7 | 77.78% |
| pr215130 | 0 | 0 | 0 | 100.00% | 0 | 0 | 100.00% |
| pr216046 | 9 | 9 | 9 | 100.00% | 15 | 9 | 75.00% |
| pr216436 | 4 | 4 | 4 | 100.00% | 6 | 4 | 80.00% |
| pr216470 | 7 | 7 | 7 | 100.00% | 19 | 7 | 53.85% |

### Totals

| Tool | PRs | \|G\| | \|P\| | TP | FP | FN | Precision | Recall | F1 | PRs with F1 100% |
|---|---|---|---|---|---|---|---|---|---|---|
| MetaphIR | all | 141 | 140 | 140 | 0 | 1 | 100.00% | 99.29% | 99.64% | 19 |
| MetaphIR | without pr204089 | 138 | 137 | 137 | 0 | 1 | 100.00% | 99.28% | 99.64% | 18 |
| daggrep | all | 141 | 807 | 138 | 669 | 3 | 17.10% | 97.87% | 29.11% | 2 |
| daggrep | without pr204089 | 138 | 801 | 135 | 666 | 3 | 16.85% | 97.83% | 28.75% | 2 |

This report scores only the test suite functions. The index and query-time measurements (RQ3) are one run over the whole corpus and cannot be split by source; see `REPORT.md`.

