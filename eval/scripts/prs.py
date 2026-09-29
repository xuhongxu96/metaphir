"""The InstCombine pull requests used by the MetaphIR evaluation.

Each entry names the MetaphIR pattern file(s) that model the PR's fold and the
upstream regression test file(s) that exercise it. Pattern paths are relative
to the repository root; test paths are relative to
``llvm-project/llvm/test/Transforms``.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PR:
    patterns: tuple[str, ...]
    tests: tuple[str, ...]


def _pr(patterns: list[str], tests: list[str]) -> PR:
    return PR(tuple(f"eval/patterns/{p}" for p in patterns), tuple(tests))


PRS: dict[str, PR] = {
    "pr216436": _pr(["pr216436.mpir"], ["InstCombine/add-mask-neg.ll"]),
    "pr215122": _pr(["pr215122.mpir"], ["InstCombine/add-mask-neg.ll"]),
    "pr215130": _pr(["pr215130.mpir"], ["InstCombine/saturating-add-sub.ll"]),
    "pr214541": _pr(["pr214541.mpir"], ["InstCombine/div.ll"]),
    "pr214517": _pr(["pr214517.mpir"], ["InstCombine/shift.ll"]),
    "pr214381": _pr(["pr214381.mpir"], ["InstCombine/icmp-floor-align.ll"]),
    "pr214376": _pr(["pr214376.mpir"], ["InstCombine/cttz.ll"]),
    "pr213709": _pr(["pr213709.mpir"], ["InstCombine/icmp-lowbit.ll"]),
    "pr213313": _pr(
        ["pr213313.mpir"],
        ["InstCombine/fold-and-zext-sext.ll", "InstCombine/fold-or-zext-sext.ll"],
    ),
    "pr212132": _pr(
        ["pr212132_case1.mpir", "pr212132_case2.mpir"],
        ["InstCombine/select-and-or-powerof2.ll"],
    ),
    "pr210499": _pr(["pr210499.mpir"], ["InstCombine/trunc.ll"]),
    "pr209322": _pr(["pr209322.mpir"], ["InstCombine/udiv-isknownnegative.ll"]),
    "pr207564": _pr(["pr207564.mpir"], ["InstCombine/zext-sub-trunc.ll"]),
    "pr207462": _pr(["pr207462.mpir", "pr207462_mul.mpir"], ["InstCombine/add4.ll"]),
    "pr205383": _pr(
        ["pr205383_sub.mpir", "pr205383_xor.mpir"],
        ["InstCombine/select-ctlz-to-cttz.ll"],
    ),
    "pr204928": _pr(["pr204928.mpir"], ["InstCombine/set.ll"]),
    "pr204927": _pr(["pr204927.mpir"], ["InstCombine/zext.ll"]),
    "pr216470": _pr(["pr216470.mpir"], ["InstCombine/add.ll"]),
    "pr216046": _pr(["pr216046.mpir"], ["InstCombine/scmp.ll"]),
    "pr204089": _pr(["pr204089.mpir"], ["InstSimplify/cast.ll"]),
}
