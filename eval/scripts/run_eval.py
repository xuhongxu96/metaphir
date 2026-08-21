#!/usr/bin/env python3
"""Evaluate a MetaphIR pattern against a PR pass-plugin over a corpus.

Two decoupled stages so that metric tweaks don't require re-running the tools:

  collect   Run the plugin and the MetaphIR pattern(s) over the corpus and save
            the anchor sets + timing to files.
  metrics   Load saved anchor sets and compute evaluation metrics.

Ground truth (G): anchors (file, function, anchor-ssa-name) where the PR's pass
plugin fires. Prediction (P): anchors where the MetaphIR pattern(s) match.
Both run on the same preprocessed (pre-InstCombine) IR.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
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
    "pr213709": ["eval/patterns/pr213709_eq.mpir",
                 "eval/patterns/pr213709_ne0.mpir",
                 "eval/patterns/pr213709_ne1.mpir"],
    "pr213313": ["eval/patterns/pr213313_and.mpir",
                 "eval/patterns/pr213313_or.mpir"],
    "pr212132": ["eval/patterns/pr212132_c1.mpir",
                 "eval/patterns/pr212132_c2.mpir",
                 "eval/patterns/pr212132_c3.mpir",
                 "eval/patterns/pr212132_c4.mpir"],
    "pr210499": ["eval/patterns/pr210499.mpir"],
    "pr209322": ["eval/patterns/pr209322.mpir"],
    "pr207564": ["eval/patterns/pr207564.mpir"],
    "pr207462": ["eval/patterns/pr207462.mpir"],
    "pr205383": ["eval/patterns/pr205383_sub.mpir",
                 "eval/patterns/pr205383_xor.mpir"],
    "pr204928": ["eval/patterns/pr204928.mpir"],
    "pr204927": ["eval/patterns/pr204927.mpir"],
    "pr216470": ["eval/patterns/pr216470.mpir"],
    "pr216046": ["eval/patterns/pr216046.mpir"],
    "pr204089": ["eval/patterns/pr204089.mpir"],
}

ANCHOR_RE = re.compile(r"^ANCHOR (\S+) (\S+)$")
TARGET_RE = re.compile(r"^target \d+: @(\S+)$")
BINDING_RE = re.compile(r"\?anch = (%[^,\s]+)")


def collect_corpus(corpus: Path) -> list[Path]:
    files = sorted(p for p in corpus.rglob("*") if p.suffix in (".bc", ".ll"))
    if not files:
        sys.exit(f"no .bc/.ll files found under {corpus}")
    return files


def preprocess(bc: Path, out: Path) -> bool:
    """Run the pre-InstCombine passes to reproduce the IR InstCombine sees.

    The collected `original/` modules are O0 (alloca/load/store); InstCombine in
    a real pipeline runs after mem2reg/sroa/early-cse/simplifycfg, which is what
    exposes the SSA algebraic patterns. Both ground truth and prediction run on
    this preprocessed IR.
    """
    proc = subprocess.run(
        [
            str(OPT),
            "-passes=function(sroa,mem2reg,early-cse,simplifycfg)",
            str(bc),
            "-o",
            str(out),
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.returncode == 0


def run_plugin(so: Path, pass_name: str, bc: Path) -> set[tuple[str, str, str]]:
    anchors: set[tuple[str, str, str]] = set()
    proc = subprocess.run(
        [
            str(OPT),
            f"-load-pass-plugin={so}",
            f"-passes={pass_name}",
            str(bc),
            "-o",
            "/dev/null",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    for line in proc.stderr.splitlines():
        m = ANCHOR_RE.match(line)
        if m:
            anchors.add((bc.name, m.group(1), m.group(2)))
    return anchors


def run_pattern(pattern: Path, bc: Path) -> set[tuple[str, str, str]]:
    anchors: set[tuple[str, str, str]] = set()
    proc = subprocess.run(
        [str(METAPHIR_MATCH), str(pattern), str(bc)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        return anchors
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


def load_anchors(path: Path) -> set[tuple[str, str, str]]:
    anchors: set[tuple[str, str, str]] = set()
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        f, fn, a = line.split("\t", 2)
        anchors.add((f, fn, a))
    return anchors


def func_keys(anchors: set[tuple[str, str, str]]) -> set[tuple[str, str]]:
    return {(f, fn) for (f, fn, _) in anchors}


def metrics(G: set, P: set, label: str) -> None:
    tp = len(G & P)
    fp = len(P - G)
    fn = len(G - P)
    denom = len(G | P)
    recall = tp / len(G) if G else 1.0
    precision = tp / len(P) if P else 1.0
    f1 = 2 * tp / (len(G) + len(P)) if (len(G) + len(P)) else 1.0
    jaccard = tp / denom if denom else 1.0
    print(f"  [{label}] |G|={len(G)} |P|={len(P)} TP={tp} FP={fp} FN={fn}")
    print(
        f"  [{label}] recall={recall:.4f} precision={precision:.4f} "
        f"F1={f1:.4f} diff_rate={1 - jaccard:.4f}"
    )


def cmd_collect(args: argparse.Namespace) -> int:
    corpus_files = collect_corpus(args.corpus)
    print(f"== collect {args.pr}: {len(corpus_files)} corpus files ==")
    out = Path(args.outdir)
    out.mkdir(parents=True, exist_ok=True)
    g_path = out / f"{args.pr}_G.anchors"
    p_path = out / f"{args.pr}_P.anchors"
    timing_path = out / f"{args.pr}_timing.txt"

    G: set = set()
    P: set = set()
    t_plugin = 0.0
    t_pattern = 0.0
    n_ok = 0
    import tempfile

    with tempfile.TemporaryDirectory(prefix="metaphir-eval-") as tmp:
        tmp_path = Path(tmp)
        for bc in corpus_files:
            pp = bc
            if args.preprocess:
                pp = tmp_path / (bc.stem + ".bc")
                if not preprocess(bc, pp):
                    print(f"  warning: preprocessing failed for {bc.name}")
                    continue
            n_ok += 1
            t0 = time.time()
            anchors = run_plugin(args.plugin, args.pass_name, pp)
            t_plugin += time.time() - t0
            G |= anchors

            file_anchors: set = set()
            t0 = time.time()
            for pattern in args.patterns:
                file_anchors |= run_pattern(pattern, pp)
            t_pattern += time.time() - t0
            P |= file_anchors

    with open(g_path, "w") as fh:
        fh.writelines("\t".join(a) + "\n" for a in sorted(G))
    with open(p_path, "w") as fh:
        fh.writelines("\t".join(a) + "\n" for a in sorted(P))
    with open(timing_path, "w") as fh:
        fh.write(f"modules_ok={n_ok}\n")
        fh.write(f"plugin_seconds={t_plugin:.3f}\n")
        fh.write(f"pattern_seconds={t_pattern:.3f}\n")
        fh.write(f"patterns={len(args.patterns)}\n")
        fh.write(f"G_anchors={len(G)}\n")
        fh.write(f"P_anchors={len(P)}\n")

    print(f"  saved G anchors -> {g_path} ({len(G)})")
    print(f"  saved P anchors -> {p_path} ({len(P)})")
    print(f"  saved timing    -> {timing_path}")
    print(f"  plugin {t_plugin:.2f}s | pattern {t_pattern:.2f}s")
    return 0


def cmd_metrics(args: argparse.Namespace) -> int:
    out = Path(args.anchors_dir)
    g_path = out / f"{args.pr}_G.anchors"
    p_path = out / f"{args.pr}_P.anchors"
    if not g_path.is_file() or not p_path.is_file():
        sys.exit(f"missing anchor files for {args.pr} in {out}; run collect first")
    G = load_anchors(g_path)
    P = load_anchors(p_path)
    timing_path = out / f"{args.pr}_timing.txt"
    if timing_path.is_file():
        print(f"== {args.pr} (saved anchors) ==")
        for line in timing_path.read_text().splitlines():
            print(f"  {line}")
    print("\n--- anchored-instruction level ---")
    metrics(G, P, "anchor")
    print("\n--- function level ---")
    metrics(func_keys(G), func_keys(P), "function")
    return 0


def cmd_run_all(args: argparse.Namespace) -> int:
    """Run collect + metrics for every PR, then print a summary table."""
    out = Path(args.outdir)
    out.mkdir(parents=True, exist_ok=True)

    prs = list(PR_PATTERNS)
    if args.pr:
        unknown = [pr for pr in args.pr if pr not in PR_PATTERNS]
        if unknown:
            sys.exit(f"unknown PR(s): {', '.join(unknown)}")
        prs = args.pr

    rows: list[tuple[str, int, int, int, int, int, float, float]] = []
    for pr in prs:
        patterns = PR_PATTERNS[pr]
        plugin = REPO / "build" / "eval" / "plugins" / f"{pr}.so"
        collect_args = argparse.Namespace(
            pr=pr, plugin=plugin, pass_name=pr,
            patterns=[REPO / p for p in patterns],
            corpus=args.corpus, preprocess=False, outdir=out,
        )
        if cmd_collect(collect_args) != 0:
            return 1
        g = load_anchors(out / f"{pr}_G.anchors")
        p = load_anchors(out / f"{pr}_P.anchors")
        tp = len(g & p)
        fp = len(p - g)
        fn = len(g - p)
        recall = tp / len(g) if g else 1.0
        f1 = 2 * tp / (len(g) + len(p)) if (len(g) + len(p)) else 1.0
        rows.append((pr, len(g), len(p), tp, fp, fn, recall, f1))
        print(f"  {pr}: G={len(g)} P={len(p)} TP={tp} FP={fp} FN={fn} "
              f"R={recall:.3f} F1={f1:.3f}")

    print("\n=== SUMMARY ===")
    print(f"{'pr':<10} {'G':>5} {'P':>5} {'TP':>4} {'FP':>4} {'FN':>4} "
          f"{'recall':>7} {'F1':>6}")
    for pr, g, p, tp, fp, fn, recall, f1 in rows:
        print(f"{pr:<10} {g:>5} {p:>5} {tp:>4} {fp:>4} {fn:>4} "
              f"{recall:>7.3f} {f1:>6.3f}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="stage", required=True)

    c = sub.add_parser("collect", help="run tools and save anchors")
    c.add_argument("--pr", required=True)
    c.add_argument("--plugin", required=True, type=Path)
    c.add_argument("--pass", dest="pass_name", required=True)
    c.add_argument("--patterns", nargs="+", type=Path, required=True)
    c.add_argument("--corpus", type=Path, default=REPO / "eval" / "corpus")
    c.add_argument(
        "--preprocess",
        action="store_true",
        help="preprocess each module before matching (use only if "
        "the corpus is not already preprocessed)",
    )
    c.add_argument("--outdir", required=True, type=Path)
    c.set_defaults(func=cmd_collect)

    m = sub.add_parser("metrics", help="compute metrics from saved anchors")
    m.add_argument("--pr", required=True)
    m.add_argument("--anchors-dir", required=True, type=Path)
    m.set_defaults(func=cmd_metrics)

    a = sub.add_parser("run_all", help="collect + metrics for every PR")
    a.add_argument("--corpus", type=Path, default=REPO / "eval" / "corpus")
    a.add_argument(
        "--pr",
        nargs="*",
        help="only run the given PRs (default: all); e.g. --pr pr214541 pr204089",
    )
    a.add_argument("--outdir", required=True, type=Path)
    a.set_defaults(func=cmd_run_all)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
