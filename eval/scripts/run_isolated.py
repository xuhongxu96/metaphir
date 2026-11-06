#!/usr/bin/env python3
"""Evaluate against each fold alone, run by the plugin in eval/fold-plugin.

The ground truth of a PR is the functions of the corpus its fold fires in when
no other fold runs (see eval/fold-plugin/MetaphIRFolds.cpp). It is saved in
``<out>/gt``, with the firings per PR in ``<out>/firings.tsv``, and compared in
``<out>/REPORT-isolated.md`` with the InstCombine ground truth and with the
predictions saved in ``--results``, which are not re-run.

    eval/scripts/run_isolated.py [--corpus eval/corpus-o2-final] \\
        [--results eval/results/o2-final] [-o eval/results/o2-final-isolated]
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

from report import provenance
from run_eval import ANCHOR_RE, OPT, collect_corpus, load_functions, save_functions, scores

REPO = Path(__file__).resolve().parents[2]
PLUGIN = REPO / "eval/fold-plugin/build/MetaphIRFolds.so"
SOURCE = REPO / "eval/fold-plugin/MetaphIRFolds.cpp"
FIRINGS_RE = re.compile(r"^FIRINGS \S+ (\S+) (\d+)$")
TOOLS = ["metaphir-index", "daggrep"]


def plugin_prs() -> list[str]:
    """The PRs whose folds the plugin holds."""
    return sorted(set(re.findall(r'foldEnabled\("(pr\d+)"\)', SOURCE.read_text())))


def run_module(bc: Path) -> tuple[Path, str, int]:
    proc = subprocess.run(
        [str(OPT), f"-load-pass-plugin={PLUGIN}", "-passes=metaphir-folds",
         "-disable-output", str(bc)],
        capture_output=True, text=True, check=False,
    )
    return bc, proc.stderr, proc.returncode


def collect(corpus: Path, out: Path, prs: list[str], jobs: int) -> None:
    """Runs the folds over the corpus."""
    funcs: dict[str, set] = {pr: set() for pr in prs}
    firings: Counter[str] = Counter()
    failed = []
    start = time.monotonic()
    with ThreadPoolExecutor(jobs) as pool:
        for bc, stderr, code in pool.map(run_module, collect_corpus(corpus)):
            if code:
                failed.append(f"{bc.name}\trc={code}\t{stderr.splitlines()[-1:]}")
            for line in stderr.splitlines():
                if m := ANCHOR_RE.match(line):
                    funcs[m[2]].add((bc.name, m[1]))
                elif m := FIRINGS_RE.match(line):
                    firings[m[1]] += int(m[2])
    seconds = time.monotonic() - start
    (out / "gt").mkdir(parents=True, exist_ok=True)
    for pr in prs:
        save_functions(out / "gt" / f"{pr}_G.functions", funcs[pr])
    (out / "firings.tsv").write_text("".join(f"{pr}\t{firings[pr]}\n" for pr in prs))
    (out / "failures.txt").write_text("".join(f + "\n" for f in failed))
    (out / "seconds.txt").write_text(f"{seconds:.0f}\n")


def macro(rows: list[dict], field: str) -> float:
    """The mean of ``field`` over the PRs it says something about."""
    key = "P" if field == "precision" else "G"
    used = [r[field] for r in rows if r[key]]
    return sum(used) / len(used) if used else 0.0


def report(out: Path, results: Path, corpus: Path, prs: list[str]) -> str:
    isolated = {pr: load_functions(out / "gt" / f"{pr}_G.functions") for pr in prs}
    firings = dict(
        line.split("\t") for line in (out / "firings.tsv").read_text().splitlines()
    )
    instcombine = {pr: load_functions(results / "gt" / f"{pr}_G.functions") for pr in prs}
    source = provenance(corpus)
    failed = (out / "failures.txt").read_text().splitlines()
    seconds = (out / "seconds.txt").read_text().strip()
    lines = ["# Evaluation against each fold alone", "",
             f"MetaphIR `{source['metaphir_commit']}`, LLVM `{source['llvm_commit']}`.", "",
             f"Over every module of `{corpus.name}`, the upstream test files included, "
             f"in {seconds} s. Modules `opt` failed on: {len(failed)}.", "",
             "## Ground truth", "",
              "| PR | Firings | Isolated | InstCombine | Both | Only isolated | Only InstCombine |",
              "|---|---|---|---|---|---|---|"]
    for pr in prs:
        a, b = isolated[pr], instcombine[pr]
        lines.append(f"| {pr} | {firings[pr]} | {len(a)} | {len(b)} | {len(a & b)} "
                     f"| {len(a - b)} | {len(b - a)} |")
    for tool in TOOLS:
        lines += ["", f"## {tool}", "",
                  "| PR | P | Isolated: P / R / F1 | InstCombine: P / R / F1 |",
                  "|---|---|---|---|"]
        rows: dict[str, list[dict]] = {"iso": [], "ic": []}
        tp = {"iso": Counter(), "ic": Counter()}
        for pr in prs:
            path = results / tool / f"{pr}_P.functions"
            if not path.is_file():
                lines.append(f"| {pr} | no pattern | | |")
                continue
            pred = load_functions(path)
            cells = []
            for name, gt in (("iso", isolated[pr]), ("ic", instcombine[pr])):
                s = scores(gt, pred)
                rows[name].append(s)
                tp[name].update({k: s[k] for k in ("TP", "FP", "FN")})
                cells.append(f"{s['precision']:.3f} / {s['recall']:.3f} / {s['f1']:.3f}")
            lines.append(f"| {pr} | {len(pred)} | {cells[0]} | {cells[1]} |")
        for name, label in (("iso", "Isolated"), ("ic", "InstCombine")):
            c = tp[name]
            micro_p = c["TP"] / ((c["TP"] + c["FP"]) or 1)
            micro_r = c["TP"] / ((c["TP"] + c["FN"]) or 1)
            lines += ["", f"{label}: macro precision {macro(rows[name], 'precision'):.3f}, "
                      f"macro recall {macro(rows[name], 'recall'):.3f}, "
                      f"micro precision {micro_p:.3f}, micro recall {micro_r:.3f}."]
    text = "\n".join(lines) + "\n"
    (out / "REPORT-isolated.md").write_text(text)
    return text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--corpus", type=Path, default=REPO / "eval/corpus-o2-final")
    ap.add_argument("--results", type=Path, default=REPO / "eval/results/o2-final")
    ap.add_argument("-o", "--output", type=Path, default=REPO / "eval/results/o2-final-isolated")
    ap.add_argument("-j", "--jobs", type=int, default=os.cpu_count())
    ap.add_argument("--report-only", action="store_true", help="only write the report")
    args = ap.parse_args()
    prs = plugin_prs()
    if not args.report_only:
        collect(args.corpus, args.output, prs, args.jobs)
    print(report(args.output, args.results, args.corpus, prs))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
