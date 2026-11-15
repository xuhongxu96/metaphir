#!/usr/bin/env python3
"""Line coverage of MetaphIR's sources by the lit tests.

Runs the lit tests under test/ with the tools of a build configured with
-DMETAPHIR_USE_COVERAGE=ON, then reports, for each source file under the
given directories, the lines gcov counts as executable and how many of them
the tests ran:

    cmake -G Ninja -S . -B build-cov -DMETAPHIR_USE_COVERAGE=ON
    cmake --build build-cov
    scripts/coverage.py --build build-cov metaphir/Transforms

--missing lists the lines no test ran. --no-run reports on the counts of the
last run, and --tests runs only the given lit tests (paths under test/).
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DIRS = ["metaphir/Parser", "metaphir/Dialect", "metaphir/Transforms",
                "metaphir/Exec", "metaphir/Matching", "metaphir/Index", "metaphir/Web"]
TOOLS = ["metaphir-lex", "metaphir-parse", "metaphir-match", "metaphir-index",
         "metaphir-opt"]


def run_ctest(build: Path) -> int:
    """The unit tests and the lit suite of build, as ctest runs them."""
    return subprocess.run(
        ["ctest", "--test-dir", str(build), "-j", "8", "--output-on-failure"],
        check=False,
    ).returncode


def run_lit(build: Path, tests: list[str], utils: Path) -> int:
    for gcda in build.rglob("*.gcda"):
        gcda.unlink()
    command = [str(utils / "llvm-lit"), "-q", "--skip-test-time-recording"]
    for tool in TOOLS:
        command += ["-D", f"{tool.replace('-', '_')}={build / 'tools' / tool}"]
    paths = [str(build / "test" / t) for t in tests] or [str(build / "test")]
    return subprocess.run(command + paths, check=False).returncode


def coverage(source: Path, objects: Path) -> tuple[int, list[int]] | None:
    """The executable lines of source, and those not run; None if not built."""
    gcda = objects / (source.name + ".gcda")
    gcno = objects / (source.name + ".gcno")
    if not gcno.exists():
        return None
    # Built but never run: gcov reads the notes alone.
    data = gcda if gcda.exists() else gcno
    result = subprocess.run(["gcov", "-t", data.name], capture_output=True,
                            text=True, cwd=objects, check=False)
    excluded = unreachable_lines(source.read_text().splitlines())
    executable = 0
    missing: list[int] = []
    seen: set[int] = set()
    current = None
    for line in result.stdout.splitlines():
        parts = line.split(":", 2)
        if len(parts) < 3:
            continue
        count, number, text = parts[0].strip(), parts[1].strip(), parts[2]
        if number == "0":
            if text.startswith("Source:"):
                current = Path(text[len("Source:"):])
            continue
        if current is None or current.resolve() != source.resolve():
            continue
        # A template's line comes again for each instantiation, after the
        # count of all of them.
        if count == "-" or int(number) in seen or int(number) in excluded:
            continue
        seen.add(int(number))
        executable += 1
        if count.startswith("#####") or count.startswith("====="):
            missing.append(int(number))
    return executable, missing


LABEL_RE = re.compile(r"^\s*(default|case\b.*):\s*$")


def unreachable_lines(text: list[str]) -> set[int]:
    """The lines no input reaches by design: llvm_unreachable calls with the
    case labels that lead only to them, and what LCOV_EXCL_START/STOP (or
    LCOV_EXCL_LINE) mark: safeguards against bugs elsewhere."""
    excluded: set[int] = set()
    off = False
    for index, line in enumerate(text):
        number = index + 1
        if "LCOV_EXCL_START" in line:
            off = True
        if off or "LCOV_EXCL_LINE" in line:
            excluded.add(number)
        if "LCOV_EXCL_STOP" in line:
            off = False
        if "llvm_unreachable(" in line:
            excluded.add(number)
            # A call wrapped over lines, and the labels before it.
            end = index
            while ");" not in text[end] and end + 1 < len(text):
                end += 1
                excluded.add(end + 1)
            before = index - 1
            while before >= 0 and LABEL_RE.match(text[before]):
                excluded.add(before + 1)
                before -= 1
    return excluded


def object_dir(build: Path, source: Path) -> Path | None:
    relative = source.relative_to(REPO)
    for gcno in build.rglob(source.name + ".gcno"):
        # <build>/<relative dir>/CMakeFiles/<target>.dir/<name>.gcno
        if gcno.parent.parent.parent == build / relative.parent:
            return gcno.parent
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("dirs", nargs="*", default=DEFAULT_DIRS,
                        help="source directories or files to report on")
    parser.add_argument("--build", type=Path, default=REPO / "build-cov")
    parser.add_argument("--utils", type=Path,
                        default=REPO / "llvm-project" / "build" / "bin",
                        help="where llvm-lit and FileCheck are")
    parser.add_argument("--tests", nargs="*", default=[],
                        help="lit tests to run, relative to test/")
    parser.add_argument("--no-run", action="store_true")
    parser.add_argument("--ctest", action="store_true",
                        help="run every ctest test (the unit tests too), "
                        "instead of the lit tests alone")
    parser.add_argument("--missing", action="store_true",
                        help="list the lines no test ran")
    args = parser.parse_args()
    build = args.build.resolve()

    if args.ctest and not args.no_run:
        for gcda in build.rglob("*.gcda"):
            gcda.unlink()
        if run_ctest(build) != 0:
            print("coverage: some tests failed", file=sys.stderr)
    elif not args.no_run and run_lit(build, args.tests, args.utils) != 0:
        print("coverage: some lit tests failed", file=sys.stderr)

    sources: list[Path] = []
    for entry in args.dirs:
        path = (REPO / entry).resolve()
        sources += [path] if path.is_file() else sorted(path.rglob("*.cpp"))
    total = covered = 0
    for source in sources:
        objects = object_dir(build, source)
        result = coverage(source, objects) if objects else None
        name = source.relative_to(REPO)
        if result is None:
            print(f"{'':>7}  {name} (not built)")
            continue
        executable, missing = result
        total += executable
        covered += executable - len(missing)
        percent = 100.0 * (executable - len(missing)) / executable if executable else 100.0
        print(f"{percent:6.1f}%  {name} ({executable - len(missing)}/{executable})")
        if args.missing and missing:
            text = source.read_text().splitlines()
            for number in missing:
                print(f"         {number:5}: {text[number - 1].strip()}")
    if total:
        print(f"{100.0 * covered / total:6.1f}%  total ({covered}/{total})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
