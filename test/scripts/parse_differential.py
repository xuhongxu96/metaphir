#!/usr/bin/env python3
"""Checks that metaphir-parse --engine=mlir prints what the classic engine
prints -- the pattern, its diagnostics and its exit status -- for every
pattern under the given paths: .mpir files, and the parts of split-file
tests (.ll)."""

import argparse
import pathlib
import subprocess
import sys
import tempfile


def inputs(paths, split_file, scratch):
    for root in paths:
        root = pathlib.Path(root)
        files = [root] if root.is_file() else sorted(root.rglob("*"))
        for f in files:
            if f.suffix == ".mpir":
                yield f
            elif f.suffix == ".ll" and ";--- " in f.read_text(errors="replace"):
                out = pathlib.Path(scratch) / f.relative_to(f.anchor)
                out.mkdir(parents=True, exist_ok=True)
                subprocess.run([split_file, str(f), str(out)], check=True,
                               capture_output=True)
                yield from sorted(p for p in out.iterdir() if p.is_file())
            elif f.suffix == ".ll":
                yield f


def run(parse, engine, path):
    p = subprocess.run([parse, f"--engine={engine}", str(path)],
                       capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parse", required=True)
    ap.add_argument("--split-file", required=True)
    ap.add_argument("paths", nargs="+")
    args = ap.parse_args()
    failures = 0
    count = 0
    with tempfile.TemporaryDirectory() as scratch:
        for path in inputs(args.paths, args.split_file, scratch):
            count += 1
            classic = run(args.parse, "classic", path)
            mlir = run(args.parse, "mlir", path)
            if classic != mlir:
                failures += 1
                print(f"MISMATCH {path}")
                for name, a, b in zip(("status", "stdout", "stderr"),
                                      classic, mlir):
                    if a != b:
                        print(f"  {name}:\n    classic: {a!r}\n    mlir:    {b!r}")
    print(f"{count} patterns, {failures} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
