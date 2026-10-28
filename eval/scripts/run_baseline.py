#!/usr/bin/env python3
"""Run a tool's patterns over the corpus and save the functions they match.

  metaphir-index  eval/patterns, one `metaphir-match` run per pattern over the
                  whole corpus, with the index (``--index``, required)
  metaphir-scan   the same, without the index
  daggrep         eval/baselines/daggrep/patterns/<pr>[_<alt>].ll, one run of
                  the adapted daggrep per pattern over the whole corpus (its
                  own threads)

A PR's predictions are the union over its pattern files. They are saved to
``<results>/<tool>/<pr>_P.functions`` in the format of ``run_eval.py``, so
``run_eval.py metrics --tool <tool>`` scores them against the ground truth.
The time recorded is the wall-clock time per pattern file, the median of
``--repeat`` runs.

daggrep defaults to ``eval/baselines/daggrep/build/daggrep``; set ``DAGGREP``
to override it.
"""

from __future__ import annotations

import argparse
import os
import statistics
import subprocess
import sys
import tempfile
import time
from collections.abc import Callable
from pathlib import Path

from run_eval import (
    METAPHIR_MATCH,
    PR_PATTERNS,
    REPO,
    Func,
    MatchStats,
    collect_corpus,
    response_file_line,
    run_metaphir,
    save_functions,
    selected_prs,
)

BASELINES = REPO / "eval" / "baselines"
DAGGREP = Path(
    os.environ.get("DAGGREP", BASELINES / "daggrep" / "build" / "daggrep")
)
PATTERN_DIRS = {
    "daggrep": (BASELINES / "daggrep" / "patterns", ".ll"),
}


def pattern_files(tool: str, pr: str) -> list[Path]:
    """The baseline pattern files of ``pr``: ``<pr>`` or ``<pr>_<alt>``."""
    if tool.startswith("metaphir"):
        return [REPO / p for p in PR_PATTERNS[pr]]
    directory, suffix = PATTERN_DIRS[tool]
    files = sorted(
        p for p in directory.glob(f"*{suffix}") if p.stem == pr or p.stem.startswith(pr + "_")
    )
    if not files:
        sys.exit(f"no {tool} pattern for {pr} in {directory}")
    return files


# --------------------------------------------------------------------------- #
# daggrep
# --------------------------------------------------------------------------- #
def parse_daggrep(stdout: str) -> set[Func]:
    """daggrep prints one ``<file>\\t@<function>`` line per matching function."""
    funcs: set[Func] = set()
    for line in stdout.splitlines():
        path, func = line.split("\t")
        funcs.add((Path(path).name, func.removeprefix("@")))
    return funcs


def run_daggrep(pattern: Path, files: list[Path], jobs: int) -> tuple[set[Func], list[str]]:
    with tempfile.NamedTemporaryFile("w", suffix=".rsp") as response:
        response.writelines(response_file_line(f) for f in files)
        response.flush()
        proc = subprocess.run(
            [str(DAGGREP), "-j", str(jobs), str(pattern), f"@{response.name}"],
            capture_output=True,
            text=True,
            check=False,
        )
    errors = [ln for ln in proc.stderr.splitlines() if "error:" in ln]
    if proc.returncode < 0 or (proc.returncode != 0 and not errors):
        tail = " | ".join(proc.stderr.splitlines()[-3:])
        errors.append(f"daggrep {pattern.name}: rc={proc.returncode}: {tail}")
    return (
        parse_daggrep(proc.stdout),
        [f"daggrep {pattern.name}: {e}" for e in errors],
        MatchStats(),
    )


INDEX: Path = Path()
MATCH_ARGS: list[str] = []
RUNNERS: dict[str, Callable[[Path, list[Path], int], tuple[set[Func], list[str]]]] = {
    "daggrep": run_daggrep,
    "metaphir-scan": lambda p, f, j: run_metaphir(p, f, j, None, MATCH_ARGS),
    "metaphir-index": lambda p, f, j: run_metaphir(p, f, j, INDEX, MATCH_ARGS),
}
TOOLS = {
    "daggrep": DAGGREP,
    "metaphir-scan": METAPHIR_MATCH,
    "metaphir-index": METAPHIR_MATCH,
}


