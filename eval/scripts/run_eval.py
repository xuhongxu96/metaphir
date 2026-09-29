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

The tools default to ``llvm-project/build/bin/opt`` and
``build/tools/metaphir-match``; set ``METAPHIR_OPT`` / ``METAPHIR_MATCH`` to
override them.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from prs import PRS

REPO = Path(__file__).resolve().parents[2]
OPT = Path(
    os.environ.get("METAPHIR_OPT", REPO / "llvm-project" / "build" / "bin" / "opt")
)
METAPHIR_MATCH = Path(
    os.environ.get("METAPHIR_MATCH", REPO / "build" / "tools" / "metaphir-match")
)

PR_PATTERNS: dict[str, tuple[str, ...]] = {pr: e.patterns for pr, e in PRS.items()}

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
def fold_id_matches(fold_id: str, pr: str) -> bool:
    """A foldID belongs to ``pr`` when it is exactly the PR name or extends it
    with a ``_`` suffix (e.g. ``pr213313_and`` matches ``pr213313``)."""
    return fold_id == pr or fold_id.startswith(pr + "_")


def run_llvm_anchors(
    bc: Path, prs: list[str], env: dict[str, str]
) -> tuple[dict[str, set[Anchor]], str | None]:
    """Collect ground-truth anchors from LLVM's own fold sites.

    Runs a single instcombine pass with ``METAPHIR_EVAL_ANCHOR=1`` so the
    instrumented folds report every firing as ``ANCHOR <func> <ssa> <foldID>``
    on stderr. Only anchors whose foldID matches one of ``prs`` (exact or
    ``_``-suffixed) are kept.

    Fixpoint verification is disabled: when it fails, opt aborts mid-module and
    every later function would silently lose its anchors. Returns the anchors
    and, if opt still exits non-zero, the tail of its stderr.
    """
    proc = subprocess.run(
        [
            str(OPT),
            "-passes=function(instcombine<no-verify-fixpoint>)",
            str(bc),
            "-o",
            "/dev/null",
        ],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    by_pr: dict[str, set[Anchor]] = {pr: set() for pr in prs}
    for line in proc.stderr.splitlines():
        m = ANCHOR_RE.match(line)
        if m:
            fold_id = m.group(3)
            for pr in prs:
                if fold_id_matches(fold_id, pr):
                    by_pr[pr].add((bc.name, m.group(1), m.group(2)))
    error = None
    if proc.returncode != 0:
        tail = [ln for ln in proc.stderr.splitlines() if not ANCHOR_RE.match(ln)][-3:]
        error = f"rc={proc.returncode}: " + " | ".join(tail)
    return by_pr, error


class PatternRunError(RuntimeError):
    """metaphir-match failed; its predictions for the module are unknown."""


def run_pattern(pattern: Path, bc: Path) -> set[Anchor]:
    proc = subprocess.run(
        [str(METAPHIR_MATCH), str(pattern), str(bc)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        tail = " | ".join(proc.stderr.splitlines()[-3:])
        raise PatternRunError(
            f"metaphir-match {pattern.name} {bc.name}: rc={proc.returncode}: {tail}"
        )

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
    files: list[Path], run: Callable[[Path], set[Anchor]], jobs: int = 1
) -> tuple[set[Anchor], float]:
    """Apply ``run(bc) -> anchors`` to every corpus file.

    Returns the union of the anchors and the summed per-module run time.
    """

    def worker(bc: Path) -> tuple[set[Anchor], float]:
        t0 = time.perf_counter()
        res = run(bc)
        return res, time.perf_counter() - t0

    anchors: set[Anchor] = set()
    elapsed = 0.0
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for res, t in pool.map(worker, files):
            anchors |= res
            elapsed += t
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
        fields = line.split("\t")
        if len(fields) != 3:
            sys.exit(f"{path}: malformed anchor line: {line!r}")
        anchors.add((fields[0], fields[1], fields[2]))
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
    diff_rate = 1 - (tp / union) if union else 0.0
    print(f"  [{label}] |G|={len(G)} |P|={len(P)} TP={tp} FP={fp} FN={fn}")
    print(
        f"  [{label}] recall={recall:.4f} precision={precision:.4f} "
        f"F1={f1:.4f} diff_rate={diff_rate:.4f}"
    )


# --------------------------------------------------------------------------- #
# Collection steps
# --------------------------------------------------------------------------- #
def collect_ground_truth(
    files: list[Path], prs: list[str], outdir: Path, jobs: int = 1
) -> None:
    label = prs[0] if len(prs) == 1 else f"[{', '.join(prs)}]"
    print(f"== gt {label}: {len(files)} modules ==")
    env = dict(os.environ)
    env["METAPHIR_EVAL_ANCHOR"] = "1"

    def worker(bc: Path) -> tuple[dict[str, set[Anchor]], str | None, float]:
        t0 = time.perf_counter()
        res, error = run_llvm_anchors(bc, prs, env)
        return res, error, time.perf_counter() - t0

    all_anchors: dict[str, set[Anchor]] = {pr: set() for pr in prs}
    failed: list[tuple[Path, str]] = []
    total_t = 0.0
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for bc, (by_pr, error, t) in zip(files, pool.map(worker, files), strict=True):
            total_t += t
            if error:
                failed.append((bc, error))
            for pr, a in by_pr.items():
                all_anchors[pr] |= a

    if failed:
        print(
            f"  warning: opt failed on {len(failed)} module(s); "
            "their anchors may be incomplete:"
        )
        for bc, error in failed:
            print(f"    {bc.name}: {error}")

    for pr in prs:
        G = all_anchors[pr]
        if not G:
            print(
                f"  warning: no LLVM ground-truth anchors for {pr}; the fold may be "
                f"absent from this LLVM revision or never fires on the corpus"
            )
        g_path = outdir / f"{pr}_G.anchors"
        save_anchors(g_path, G)
        (outdir / f"{pr}_G_timing.txt").write_text(
            f"modules={len(files)}\n"
            f"gt_seconds={total_t:.3f}\n"
            f"gt_shared_prs={len(prs)}\n"
            f"G_anchors={len(G)}\n"
        )
        print(f"  saved G anchors -> {g_path} ({len(G)})")
    if len(prs) > 1:
        print(f"  gt total time {total_t:.2f}s across {len(prs)} PRs")


def collect_patterns(
    files: list[Path], pr: str, patterns: list[Path], outdir: Path, jobs: int = 1
) -> bool:
    """Collect predictions for ``pr``. Returns False if any module failed.

    A module on which ``metaphir-match`` fails contributes no anchors; it is
    listed in ``<pr>_P_failures.txt`` so the gap is never silent.
    """
    print(f"== pattern {pr}: {len(files)} modules, {len(patterns)} pattern(s) ==")
    failures: list[str] = []

    def run(bc: Path) -> set[Anchor]:
        anchors: set[Anchor] = set()
        for pattern in patterns:
            try:
                anchors |= run_pattern(pattern, bc)
            except PatternRunError as err:
                failures.append(str(err))
        return anchors

    P, t_pat = run_over_corpus(files, run, jobs=jobs)

    p_path = outdir / f"{pr}_P.anchors"
    save_anchors(p_path, P)
    (outdir / f"{pr}_P_timing.txt").write_text(
        f"modules={len(files)}\n"
        f"pattern_seconds={t_pat:.3f}\n"
        f"patterns={len(patterns)}\n"
        f"P_anchors={len(P)}\n"
    )
    failures_path = outdir / f"{pr}_P_failures.txt"
    if failures:
        failures_path.write_text("".join(f + "\n" for f in sorted(failures)))
        print(
            f"  error: metaphir-match failed {len(failures)} time(s); "
            f"see {failures_path}"
        )
    elif failures_path.exists():
        failures_path.unlink()
    print(f"  saved P anchors -> {p_path} ({len(P)})")
    print(f"  pattern {t_pat:.2f}s")
    return not failures


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


def require_executable(path: Path, hint: str) -> None:
    if not (path.is_file() and os.access(path, os.X_OK)):
        sys.exit(f"{path} not found or not executable ({hint})")


def setup_outdir(args: argparse.Namespace) -> tuple[Path, list[Path]]:
    if args.jobs < 1:
        sys.exit("--jobs must be at least 1")
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    return outdir, collect_corpus(args.corpus)


def cmd_gt(args: argparse.Namespace) -> int:
    require_executable(OPT, "run scripts/prepare_llvm.sh or set METAPHIR_OPT")
    outdir, files = setup_outdir(args)
    prs = selected_prs(args.pr)
    collect_ground_truth(files, prs, outdir, jobs=args.jobs)
    return 0


def cmd_pattern(args: argparse.Namespace) -> int:
    require_executable(METAPHIR_MATCH, "build MetaphIR or set METAPHIR_MATCH")
    outdir, files = setup_outdir(args)
    prs = selected_prs(args.pr)
    if args.patterns and len(prs) != 1:
        sys.exit("--patterns overrides the patterns for exactly one --pr")
    ok = True
    for pr in prs:
        patterns = (
            args.patterns if args.patterns else [REPO / p for p in PR_PATTERNS[pr]]
        )
        missing = [str(p) for p in patterns if not p.is_file()]
        if missing:
            sys.exit(f"missing pattern file(s) for {pr}: {', '.join(missing)}")
        ok &= collect_patterns(files, pr, patterns, outdir, jobs=args.jobs)
    return 0 if ok else 1


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
    p.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=1,
        help="number of parallel jobs (default: 1)",
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
