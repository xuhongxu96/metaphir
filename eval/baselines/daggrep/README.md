# Daggrep

[`dtcxzyw/llvm-opt-benchmark/daggrep.cpp`](https://github.com/dtcxzyw/llvm-opt-benchmark/blob/main/daggrep.cpp) (`680a568`)


## Building

daggrep builds against MetaphIR's LLVM (`scripts/prepare_llvm.sh`):

```sh
cmake -G Ninja -S eval/baselines/daggrep -B eval/baselines/daggrep/build \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_DIR=$PWD/llvm-project/build/install/lib/cmake/llvm
cmake --build eval/baselines/daggrep/build
```

## Running

```sh
uv run eval/scripts/run_baseline.py daggrep --corpus eval/corpus-o2-final \
  --results eval/results/o2-final -j 80 --repeat 3
uv run eval/scripts/run_eval.py metrics --corpus eval/corpus-o2-final \
  --results eval/results/o2-final --tool daggrep
```

`run_baseline.py`:

- writes `eval/results/<corpus>/<tool>/<pr>_P.functions`, in the format of
  `run_eval.py`;
- takes the union over a PR's pattern files (`<pr>.ll`, or one `<pr>_<alt>.ll`
  per alternative);
- records the wall-clock time of each pattern file.

`run_eval.py metrics --tool <tool>` scores the result against the ground
truth.

## daggrep

`daggrep/daggrep.cpp` is upstream's file with the changes in
`daggrep/daggrep.patch`.

The patch changes only the driver:

- **Input:** `daggrep [-j N] <pattern.ll> <files, dirs or @rsp>...`
  - It reads `.bc` as well as `.ll`.
  - It drops upstream's `/optimized/` filter and its blocklist.
- **No limits:**
  - It drops the stop after 20 matching modules.
  - It drops the stop after the first matching function in a module.
- **Output:** one sorted `<file>\t@<function>` line per function with a match.
- **Threads:** `-j N` worker threads pull modules from a shared index.
  The original implementation busy-waits on a lock-protected queue.

### Limitations

- It ignores types, so every pattern also matches at other bit widths.
- It does not compare icmp predicates.
- If matching a node succeeds only after swapping its operands, daggrep keeps
  that binding even if a later node fails; it does not backtrack and try the
  other operand order.
- A pattern intrinsic call without a `noundef` return attribute rejects every
  call that has one. This check is inverted relative to the flag checks, so
  every pattern call carries `noundef`, which then accepts calls with and
  without it.

### Expressiveness

For each of the MetaphIR patterns in `eval/patterns/`,
we write the closest daggrep pattern in `eval/baselines/daggrep/patterns/` and note what daggrep drops.
**Exact** means daggrep accepts the same instructions as the MetaphIR pattern.

| Pattern | daggrep | Dropped by daggrep |
|---|---|---|
| pr204089 | exact | - (2 files: nuw+zext, nsw+sext) |
| pr204927 | approx. | one-use of the logic op |
| pr204928 | approx. | one-use of the logic op |
| pr205383_sub | approx. | `?bm1 == ?bits - 1`; the predicate |
| pr205383_xor | approx. | `?bm1 == ?bits - 1`, `isPower2(?bits)`; the predicate |
| pr207462 | approx. | one-use; `notUndef` becomes `noundef` (not poison, which is stronger) |
| pr207462_mul | approx. | one-use; `?c0 != 0`, `(1 << ?k) - ?c0 != 0`; `noundef` as above |
| pr207564 | exact | - |
| pr209322 | approx. | `knownNegative(?y)` |
| pr210499 | approx. | the `i1` result type (4 files: lshr/ashr × nuw/nsw) |
| pr212132_case1 | approx. | `knownPowerOfTwo(?shift)`; one-use; the predicate |
| pr212132_case2 | approx. | as case 1 |
| pr213313 | exact | - (2 files: and, or) |
| pr213709 | approx. | `sgt(?bits, 1)`; the predicate; one-use for `ne 1` (2 files: `?c` = 0, 1) |
| pr214376 | approx. | `?c` odd (any immediate) |
| pr214381 | approx. | `?d != 0`; the predicate and the ranges of `?c`, `?d` |
| pr214517 | approx. | one-use of the cttz |
| pr214541 | approx. | one-use; `noOverflow("umul", ?y, ?z)` |
| pr215122 | approx. | `lowBitMask` (any immediate); one-use |
| pr215130 | approx. | `?c + ?negc == 0`; one-use |
| pr216046 | approx. | `inSignedRange(?x, -1, 1)` |
| pr216436 | approx. | `lowBitMask` (any immediate); one-use |
| pr216470 | approx. | `lowBitMask`, `popcount(?mask) == ?shift`, `noOverflow`; one-use; the predicate (2 files: with and without the zext) |

### Comparison with MetaphIR

| MetaphIR | daggrep |
|---|---|
| a metavariable | a function argument |
| a constant class or `:constantInt` | a `%cst...` argument (any immediate constant) |
| `notUndef` / `isGuaranteedNotToBeUndef` | `noundef` on the argument |
| a flag in the pattern | the same flag |
| a flag variable (`nuw:?nuw`) | one file per alternative, or dropped |
| a composite (`zextOrSext`, `bitwiseLogic`, `andOr`, `shr`, `selectEqZero`, `:o`) | one file per alternative |
| `neg` | `sub 0, x` |
| the `i1` flag of ctlz/cttz | `i1 false`, which daggrep matches against either value |
| an intrinsic call | `call noundef ...`; a call without `noundef` would reject every corpus call that has it |
| one-use, constraints, value tracking | dropped |
