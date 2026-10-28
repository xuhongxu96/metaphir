#!/usr/bin/env python3
"""Evaluate MetaphIR patterns against LLVM's InstCombine pass over a corpus.

The evaluation compares functions: a fold's ground truth (G) is the set of
functions it fires in, a tool's predictions (P) the set of functions its
pattern(s) match. The steps are independent and cacheable, so tweaking
patterns does not force re-running the (slower) ground-truth collection:

  gt        Run LLVM's instrumented folds over the corpus and save, for
            every PR (or those given with ``--pr``), the functions they fire
            in to ``<gt-dir>/<pr>_G.functions``. ``--passes`` chooses the
            pipeline (one ``instcombine`` by default). ``--firings input``
            (default) reports only firings rooted at input instructions;
            ``--firings all`` reports every function-level firing, including
            firings from instsimplify passes and pipeline-created code.
            ``--committed ablation`` (default) keeps a firing only if running
            the pipeline without that PR's folds changes the function's IR,
            which drops speculative simplifications that rewrote nothing;
            ``--committed anchor`` keeps every reported anchor.

  index     Index the corpus with ``metaphir-index``.

  check-index
            Check that matching with the index finds the functions matching
            without it finds, on a sample of the corpus and every module with
            ground-truth functions.

  metrics   Score a tool's saved predictions, ``<tool>/<pr>_P.functions``
            from ``run_baseline.py``, against the ground truth in
            ``--gt-dir`` of ``--results`` or of another results directory
            (``--gt``).

Ground truth comes from running an instrumented ``opt`` with
``METAPHIR_EVAL_ENABLED=1``, which reports ``ANCHOR <function> <pr>``.

The tools default to ``llvm-project/build/bin/opt``,
``build/tools/metaphir-match`` and ``build/tools/metaphir-index``; set
``METAPHIR_OPT`` / ``METAPHIR_MATCH`` / ``METAPHIR_INDEX`` to override them.
"""

from __future__ import annotations

import argparse
import os
import random
import re
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from prs import PRS

REPO = Path(__file__).resolve().parents[2]
OPT = Path(
    os.environ.get("METAPHIR_OPT", REPO / "llvm-project" / "build" / "bin" / "opt")
)
METAPHIR_MATCH = Path(
    os.environ.get("METAPHIR_MATCH", REPO / "build" / "tools" / "metaphir-match")
)
METAPHIR_INDEX = Path(
    os.environ.get("METAPHIR_INDEX", REPO / "build" / "tools" / "metaphir-index")
)
GT_DIR = "gt"
# The pass pipeline for a direct GT run.  `no-verify-fixpoint` is required: the
# textual instcombine parser enables it, and an abort loses later functions.
GT_PASSES = "function(instcombine<no-verify-fixpoint>)"
TOOL_CHOICES = ["metaphir-index", "metaphir-scan", "daggrep"]

PR_PATTERNS: dict[str, tuple[str, ...]] = {pr: e.patterns for pr, e in PRS.items()}

ANCHOR_RE = re.compile(r"^ANCHOR (\S+) (\S+)$")
SUMMARY_FILES_RE = re.compile(
    r"^matched (\d+) of (\d+) functions \(in (\d+) of (\d+) files\)$", re.M
)
SUMMARY_POSTING_RE = re.compile(
    r"^matched (\d+) of (\d+) functions \((\d+) on the posting lists\)$", re.M
)


def match_stats(stderr: str) -> MatchStats:
    """The candidate counts in ``metaphir-match --summary``'s stderr."""
    if m := SUMMARY_FILES_RE.search(stderr):
        return MatchStats(*(int(x) for x in m.groups()))
    if m := SUMMARY_POSTING_RE.search(stderr):
        checked, functions, posting = (int(x) for x in m.groups())
        return MatchStats(checked, functions, posting_candidates=posting)
    return MatchStats()

# A function of the corpus: (module file name, function name).
Func = tuple[str, str]