# --------------------------------------------------------------------------- #
# Driver
# --------------------------------------------------------------------------- #
def collect(
    tool: str, pr: str, files: list[Path], outdir: Path, jobs: int, repeat: int
) -> bool:
    patterns = pattern_files(tool, pr)
    print(f"== {tool} {pr}: {len(files)} modules, {len(patterns)} pattern(s) ==")
    P: set[Func] = set()
    failures: list[str] = []
    seconds: dict[str, float] = {}
    counts: dict[str, MatchStats] = {}
    for pattern in patterns:
        times = []
        for _ in range(repeat):
            t0 = time.perf_counter()
            funcs, errors, stats = RUNNERS[tool](pattern, files, jobs)
            times.append(time.perf_counter() - t0)
        seconds[pattern.stem] = statistics.median(times)
        counts[pattern.stem] = stats
        P |= funcs
        failures += errors
        checked = "" if stats.checked is None else f", {stats.checked} packs"
        print(f"  {pattern.name}: {len(funcs)} functions{checked}, {seconds[pattern.stem]:.2f}s")

    save_functions(outdir / f"{pr}_P.functions", P)
    timing = (
        f"modules={len(files)}\n"
        f"tool={tool}\n"
        f"jobs={jobs}\n"
        f"repeat={repeat}\n"
        f"pattern_seconds={sum(seconds.values()):.3f}\n"
        + "".join(f"seconds[{k}]={v:.3f}\n" for k, v in seconds.items())
    )
    for stem, stats in counts.items():
        for field, value in (
            ("checked", stats.checked),
            ("total_functions", stats.functions),
            ("files_read", stats.files),
            ("total_files", stats.total_files),
            ("posting_candidates", stats.posting_candidates),
        ):
            if value is not None:
                timing += f"{field}[{stem}]={value}\n"
    (outdir / f"{pr}_P_timing.txt").write_text(
        timing + f"patterns={len(patterns)}\nP_functions={len(P)}\n"
    )
    failures_path = outdir / f"{pr}_P_failures.txt"
    if failures:
        failures_path.write_text("".join(f + "\n" for f in sorted(set(failures))))
        print(f"  error: {len(failures)} failure(s); see {failures_path}")
    elif failures_path.exists():
        failures_path.unlink()
    print(f"  saved {len(P)} functions")
    return not failures


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("tool", choices=sorted(RUNNERS))
    ap.add_argument("--pr", nargs="*", help="only run the given PRs (default: all)")
    ap.add_argument(
        "--corpus", type=Path, required=True, help="the corpus directory"
    )
    ap.add_argument(
        "--results",
        type=Path,
        required=True,
        help="results directory of the corpus; predictions go to <results>/<tool>",
    )
    ap.add_argument(
        "--outdir",
        type=Path,
        help="write to this directory instead of <results>/<tool>",
    )
    ap.add_argument("-j", "--jobs", type=int, default=1)
    ap.add_argument(
        "--repeat", type=int, default=1, help="runs per pattern; the median is kept"
    )
    ap.add_argument(
        "--index",
        type=Path,
        help="the index metaphir-index uses (required for metaphir-index)",
    )
    ap.add_argument(
        "--match-arg",
        action="append",
        default=[],
        help="pass this option on to metaphir-match (repeatable), e.g. "
        "--match-arg=--no-constraint-prefilter",
    )
    args = ap.parse_args()
    if args.index is None and args.tool == "metaphir-index":
        sys.exit("--index is required for metaphir-index")
    global INDEX
    INDEX = args.index or Path()
    MATCH_ARGS.extend(args.match_arg)
    tool = TOOLS[args.tool]
    if not (tool.is_file() and os.access(tool, os.X_OK)):
        sys.exit(f"{tool} not found; see eval/baselines/README.md")
    if args.jobs < 1 or args.repeat < 1:
        sys.exit("--jobs and --repeat must be at least 1")
    outdir = args.outdir or args.results / args.tool
    outdir.mkdir(parents=True, exist_ok=True)
    files = collect_corpus(args.corpus)
    ok = True
    for pr in selected_prs(args.pr):
        ok &= collect(args.tool, pr, files, outdir, args.jobs, args.repeat)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
