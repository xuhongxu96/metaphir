#!/usr/bin/env python3
"""Evaluate MetaphIR patterns against LLVM's InstCombine pass over a corpus.

The evaluation is split into independent, cacheable steps so that tweaking
patterns does not force re-running the (slower) ground-truth collection:

  gt        Run LLVM's instrumented InstCombine over the corpus and save the
            ground-truth anchor set to ``<pr>_G.anchors``. Runs for every PR by
            default; use ``--pr`` to select a subset.

  pattern   Run the MetaphIR pattern(s) over the corpus and save the prediction
            anchor set to ``<pr>_P.anchors``. Runs for every PR by default; use
            ``--pr`` to select a subset (or ``--patterns`` to override the
            patterns for a single PR).

  metrics   Load the saved anchor sets and compute precision/recall/F1 for
            every PR (use ``--pr`` to select a subset).

Ground truth (G): anchors (file, function, anchor-ssa-name) where LLVM's own
fold fires, captured by running an instrumented InstCombine with
``METAPHIR_EVAL_ANCHOR=1``. Prediction (P): anchors where the MetaphIR
pattern(s) match. Both run on the same corpus IR.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from collections.abc import Callable
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OPT = REPO / "llvm-project" / "build" / "bin" / "opt"
METAPHIR_MATCH = REPO / "build" / "tools" / "metaphir-match"

# PR -> MetaphIR pattern files (relative to the repo root).
PR_PATTERNS: dict[str, list[str]] = {
    "pr216436": ["eval/patterns/pr216436.mpir"],
    "pr215122": ["eval/patterns/pr215122.mpir"],
    "pr215130": ["eval/patterns/pr215130.mpir"],
    "pr214541": ["eval/patterns/pr214541.mpir"],
    "pr214517": ["eval/patterns/pr214517.mpir"],
    "pr214381": ["eval/patterns/pr214381.mpir"],
    "pr214376": ["eval/patterns/pr214376.mpir"],
    "pr213709": [
        "eval/patterns/pr213709_eq.mpir",
        "eval/patterns/pr213709_ne0.mpir",
        "eval/patterns/pr213709_ne1.mpir",
    ],
    "pr213313": ["eval/patterns/pr213313_and.mpir", "eval/patterns/pr213313_or.mpir"],
    "pr212132": [
        "eval/patterns/pr212132_c1.mpir",
        "eval/patterns/pr212132_c2.mpir",
        "eval/patterns/pr212132_c3.mpir",
        "eval/patterns/pr212132_c4.mpir",
    ],
    "pr210499": ["eval/patterns/pr210499.mpir"],
    "pr209322": ["eval/patterns/pr209322.mpir"],
    "pr207564": ["eval/patterns/pr207564.mpir"],
    "pr207462": [
        "eval/patterns/pr207462.mpir",
        "eval/patterns/pr207462_mul.mpir",
    ],
    "pr205383": ["eval/patterns/pr205383_sub.mpir", "eval/patterns/pr205383_xor.mpir"],
    "pr204928": ["eval/patterns/pr204928.mpir"],
    "pr204927": ["eval/patterns/pr204927.mpir"],
    "pr216470": [
        "eval/patterns/pr216470.mpir",
        "eval/patterns/pr216470_self.mpir",
    ],
    "pr216046": [
        "eval/patterns/pr216046.mpir",
        "eval/patterns/pr216046_range.mpir",
    ],
    "pr204089": ["eval/patterns/pr204089.mpir"],
}

ANCHOR_RE = re.compile(r"^ANCHOR (\S+) (\S+)(?: (\S+))?$")
TARGET_RE = re.compile(r"^target \d+: @(\S+)$")
BINDING_RE = re.compile(r"\?anch = (%[^,\s]+)")

Anchor = tuple[str, str, str]


# --------------------------------------------------------------------------- #
# Corpus
# --------------------------------------------------------------------------- #
def collect_corpus(corpus: Path) -> list[Path]:
    files = sorted(p for p in corpus.rglob("*") if p.suffix in (".bc", ".ll"))
    if not files:
        sys.exit(f"no .bc/.ll files found under {corpus}")
    return files


# --------------------------------------------------------------------------- #
# Tool runners
# --------------------------------------------------------------------------- #
def run_llvm_anchors(bc: Path, want_fold: str) -> set[Anchor]:
    """Collect ground-truth anchors from LLVM's own fold sites.

    Runs a single instcombine pass with ``METAPHIR_EVAL_ANCHOR=1`` so the
    instrumented folds report every firing as ``ANCHOR <func> <ssa> <foldID>``
    on stderr. Only anchors whose foldID matches ``want_fold`` are kept.
    """
    env = dict(os.environ)
    env["METAPHIR_EVAL_ANCHOR"] = "1"
    proc = subprocess.run(
        [str(OPT), "-passes=function(instcombine)", str(bc), "-o", "/dev/null"],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    anchors: set[Anchor] = set()
    for line in proc.stderr.splitlines():
        m = ANCHOR_RE.match(line)
        if m and (want_fold is None or m.group(3) == want_fold):
            anchors.add((bc.name, m.group(1), m.group(2)))
    return anchors


def run_pattern(pattern: Path, bc: Path) -> set[Anchor]:
    proc = subprocess.run(
        [str(METAPHIR_MATCH), str(pattern), str(bc)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        return set()

    anchors: set[Anchor] = set()
    func = None
    for line in proc.stdout.splitlines():
        m = TARGET_RE.match(line)
        if m:
            func = m.group(1)
            continue
        if func and "{" in line:
            bm = BINDING_RE.search(line)
            if bm:
                anchors.add((bc.name, func, bm.group(1).lstrip("%")))
    return anchors


def run_over_corpus(
    files: list[Path], run: Callable[[Path], set[Anchor]]
) -> tuple[set[Anchor], float]:
    """Apply ``run(bc) -> anchors`` to every corpus file, accumulating anchors and wall time."""
    anchors: set[Anchor] = set()
    elapsed = 0.0
    for bc in files:
        t0 = time.time()
        anchors |= run(bc)
        elapsed += time.time() - t0
    return anchors, elapsed


# --------------------------------------------------------------------------- #
# Anchor I/O and metrics
# --------------------------------------------------------------------------- #
def save_anchors(path: Path, anchors: set[Anchor]) -> None:
    path.write_text("".join("\t".join(a) + "\n" for a in sorted(anchors)))


def load_anchors(path: Path) -> set[Anchor]:
    anchors: set[Anchor] = set()
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        f, fn, a = line.split("\t", 2)
        anchors.add((f, fn, a))
    return anchors


def func_keys(anchors: set[Anchor]) -> set[tuple[str, str]]:
    return {(f, fn) for (f, fn, _) in anchors}


def print_metrics(G: set[Anchor], P: set[Anchor], label: str) -> None:
    tp = len(G & P)
    fp = len(P - G)
    fn = len(G - P)
    union = len(G | P)
    recall = tp / len(G) if G else 1.0
    precision = tp / len(P) if P else 1.0
    f1 = 2 * tp / (len(G) + len(P)) if (len(G) + len(P)) else 1.0
    diff_rate = 1 - (tp / union) if union else 1.0
    print(f"  [{label}] |G|={len(G)} |P|={len(P)} TP={tp} FP={fp} FN={fn}")
    print(
        f"  [{label}] recall={recall:.4f} precision={precision:.4f} "
        f"F1={f1:.4f} diff_rate={diff_rate:.4f}"
    )


# --------------------------------------------------------------------------- #
# Collection steps
# --------------------------------------------------------------------------- #
def collect_ground_truth(files: list[Path], pr: str, outdir: Path) -> None:
    print(f"== gt {pr}: {len(files)} modules ==")
    G, t_gt = run_over_corpus(files, lambda bc: run_llvm_anchors(bc, pr))

    if not G:
        print(
            f"  warning: no LLVM ground-truth anchors for {pr}; the fold may be "
            f"absent from this LLVM revision or never fires on the corpus"
        )

    g_path = outdir / f"{pr}_G.anchors"
    save_anchors(g_path, G)
    (outdir / f"{pr}_G_timing.txt").write_text(
        f"modules={len(files)}\ngt_seconds={t_gt:.3f}\nG_anchors={len(G)}\n"
    )
    print(f"  saved G anchors -> {g_path} ({len(G)})")
    print(f"  gt {t_gt:.2f}s")


def collect_patterns(
    files: list[Path], pr: str, patterns: list[Path], outdir: Path
) -> None:
    print(f"== pattern {pr}: {len(files)} modules, {len(patterns)} pattern(s) ==")
    run = lambda bc: set().union(*(run_pattern(p, bc) for p in patterns))
    P, t_pat = run_over_corpus(files, run)

    p_path = outdir / f"{pr}_P.anchors"
    save_anchors(p_path, P)
    (outdir / f"{pr}_P_timing.txt").write_text(
        f"modules={len(files)}\n"
        f"pattern_seconds={t_pat:.3f}\n"
        f"patterns={len(patterns)}\n"
        f"P_anchors={len(P)}\n"
    )
    print(f"  saved P anchors -> {p_path} ({len(P)})")
    print(f"  pattern {t_pat:.2f}s")


# --------------------------------------------------------------------------- #
# Commands
# --------------------------------------------------------------------------- #
def selected_prs(prs_arg: list[str] | None) -> list[str]:
    if prs_arg:
        unknown = [pr for pr in prs_arg if pr not in PR_PATTERNS]
        if unknown:
            sys.exit(f"unknown PR(s): {', '.join(unknown)}")
        return prs_arg
    return list(PR_PATTERNS)


def setup_outdir(args: argparse.Namespace) -> tuple[Path, list[Path]]:
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    return outdir, collect_corpus(args.corpus)


def cmd_gt(args: argparse.Namespace) -> int:
    outdir, files = setup_outdir(args)
    for pr in selected_prs(args.pr):
        collect_ground_truth(files, pr, outdir)
    return 0


def cmd_pattern(args: argparse.Namespace) -> int:
    outdir, files = setup_outdir(args)
    prs = selected_prs(args.pr)
    if args.patterns and len(prs) != 1:
        sys.exit("--patterns overrides the patterns for exactly one --pr")
    for pr in prs:
        patterns = (
            args.patterns if args.patterns else [REPO / p for p in PR_PATTERNS[pr]]
        )
        collect_patterns(files, pr, patterns, outdir)
    return 0


def cmd_metrics(args: argparse.Namespace) -> int:
    outdir = Path(args.outdir)
    for pr in selected_prs(args.pr):
        g_path = outdir / f"{pr}_G.anchors"
        p_path = outdir / f"{pr}_P.anchors"
        if not g_path.is_file():
            sys.exit(
                f"missing ground-truth anchors for {pr} in {outdir}; run `gt` first"
            )
        if not p_path.is_file():
            sys.exit(
                f"missing prediction anchors for {pr} in {outdir}; run `pattern` first"
            )

        G = load_anchors(g_path)
        P = load_anchors(p_path)
        print(f"== {pr} ==")
        for stem in ("G", "P"):
            timing = outdir / f"{pr}_{stem}_timing.txt"
            if timing.is_file():
                print(f"  {stem} timing:")
                for line in timing.read_text().splitlines():
                    print(f"    {line}")

        print("  --- anchored-instruction level ---")
        print_metrics(G, P, "anchor")
        print("  --- function level ---")
        print_metrics(func_keys(G), func_keys(P), "function")
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def add_common_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--corpus", type=Path, default=REPO / "eval" / "corpus")
    p.add_argument(
        "--outdir",
        type=Path,
        default=REPO / "eval" / "results",
        help="output directory for anchors/timing (default: eval/results)",
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="stage", required=True)

    g = sub.add_parser("gt", help="collect LLVM ground-truth anchors")
    g.add_argument(
        "--pr",
        nargs="*",
        help="only run the given PRs (default: all); e.g. --pr pr214541 pr204089",
    )
    add_common_args(g)
    g.set_defaults(func=cmd_gt)

    p = sub.add_parser("pattern", help="collect MetaphIR pattern predictions")
    p.add_argument(
        "--pr",
        nargs="*",
        help="only run the given PRs (default: all); e.g. --pr pr214541 pr204089",
    )
    p.add_argument(
        "--patterns",
        nargs="+",
        type=Path,
        help="override the patterns for exactly one --pr (otherwise patterns "
        "come from the built-in PR_PATTERNS map)",
    )
    add_common_args(p)
    p.set_defaults(func=cmd_pattern)

    m = sub.add_parser("metrics", help="compute metrics from saved anchors")
    m.add_argument(
        "--pr",
        nargs="*",
        help="only compute metrics for the given PRs (default: all)",
    )
    add_common_args(m)
    m.set_defaults(func=cmd_metrics)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
