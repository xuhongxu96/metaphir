#!/usr/bin/env python3
"""Checks that metaphir-match's faster modes change nothing.

Every pattern of every lit test under test/Matching is matched against the
test's IR files in each mode of a group; within a group, the outputs must be
identical. The indexed modes run on the files assembled to bitcode, which is
loaded lazily.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Groups of modes that must print the same, each mode's arguments first.
GROUPS = [
    [[], ["--no-prefilter"]],
    [
        ["--matches-only"],
        ["--matches-only", "--no-prefilter"],
        ["--matches-only", "-j", "4"],
    ],
]
# The same, on bitcode; INDEX stands for the index of the files.
INDEX = "<index>"
BITCODE_GROUPS = [
    [
        ["--matches-only"],
        ["--matches-only", "--index", INDEX],
        ["--matches-only", "--index", INDEX, "-j", "4"],
        ["--matches-only", "--index", INDEX, "--no-prefilter"],
    ],
]


def run(command: list[str]) -> tuple[int, str, str]:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    return result.returncode, result.stdout, result.stderr


def check_test(test: Path, args: argparse.Namespace, work: Path) -> list[str]:
    """Compares the modes on one lit test; returns the differences found."""
    directory = work / test.stem
    subprocess.run(
        [args.split_file, "--no-leading-lines", str(test), str(directory)],
        check=True,
        capture_output=True,
    )
    inputs = work / f"{test.stem}.inputs"
    for ir in sorted(directory.rglob("*.ll")):
        moved = inputs / ir.relative_to(directory)
        moved.parent.mkdir(parents=True, exist_ok=True)
        ir.rename(moved)
    if not inputs.exists():
        return []

    # The files assembled, or copied when they do not assemble.
    bitcode = work / f"{test.stem}.bitcode"
    for ir in sorted(inputs.rglob("*.ll")):
        target = bitcode / ir.relative_to(inputs)
        target.parent.mkdir(parents=True, exist_ok=True)
        assembled = subprocess.run(
            [args.llvm_as, str(ir), "-o", str(target.with_suffix(".bc"))],
            capture_output=True,
            check=False,
        )
        if assembled.returncode != 0:
            shutil.copy(ir, target)
    index = work / f"{test.stem}.mpidx"
    subprocess.run(
        [args.index, "build", str(bitcode), "-o", str(index)],
        check=True,
        capture_output=True,
    )

    failures = []
    for pattern in sorted(directory.rglob("*.mpir")):
        for groups, files in ((GROUPS, inputs), (BITCODE_GROUPS, bitcode)):
            for group in groups:
                modes = [
                    [str(index) if arg == INDEX else arg for arg in mode]
                    for mode in group
                ]
                first = run([args.match, *modes[0], str(pattern), str(files)])
                for mode, shown in zip(modes[1:], group[1:], strict=True):
                    other = run([args.match, *mode, str(pattern), str(files)])
                    if other != first:
                        failures.append(
                            f"{test.name}: {pattern.name}: {' '.join(shown)}"
                            f" differs from {' '.join(group[0]) or 'the default'}"
                        )
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--match", required=True, help="metaphir-match")
    parser.add_argument("--index", required=True, help="metaphir-index")
    parser.add_argument("--split-file", required=True, help="split-file")
    parser.add_argument("--llvm-as", required=True, help="llvm-as")
    parser.add_argument("tests", type=Path, help="directory of lit tests")
    args = parser.parse_args()

    tests = sorted(args.tests.glob("MIRMatcher-*.ll"))
    if not tests:
        print(f"no tests in {args.tests}", file=sys.stderr)
        return 1
    failures = []
    with tempfile.TemporaryDirectory() as work:
        for test in tests:
            failures += check_test(test, args, Path(work))
    for failure in failures:
        print(failure, file=sys.stderr)
    print(f"{len(tests)} tests, {len(failures)} differences")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