@dataclass(frozen=True)
class MatchStats:
    """What ``metaphir-match --summary`` reports for one pattern run.

    ``checked`` is the number of functions whose features may match: the packs
    a published query would fetch. ``files`` is the number of modules read.
    """

    checked: int | None = None
    functions: int | None = None
    files: int | None = None
    total_files: int | None = None
    posting_candidates: int | None = None


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
def run_llvm(
    bc: Path, prs: list[str], env: dict[str, str], passes: str = GT_PASSES
) -> tuple[dict[str, set[Func]], str | None]:
    """The functions of ``bc`` each fold of ``prs`` fires in.

    Runs ``passes`` with ``METAPHIR_EVAL_ENABLED=1``, so the instrumented folds
    report anchors. Fixpoint verification is disabled by default: when it
    fails, opt aborts mid-module and every later function would silently be
    lost. Returns the functions and, if opt still exits non-zero, the tail of
    its stderr.
    """
    proc = subprocess.run(
        [
            str(OPT),
            f"-passes={passes}",
            str(bc),
            "-o",
            "/dev/null",
        ],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    by_pr: dict[str, set[Func]] = {pr: set() for pr in prs}
    for line in proc.stderr.splitlines():
        m = ANCHOR_RE.match(line)
        if m:
            for pr in prs:
                if m.group(2) == pr:
                    by_pr[pr].add((bc.name, m.group(1)))
    error = None
    if proc.returncode != 0:
        tail = [ln for ln in proc.stderr.splitlines() if not ANCHOR_RE.match(ln)][-3:]
        error = f"rc={proc.returncode}: " + " | ".join(tail)
    return by_pr, error


FUNCTION_RE = re.compile(
    r'^define [^\n]*?@("(?:[^"\\]|\\.)*"|[-\w$.]+)\(.*?^\}', re.MULTILINE | re.DOTALL
)


def function_texts(ir: str) -> dict[str, str]:
    """The text of each function definition of ``ir``, by name.

    Attribute-group (``#3``) and metadata (``!12``) numbers are numbered per
    module, so a change in one function can renumber another's; they are
    blanked so only real differences remain.
    """
    texts = {}
    for m in FUNCTION_RE.finditer(ir):
        name = m.group(1)
        if name.startswith('"'):
            name = re.sub(
                r"\\([0-9A-Fa-f]{2})", lambda h: chr(int(h.group(1), 16)), name[1:-1]
            )
        texts[name] = re.sub(r"([#!])\d+", r"\1N", m.group(0))
    return texts


def optimized_ir(
    bc: Path, env: dict[str, str], passes: str, ablate: str | None = None
) -> dict[str, str]:
    """The functions of ``bc`` after ``passes``, with the folds of ``ablate``
    (a PR) turned off."""
    env = dict(env)
    env.pop("METAPHIR_EVAL_ABLATE", None)
    if ablate:
        env["METAPHIR_EVAL_ABLATE"] = ablate
    proc = subprocess.run(
        [str(OPT), f"-passes={passes}", "-S", str(bc), "-o", "-"],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    return function_texts(proc.stdout)


def committed_only(
    bc: Path,
    by_pr: dict[str, set[Func]],
    env: dict[str, str],
    passes: str,
) -> tuple[dict[str, set[Func]], dict[str, int]]:
    """Keep the firings that changed the IR.

    A fold may simplify speculatively and have its result discarded (for
    example ``foldOpIntoPhi`` giving up on a phi), or its result may be
    thrown away by an enclosing transform, so a reported anchor does not mean
    the fold rewrote anything. Running the pipeline again without a PR's folds
    shows whether the function's IR depends on them: a firing in a function
    whose IR is identical either way is dropped. Needs no knowledge of where
    the folds are called from.
    """
    if not any(by_pr.values()):
        return by_pr, {}
    base = optimized_ir(bc, env, passes)
    kept: dict[str, set[Func]] = {}
    dropped: dict[str, int] = {}
    for pr, funcs in by_pr.items():
        if not funcs:
            kept[pr] = funcs
            continue
        ablated = optimized_ir(bc, env, passes, ablate=pr)
        kept[pr] = {
            (m, fn) for m, fn in funcs if base.get(fn) != ablated.get(fn)
        }
        dropped[pr] = len(funcs) - len(kept[pr])
    return kept, dropped


def response_file_line(path: Path) -> str:
    """``path`` quoted for an LLVM response file."""
    return '"' + str(path).replace("\\", "\\\\").replace('"', '\\"') + '"\n'


def run_metaphir(
    pattern: Path,
    files: list[Path],
    jobs: int,
    index: Path | None = None,
    extra_args: list[str] | None = None,
) -> tuple[set[Func], list[str], MatchStats]:
    """Match ``pattern`` against all ``files`` in one ``metaphir-match`` run,
    using ``index`` when given.

    Returns the functions matched, the errors, and the summary counts: the
    functions whose features may match (the packs a published query fetches)
    and the modules read.
    """
    with tempfile.NamedTemporaryFile("w", suffix=".rsp") as response:
        response.writelines(response_file_line(f) for f in files)
        response.flush()
        cmd = [str(METAPHIR_MATCH), "--matches-only", "--summary", "-j", str(jobs)]
        cmd += extra_args or []
        if index:
            cmd += ["--index", str(index)]
        proc = subprocess.run(
            cmd + [str(pattern), f"@{response.name}"],
            capture_output=True,
            text=True,
            check=False,
        )
    errors = [ln for ln in proc.stderr.splitlines() if ": error: " in ln]
    if proc.returncode < 0 or (proc.returncode != 0 and not errors):
        tail = " | ".join(proc.stderr.splitlines()[-3:])
        errors.append(f"rc={proc.returncode}: {tail}")
    for line in proc.stderr.splitlines():
        if ": warning: " in line:
            print(f"  {line}")
    # Each match is "<file>\t@<function>\t<bindings>".
    funcs = set()
    for line in proc.stdout.splitlines():
        path, func, _ = line.split("\t", 2)
        funcs.add((Path(path).name, func.removeprefix("@")))
    return funcs, [f"metaphir-match {pattern.name}: {e}" for e in errors], match_stats(
        proc.stderr
    )


# --------------------------------------------------------------------------- #
# Function sets and metrics
# --------------------------------------------------------------------------- #
def save_functions(path: Path, funcs: set[Func]) -> None:
    path.write_text("".join("\t".join(f) + "\n" for f in sorted(funcs)))


def load_functions(path: Path) -> set[Func]:
    funcs: set[Func] = set()
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) != 2:
            sys.exit(f"{path}: malformed line: {line!r}")
        funcs.add((fields[0], fields[1]))
    return funcs


def scores(G: set, P: set) -> dict[str, float | int]:
    tp = len(G & P)
    return {
        "G": len(G),
        "P": len(P),
        "TP": tp,
        "FP": len(P - G),
        "FN": len(G - P),
        "precision": tp / len(P) if P else 1.0,
        "recall": tp / len(G) if G else 1.0,
        "f1": 2 * tp / (len(G) + len(P)) if (G or P) else 1.0,
    }


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


def require_jobs(args: argparse.Namespace) -> None:
    if args.jobs < 1:
        sys.exit("--jobs must be at least 1")


def cmd_gt(args: argparse.Namespace) -> int:
    require_executable(OPT, "run scripts/prepare_llvm.sh or set METAPHIR_OPT")
    require_jobs(args)
    require_results(args)
    outdir = Path(args.results) / args.gt_dir
    outdir.mkdir(parents=True, exist_ok=True)
    files = collect_corpus(args.corpus)
    prs = selected_prs(args.pr)
    print(f"== gt: {len(files)} modules, {len(prs)} PR(s), passes={args.passes} ==")
    env = dict(os.environ)
    env["METAPHIR_EVAL_ENABLED"] = "1"
    if args.firings == "all":
        env["METAPHIR_EVAL_ALL_FIRINGS"] = "1"
    else:
        env.pop("METAPHIR_EVAL_ALL_FIRINGS", None)

    dropped_total: dict[str, int] = {pr: 0 for pr in prs}

    def worker(bc: Path) -> tuple[dict[str, set[Func]], str | None, float]:
        t0 = time.perf_counter()
        res, error = run_llvm(bc, prs, env, args.passes)
        if args.committed == "ablation" and not error:
            res, dropped = committed_only(bc, res, env, args.passes)
            for pr, n in dropped.items():
                dropped_total[pr] += n
        return res, error, time.perf_counter() - t0

    G: dict[str, set[Func]] = {pr: set() for pr in prs}
    failed: list[tuple[Path, str]] = []
    total_t = 0.0
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for bc, (by_pr, error, t) in zip(files, pool.map(worker, files), strict=True):
            total_t += t
            if error:
                failed.append((bc, error))
            for pr, funcs in by_pr.items():
                G[pr] |= funcs

    if failed:
        print(
            f"  warning: opt failed on {len(failed)} module(s); "
            "their functions may be missing:"
        )
        for bc, error in failed:
            print(f"    {bc.name}: {error}")
    for pr in prs:
        if not G[pr]:
            print(
                f"  warning: the fold of {pr} fires nowhere; it may be absent "
                "from this LLVM revision"
            )
        save_functions(outdir / f"{pr}_G.functions", G[pr])
        note = (
            f" (+{dropped_total[pr]} anchors dropped: IR unchanged without the fold)"
            if dropped_total[pr]
            else ""
        )
        print(f"  {pr}: {len(G[pr])} functions{note}")
    (outdir / "timing.txt").write_text(
        f"modules={len(files)}\nprs={len(prs)}\ngt_seconds={total_t:.3f}\n"
    )
    print(f"  {total_t:.2f} CPU-seconds, summed over the modules")
    return 0


def require_index(index: Path) -> None:
    if not index.is_file():
        sys.exit(f"{index} not found; run `index` first")


def cmd_index(args: argparse.Namespace) -> int:
    require_executable(METAPHIR_INDEX, "build MetaphIR or set METAPHIR_INDEX")
    require_jobs(args)
    t0 = time.perf_counter()
    proc = subprocess.run(
        [
            str(METAPHIR_INDEX),
            "build",
            "-j",
            str(args.jobs),
            str(args.corpus),
            "-o",
            str(args.index),
        ],
        check=False,
    )
    if proc.returncode == 0:
        print(f"  indexed -> {args.index} in {time.perf_counter() - t0:.2f}s")
    return proc.returncode


def cmd_check_index(args: argparse.Namespace) -> int:
    """Compares matching with the index with matching without it."""
    require_executable(METAPHIR_MATCH, "build MetaphIR or set METAPHIR_MATCH")
    require_index(args.index)
    require_jobs(args)
    if args.gt is None:
        require_results(args)
    files = collect_corpus(args.corpus)
    # Modules with ground-truth functions are always checked.
    g_dir = Path(args.gt or args.results) / args.gt_dir
    rng = random.Random(args.seed)
    differences = 0
    for pr in selected_prs(args.pr):
        sample = set(rng.sample(files, min(args.sample, len(files))))
        g_path = g_dir / f"{pr}_G.functions"
        if g_path.is_file():
            modules = {m for m, _ in load_functions(g_path)}
            sample |= {f for f in files if f.name in modules}
        checked = sorted(sample)
        print(f"== check-index {pr}: {len(checked)} modules ==")
        for pattern in (REPO / p for p in PR_PATTERNS[pr]):
            expected, errors, _ = run_metaphir(pattern, checked, args.jobs)
            actual, index_errors, _ = run_metaphir(
                pattern, checked, args.jobs, args.index
            )
            errors += index_errors
            for error in errors:
                print(f"  {error}")
            for func in sorted(expected - actual):
                print(f"  {pattern.name}: missed with the index: {func}")
            for func in sorted(actual - expected):
                print(f"  {pattern.name}: only with the index: {func}")
            differences += len(expected ^ actual) + len(errors)
    print(f"{differences} difference(s)")
    return 1 if differences else 0


def cmd_metrics(args: argparse.Namespace) -> int:
    require_results(args)
    g_dir = Path(args.gt or args.results) / args.gt_dir
    p_dir = Path(args.results) / args.tool
    for pr in selected_prs(args.pr):
        g_path = g_dir / f"{pr}_G.functions"
        p_path = p_dir / f"{pr}_P.functions"
        if not g_path.is_file():
            sys.exit(f"missing ground truth for {pr} in {g_dir}; run `gt` first")
        if not p_path.is_file():
            sys.exit(
                f"missing predictions for {pr} in {p_dir}; run "
                "eval/scripts/run_baseline.py first"
            )
        s = scores(load_functions(g_path), load_functions(p_path))
        print(f"== {pr} ==")
        timing = p_dir / f"{pr}_P_timing.txt"
        if timing.is_file():
            print("  timing:")
            for line in timing.read_text().splitlines():
                print(f"    {line}")
        print(f"  |G|={s['G']} |P|={s['P']} TP={s['TP']} FP={s['FP']} FN={s['FN']}")
        print(
            f"  recall={s['recall']:.4f} precision={s['precision']:.4f} "
            f"F1={s['f1']:.4f}"
        )
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def add_common_args(p: argparse.ArgumentParser, prs: bool = True) -> None:
    if prs:
        p.add_argument(
            "--pr",
            nargs="*",
            help="only the given PRs (default: all); e.g. --pr pr214541 pr204089",
        )
    p.add_argument(
        "--corpus", type=Path, required=True, help="the corpus directory"
    )
    p.add_argument(
        "--results",
        type=Path,
        help="results directory of the corpus: gt/ and one directory per tool",
    )
    p.add_argument(
        "--gt-dir",
        default=GT_DIR,
        help=f"ground-truth subdirectory of --results/--gt (default: {GT_DIR})",
    )
    p.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=1,
        help="number of parallel jobs (default: 1)",
    )


