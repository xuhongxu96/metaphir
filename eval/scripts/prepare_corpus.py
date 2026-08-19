#!/usr/bin/env python3
"""Collect *.bc from the opt benchmark, preprocess, and save to the corpus dir.

Each `original/` module is O0 (alloca/load/store). We optimize each module with
the patched `opt` (the 20 selected InstCombine folds from eval/PRs.md are
disabled), so the resulting corpus is realistic O2-optimized IR in which those
folds never fired. The evaluation harness then matches patterns against these
modules.

Reads a manifest of `<proj>/<file>` entries (see eval/corpus_manifest.txt),
copies each `<proj>/original/<file>.bc` from the benchmark, preprocesses it,
and writes the result to the corpus directory. Existing corpus files are
overwritten.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OPT = REPO / "llvm-project" / "build-release" / "bin" / "opt"
BENCH_ROOT = Path("/ssd/h445xu/llvm-opt-benchmark-nightly/local")
PASSES = "default<O2>"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--manifest", type=Path,
                    default=REPO / "eval" / "corpus_manifest.txt")
    ap.add_argument("--corpus", type=Path, default=REPO / "eval" / "corpus")
    ap.add_argument("--bench-root", type=Path, default=BENCH_ROOT)
    ap.add_argument("--opt", type=Path, default=OPT)
    ap.add_argument("--passes", default=PASSES)
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 1,
                    help="number of opt processes to run concurrently")
    args = ap.parse_args()

    if args.jobs < 1:
        ap.error("--jobs must be at least 1")

    if not args.manifest.is_file():
        sys.exit(f"manifest not found: {args.manifest}")
    if not args.opt.is_file():
        sys.exit(f"opt not found: {args.opt} (is the Release LLVM built?)")
    if not args.bench_root.is_dir():
        sys.exit(f"benchmark root not found: {args.bench_root}")

    args.corpus.mkdir(parents=True, exist_ok=True)
    entries = [
        line.strip()
        for line in args.manifest.read_text().splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    print(f"== preparing {len(entries)} modules from {args.bench_root} ==")

    def preprocess(item: tuple[int, str], tmp_path: Path) -> tuple[bool, str]:
        index, rel = item
        proj, _, fname = rel.partition("/")
        src = args.bench_root / proj / "original" / fname
        if not src.is_file():
            return False, f"  MISSING {src}"

        dst = args.corpus / f"{proj}__{fname}"
        tmp_bc = tmp_path / f"{index}.bc"
        proc = subprocess.run(
            [str(args.opt), f"-passes={args.passes}", str(src),
             "-o", str(tmp_bc)],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            return False, (f"  PREPROCESS FAILED {rel}: "
                           f"{proc.stderr.splitlines()[:1]}")
        shutil.move(str(tmp_bc), dst)
        return True, ""

    with tempfile.TemporaryDirectory(prefix="metaphir-prep-") as tmp:
        tmp_path = Path(tmp)
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            results = pool.map(
                lambda item: preprocess(item, tmp_path), enumerate(entries))
            ok = fail = 0
            for success, message in results:
                if success:
                    ok += 1
                else:
                    print(message, file=sys.stderr)
                    fail += 1

    print(f"  preprocessed {ok} modules, {fail} failed")
    print(f"  corpus: {args.corpus}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
