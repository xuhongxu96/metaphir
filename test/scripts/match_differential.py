#!/usr/bin/env python3
"""Checks that metaphir-match --engine=mlir finds what the classic engine
finds: for every lit test under the given paths, each RUN line that runs
metaphir-match (and needs no index) is run with both engines, and their
output, diagnostics and exit status compared.

Matches are compared as sets: the engines may find them in other orders.
With --report, the differences are printed rather than failing on them."""

import argparse
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile


def run_lines(test):
    lines, current = [], ""
    for line in test.read_text(errors="replace").splitlines():
        m = re.match(r"\s*;\s*RUN:\s?(.*)$", line)
        if not m:
            continue
        part = m.group(1)
        if part.endswith("\\"):
            current += part[:-1]
            continue
        lines.append(current + part)
        current = ""
    return lines


def normalize(output):
    """Sorts the lines of each function's report, which may be in any
    order."""
    blocks, current = [], []
    for line in output.splitlines():
        if line.startswith("target ") and current:
            blocks.append(current)
            current = []
        current.append(line)
    if current:
        blocks.append(current)
    return [sorted(b) for b in blocks] if any(
        l.startswith("target ") for l in output.splitlines()) else sorted(
            output.splitlines())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--match", required=True)
    ap.add_argument("--split-file", required=True)
    ap.add_argument("--index", help="metaphir-index, to run the tests that "
                    "build an index")
    ap.add_argument("--report", action="store_true")
    ap.add_argument("--allow-explain-reasons", action="store_true",
                    help="ignore the reasons --explain gives for no "
                    "structural match, which only the classic engine has")
    ap.add_argument("paths", nargs="+")
    args = ap.parse_args()
    tests = []
    for root in args.paths:
        root = pathlib.Path(root)
        tests += [root] if root.is_file() else sorted(root.rglob("*.ll"))
    runs = mismatches = 0
    with tempfile.TemporaryDirectory() as scratch:
        for index, test in enumerate(tests):
            tmp = pathlib.Path(scratch) / f"t{index}"
            for line in run_lines(test):
                line = line.replace("%s", str(test)).replace("%t", str(tmp))
                if "metaphir-match" not in line and (
                        "split-file" in line or "rm -rf" in line or
                        (args.index and "%metaphir-index" in line)):
                    # Set-up, which both engines share.
                    cmd = line.replace("split-file", args.split_file)
                    if args.index:
                        cmd = cmd.replace("%metaphir-index",
                                          shlex.quote(args.index))
                    cmd = re.split(r"\|\s*(FileCheck|count|not FileCheck)",
                                   cmd)[0]
                    subprocess.run(cmd, shell=True, capture_output=True)
                    continue
                if "%metaphir-match" not in line or "%metaphir-index" in line \
                        or "--packs" in line or (
                            "--index" in line and not args.index):
                    continue
                # The command, without what checks its output.
                cmd = re.split(r"\|\s*(FileCheck|count|not FileCheck)", line)[0]
                cmd = re.sub(r"2>&1\s*$", "", cmd.strip())
                cmd = re.sub(r"^not\s+", "", cmd)
                runs += 1
                results = []
                for engine in ("classic", "mlir"):
                    c = cmd.replace("%metaphir-match",
                                    f"{shlex.quote(args.match)} --engine={engine}")
                    p = subprocess.run(c, shell=True, capture_output=True,
                                       text=True)
                    out = p.stdout
                    if args.allow_explain_reasons:
                        out = "\n".join(
                            l for l in out.splitlines()
                            if not l.startswith("  no structural match: ")
                            or " would be both " in l)
                    results.append((p.returncode, normalize(out), p.stderr))
                if results[0] != results[1]:
                    mismatches += 1
                    print(f"MISMATCH {test.name}: {cmd}")
                    for name, a, b in zip(("status", "stdout", "stderr"),
                                          *results):
                        if a != b:
                            print(f"  {name}:\n    classic: {a!r}\n"
                                  f"    mlir:    {b!r}"[:4000])
    print(f"{runs} runs, {mismatches} mismatches")
    return 1 if mismatches and not args.report else 0


if __name__ == "__main__":
    sys.exit(main())
