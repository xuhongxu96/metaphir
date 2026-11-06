#!/usr/bin/env python3
"""Check that the folds in eval/fold-plugin are copied from InstCombine.

Each ``// BEGIN <prs> <file>`` ... ``// END`` block of MetaphIRFolds.cpp must
appear in ``<file>``: every line, ignoring indentation, in the same order. Lines
marked ``// differs`` are left out; they replace the visitor around a fold.

    eval/scripts/check_fold_plugin.py [--llvm llvm-project]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PLUGIN = REPO / "eval/fold-plugin/MetaphIRFolds.cpp"
BEGIN = re.compile(r"\s*// BEGIN (\S+) (\S+)$")
END = re.compile(r"\s*// END$")


def blocks(text: str) -> list[tuple[str, str, list[str]]]:
    """The blocks of the plugin: (PRs, source file, lines to find there)."""
    found = []
    current = None
    for line in text.splitlines():
        if m := BEGIN.match(line):
            current = (m[1], m[2], [])
        elif END.match(line) and current:
            found.append(current)
            current = None
        elif current and line.strip() and "// differs" not in line:
            current[2].append(line.strip())
    return found


def first_missing(lines: list[str], source: list[str]) -> str | None:
    """The first of ``lines`` not found in ``source`` after the ones before it."""
    at = 0
    for line in lines:
        try:
            at = source.index(line, at) + 1
        except ValueError:
            return line
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--llvm", type=Path, default=REPO / "llvm-project")
    args = ap.parse_args()
    bad = 0
    found = blocks(PLUGIN.read_text())
    for prs, file, lines in found:
        source = [s.strip() for s in (args.llvm / file).read_text().splitlines()]
        if missing := first_missing(lines, source):
            print(f"{prs} {file}: not found, or out of order: {missing}")
            bad += 1
    print(f"{len(found)} blocks, {bad} differ")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
