#!/usr/bin/env python3
"""Collect the direct ground truth: each fold alone, run by eval/fold-plugin.

The ground truth of a PR is the functions of the corpus its fold fires in when
no other fold runs (see eval/fold-plugin/MetaphIRFolds.cpp). It is saved in
``<results>/gt/<pr>_G.functions``, with the firings per PR in ``firings.tsv``,
the modules ``opt`` failed on in ``failures.txt`` and the time in ``timing.txt``.

    eval/scripts/run_folds.py --corpus eval/corpus-o2-final \\
        --results eval/results/o2-final -j 80
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from run_eval import ANCHOR_RE, GT_DIR, OPT, collect_corpus, save_functions

REPO = Path(__file__).resolve().parents[2]
PLUGIN = REPO / "eval/fold-plugin/build/MetaphIRFolds.so"
SOURCE = REPO / "eval/fold-plugin/MetaphIRFolds.cpp"
FIRINGS_RE = re.compile(r"^FIRINGS \S+ (\S+) (\d+)$")


def plugin_prs() -> list[str]:
    """The PRs whose folds the plugin holds."""
    return sorted(set(re.findall(r'foldEnabled\("(pr\d+)"\)', SOURCE.read_text())))


def run_module(bc: Path) -> tuple[Path, str, int, float]:
    start = time.monotonic()
    proc = subprocess.run(
        [str(OPT), f"-load-pass-plugin={PLUGIN}", "-passes=metaphir-folds",
         "-disable-output", str(bc)],
        capture_output=True, text=True, check=False,
    )
    return bc, proc.stderr, proc.returncode, time.monotonic() - start


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--corpus", type=Path, required=True)
    ap.add_argument("--results", type=Path, required=True)
    ap.add_argument("-j", "--jobs", type=int, default=os.cpu_count())
    args = ap.parse_args()
    prs = plugin_prs()
    files = collect_corpus(args.corpus)
    funcs: dict[str, set] = {pr: set() for pr in prs}
    firings: Counter[str] = Counter()
    failed = []
    total = 0.0
    with ThreadPoolExecutor(args.jobs) as pool:
        for bc, stderr, code, seconds in pool.map(run_module, files):
            total += seconds
            if code:
                failed.append(f"{bc.name}\trc={code}\t{stderr.splitlines()[-1:]}")
            for line in stderr.splitlines():
                if m := ANCHOR_RE.match(line):
                    funcs[m[2]].add((bc.name, m[1]))
                elif m := FIRINGS_RE.match(line):
                    firings[m[1]] += int(m[2])
    out = args.results / GT_DIR
    out.mkdir(parents=True, exist_ok=True)
    for pr in prs:
        save_functions(out / f"{pr}_G.functions", funcs[pr])
        print(f"  {pr}: {len(funcs[pr])} functions, {firings[pr]} firings")
    (out / "firings.tsv").write_text("".join(f"{pr}\t{firings[pr]}\n" for pr in prs))
    (out / "failures.txt").write_text("".join(f + "\n" for f in failed))
    (out / "timing.txt").write_text(
        f"modules={len(files)}\nprs={len(prs)}\ngt_seconds={total:.3f}\n"
    )
    print(f"  {total:.2f} CPU-seconds, summed over the modules; {len(failed)} modules failed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
