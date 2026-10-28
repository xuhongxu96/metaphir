"""The InstCombine pull requests used by the MetaphIR evaluation.

Each entry names the MetaphIR pattern file(s) that model the PR's fold. Pattern
paths are relative to the repository root. The upstream test suite is copied
into the corpora as a whole; see ``prepare_corpus.py``.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PR:
    patterns: tuple[str, ...]


def _pr(patterns: list[str]) -> PR:
    return PR(tuple(f"eval/patterns/{p}" for p in patterns))


PRS: dict[str, PR] = {
    "pr216436": _pr(["pr216436.mpir"]),
    "pr215122": _pr(["pr215122.mpir"]),
    "pr215130": _pr(["pr215130.mpir"]),
    "pr214541": _pr(["pr214541.mpir"]),
    "pr214517": _pr(["pr214517.mpir"]),
    "pr214381": _pr(["pr214381.mpir"]),
    "pr214376": _pr(["pr214376.mpir"]),
    "pr213709": _pr(["pr213709.mpir"]),
    "pr213313": _pr(["pr213313.mpir"]),
    "pr212132": _pr(["pr212132_case1.mpir", "pr212132_case2.mpir"]),
    "pr210499": _pr(["pr210499.mpir"]),
    "pr209322": _pr(["pr209322.mpir"]),
    "pr207564": _pr(["pr207564.mpir"]),
    "pr207462": _pr(["pr207462.mpir", "pr207462_mul.mpir"]),
    "pr205383": _pr(["pr205383_sub.mpir", "pr205383_xor.mpir"]),
    "pr204928": _pr(["pr204928.mpir"]),
    "pr204927": _pr(["pr204927.mpir"]),
    "pr216470": _pr(["pr216470.mpir"]),
    "pr216046": _pr(["pr216046.mpir"]),
    "pr204089": _pr(["pr204089.mpir"]),
}