def require_results(args: argparse.Namespace) -> None:
    if args.results is None:
        sys.exit("--results is required for this stage")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="stage", required=True)

    g = sub.add_parser("gt", help="collect the ground truth")
    g.add_argument(
        "--passes",
        default=GT_PASSES,
        help=f"pass pipeline whose fold firings are the ground truth "
        f"(default: {GT_PASSES})",
    )
    g.add_argument(
        "--firings",
        choices=("input", "all"),
        default="input",
        help="'input': only firings rooted at input instructions (direct GT); "
        "'all': every function-level firing in the pipeline (real scenario)",
    )
    g.add_argument(
        "--committed",
        choices=("ablation", "anchor"),
        default="ablation",
        help="'ablation': keep a firing only if the function's IR changes "
        "when that PR's folds are turned off; 'anchor': keep every reported "
        "anchor, including speculative ones",
    )
    add_common_args(g)
    g.set_defaults(func=cmd_gt)

    x = sub.add_parser("index", help="index the corpus")
    x.add_argument(
        "--index", type=Path, required=True, help="index to write"
    )
    add_common_args(x, prs=False)
    x.set_defaults(func=cmd_index)

    c = sub.add_parser(
        "check-index", help="check matching with the index against matching without"
    )
    c.add_argument(
        "--index", type=Path, required=True, help="index to use"
    )
    c.add_argument(
        "--sample",
        type=int,
        default=200,
        help="random modules to check besides those with ground-truth functions",
    )
    c.add_argument("--seed", type=int, default=0, help="seed for the sample")
    c.add_argument(
        "--gt",
        type=Path,
        help="results directory whose gt/ names the modules to always check "
        "(default: --results)",
    )
    add_common_args(c)
    c.set_defaults(func=cmd_check_index)

    m = sub.add_parser("metrics", help="score saved predictions")
    m.add_argument(
        "--tool",
        choices=TOOL_CHOICES,
        default="metaphir-index",
        help="whose predictions to score (default: metaphir-index)",
    )
    m.add_argument(
        "--gt",
        type=Path,
        help="results directory whose gt/ to score against (default: --results)",
    )
    add_common_args(m)
    m.set_defaults(func=cmd_metrics)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
