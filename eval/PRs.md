# InstCombine Evaluation — 20 merged PRs

All 20 PRs are **merged** InstCombine folds with a clear `src -> tgt` transform
and an existing test under `llvm-project/test/Transforms/InstCombine/`.

| #   | PR     | Title (src -> tgt)                                                |
| --- | ------ | ----------------------------------------------------------------- |
| 1   | 216436 | `((x-1) \| (2^k-1)) + 1 -> (x + (2^k-1)) & -(2^k)` (power-of-2 C) |
| 2   | 215122 | `X + ((-X) & (C-1)) -> (X + C-1) & -C` (power-of-2 C)             |
| 3   | 215130 | `uadd.sat(X,C) - C -> umin(X, ~C)` (nonzero C)                    |
| 4   | 214541 | `(X udiv Y) udiv Z -> X udiv (Y*Z)` (Y*Z no-overflow)             |
| 5   | 214517 | `C << cttz(X,true) -> (-X & X) * C` (cttz single-use)             |
| 6   | 214381 | `(X - (X urem D)) u>= C -> X u>= D` (0<=C<D)                      |
| 7   | 214376 | `cttz(mul X, OddC) -> cttz(X)`                                    |
| 8   | 213709 | `(x & -x) == 0 -> (x & -x) ...` comparison folds with 0/1         |
| 9   | 213313 | `zext(X) \| sext(X) -> sext(X)`; `zext(X) & sext(X) -> zext(X)`   |
| 10  | 212132 | `select((A&S)==0 \|\| (B&S)==0, 0, S) -> S & A & B`               |
| 11  | 210499 | `trunc(shr exact X, Y) to i1 -> icmp ne X, 0`                     |
| 12  | 207564 | `zext(sub(0, trunc(X))) -> and(sub(0, X), mask)`                  |
| 13  | 207462 | commuted `add` of `udiv`/`urem` by 2                              |
| 14  | 205383 | `(bw-1) - ctlz(x & -x) -> cttz`                                   |
| 15  | 204928 | `sext(and/or/xor(trunc nsw x), y) -> and/or/xor(sext(y), x)`      |
| 16  | 204927 | `zext(and/or/xor(trunc nuw x), y) -> and/or/xor(zext(y), x)`      |
| 17  | 216470 | zext in ceiling division fold                                     |
| 18  | 216046 | `scmp(X, 0) -> sext_or_trunc(X)` (X in [-1,1])                    |
| 19  | 209322 | udiv-by-negative-constant fold, generalized to non-constant       |
| 20  | 204089 | value-preserving zext/sext of trunc                               |
