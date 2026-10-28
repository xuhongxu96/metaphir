#!/usr/bin/env python3
"""Summarize one run of eval/scripts/run_all.sh as REPORT.md and summary.json.

    report.py <outdir> [--corpus <dir>] [--gt <results>] [--gt-dir <name>]
              [--suffix <sfx>] [--title <text>] [--note <text>]...

Reads, from <outdir>:
- the ground truth (``<gt-dir>/<pr>_G.functions``) in <outdir>, or ``--gt``'s;
- each tool's predictions and timing (``<tool>/<pr>_P.functions``,
  ``<tool>/<pr>_P_timing.txt``); MetaphIR's are ``metaphir-index/``;
- the logs of the index, stats, check-index and ablation steps (``logs/``).

It writes ``REPORT<sfx>.md`` and ``summary<sfx>.json`` back to <outdir>.
``--gt-dir gt`` is the direct ground truth; ``--gt-dir gt-pipeline
--gt eval/results/original`` is the real scenario.
"""

from __future__ import annotations

import argparse
import json
import platform
import re
import statistics
import subprocess
from pathlib import Path

from pattern_stats import stats as pattern_stats
from prepare_corpus import is_test_file
from run_eval import GT_DIR, PR_PATTERNS, REPO, Func, load_functions, scores

TOOLS = ["metaphir-index", "daggrep"]
TOOL_NAMES = {"metaphir-index": "MetaphIR", "daggrep": "daggrep"}
TIMED = {
    "metaphir-index": "MetaphIR, indexed",
    "metaphir-scan": "MetaphIR, full scan",
    "daggrep": "daggrep",
    "ablation-no-value-facts": "MetaphIR, index w/o value facts",
    "ablation-no-constraint-prefilter": "MetaphIR, indexed, no constraint prefilter",
}
# pr204089's fold is queried speculatively; the evaluation reports the totals
# with and without it.
OUTLIER = "pr204089"


# --------------------------------------------------------------------------- #
# Reading
# --------------------------------------------------------------------------- #
def predictions(outdir: Path, tool: str, pr: str) -> set[Func] | None:
    path = outdir / tool / f"{pr}_P.functions"
    return load_functions(path) if path.is_file() else None


def read_timing(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    return dict(
        line.split("=", 1) for line in path.read_text().splitlines() if "=" in line
    )


def pattern_seconds(outdir: Path, tool: str, pr: str) -> dict[str, float]:
    """Seconds per pattern file of ``pr`` from ``run_baseline.py``'s timing."""
    timing = read_timing(outdir / tool / f"{pr}_P_timing.txt")
    return {
        m.group(1): float(v)
        for k, v in timing.items()
        if (m := re.fullmatch(r"seconds\[(.+)\]", k))
    }


def pattern_counts(outdir: Path, tool: str, pr: str) -> dict[str, dict[str, int]]:
    """Candidate counts per pattern file: packs checked and modules read."""
    timing = read_timing(outdir / tool / f"{pr}_P_timing.txt")
    result: dict[str, dict[str, int]] = {}
    for key, value in timing.items():
        m = re.fullmatch(
            r"(checked|total_functions|files_read|total_files|posting_candidates)\[(.+)\]",
            key,
        )
        if m:
            result.setdefault(m.group(2), {})[m.group(1)] = int(value)
    return result


def read_stats(path: Path) -> dict[str, dict[str, tuple[int, int]]]:
    """metaphir-index stats per pattern: kind -> (surviving, total)."""
    result: dict[str, dict[str, tuple[int, int]]] = {}
    pattern = None
    if not path.is_file():
        return result
    for line in path.read_text().splitlines():
        if line.startswith("== "):
            pattern = line[3:].strip()
            result[pattern] = {}
        elif pattern and (m := re.match(r"(\w+): (\d+) of (\d+)", line)):
            result[pattern][m.group(1)] = (int(m.group(2)), int(m.group(3)))
    return result


def failures(outdir: Path, tool: str) -> int:
    return sum(
        len(p.read_text().splitlines()) for p in (outdir / tool).glob("*_P_failures.txt")
    )


def git(*args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(REPO), *args], capture_output=True, text=True
    ).stdout.strip()


def machine() -> dict[str, str]:
    cpu = ""
    for line in subprocess.run(["lscpu"], capture_output=True, text=True).stdout.splitlines():
        if line.startswith("Model name:"):
            cpu = line.split(":", 1)[1].strip()
    mem_kb = 0
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemTotal:"):
            mem_kb = int(line.split()[1])
    os_name = ""
    for line in Path("/etc/os-release").read_text().splitlines():
        if line.startswith("PRETTY_NAME="):
            os_name = line.split("=", 1)[1].strip('"')
    import os

    return {
        "cpu": f"{cpu} ({platform.machine()})",
        "cores": str(os.cpu_count()),
        "memory": f"{mem_kb / 1024 / 1024:.0f} GiB",
        "os": f"{os_name}, Linux {platform.release()}",
    }


def provenance(corpus: Path | None) -> dict[str, object]:
    llvm_pin = re.search(
        r'^LLVM_COMMIT="(\w+)"', (REPO / "scripts" / "prepare_llvm.sh").read_text(), re.M
    )
    out: dict[str, object] = {
        "metaphir_commit": git("rev-parse", "HEAD")
        + (
            " (with uncommitted changes)"
            # results are this script's output, so they do not make the code dirty
            if git("status", "--porcelain", "--", ".", ":!eval/results")
            else ""
        ),
        "llvm_commit": llvm_pin.group(1) if llvm_pin else "?",
        "machine": machine(),
    }
    if corpus and corpus.is_dir():
        files = [p for p in corpus.iterdir() if p.suffix in (".bc", ".ll")]
        out["corpus"] = {
            "path": rel(corpus),
            "modules": sum(p.suffix == ".bc" for p in files),
            "test_files": sum(p.suffix == ".ll" for p in files),
            "bytes": sum(p.stat().st_size for p in files),
        }
    return out


# --------------------------------------------------------------------------- #
# Formatting
# --------------------------------------------------------------------------- #
def rel(path: Path) -> str:
    """The path relative to the repository when it is inside it."""
    path = path.resolve()
    return str(path.relative_to(REPO) if path.is_relative_to(REPO) else path)


def pct(x: float) -> str:
    return f"{100 * x:.2f}%"


def secs(x: float | None) -> str:
    return "—" if x is None else f"{x:.2f}"


def table(header: list[str], rows: list[list[str]]) -> str:
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    lines += ["| " + " | ".join(r) + " |" for r in rows]
    return "\n".join(lines)


def build(
    outdir: Path,
    corpus: Path | None,
    title: str,
    notes: list[str],
    gt: Path | None = None,
    gt_dir: str = GT_DIR,
) -> tuple[str, dict]:
    prs = sorted(PR_PATTERNS)
    gt_results = gt or outdir
    gt_path = gt_results / gt_dir
    same_corpus = gt_results.resolve() == outdir.resolve() and gt_dir == GT_DIR
    G = {pr: load_functions(gt_path / f"{pr}_G.functions") for pr in prs}
    P = {t: {pr: predictions(outdir, t, pr) for pr in prs} for t in TOOLS}
    tools = [t for t in TOOLS if all(v is not None for v in P[t].values())]

    per_pr = {pr: {t: scores(G[pr], P[t][pr]) for t in tools} for pr in prs}

    def total(t: str, skip: tuple[str, ...] = ()) -> dict:
        keep = [pr for pr in prs if pr not in skip]
        # Each PR is scored on its own, so sum the counts over PRs.
        tp = sum(per_pr[pr][t]["TP"] for pr in keep)
        g = sum(per_pr[pr][t]["G"] for pr in keep)
        p = sum(per_pr[pr][t]["P"] for pr in keep)
        return {
            "G": g, "P": p, "TP": tp, "FP": p - tp, "FN": g - tp,
            "precision": tp / p if p else 1.0,
            "recall": tp / g if g else 1.0,
            "f1": 2 * tp / (g + p) if g + p else 1.0,
            "exact_prs": sum(
                per_pr[pr][t]["FP"] == 0 and per_pr[pr][t]["FN"] == 0 for pr in keep
            ),
        }

    totals = {
        t: {"all": total(t), f"without_{OUTLIER}": total(t, (OUTLIER,))} for t in tools
    }

    # The same totals per source: llvm-opt-benchmark modules vs the upstream
    # test-suite files (``InstCombine__*.ll`` etc.).
    def in_tests(f: Func) -> bool:
        return is_test_file(Path(f[0]))

    def by_source(t: str, tests: bool, skip: tuple[str, ...] = ()) -> dict:
        keep = [pr for pr in prs if pr not in skip]
        g = tp = p = exact = 0
        for pr in keep:
            gs = {f for f in G[pr] if in_tests(f) == tests}
            ps = {f for f in P[t][pr] if in_tests(f) == tests}
            s = scores(gs, ps)
            g, p, tp = g + s["G"], p + s["P"], tp + s["TP"]
            exact += s["FP"] == 0 and s["FN"] == 0
        return {
            "G": g, "P": p, "TP": tp, "FP": p - tp, "FN": g - tp,
            "precision": tp / p if p else 1.0,
            "recall": tp / g if g else 1.0,
            "f1": 2 * tp / (g + p) if g + p else 1.0,
            "exact_prs": exact,
        }

    sources = {
        t: {
            f"{name}{'' if not skip else '_without_' + OUTLIER}": by_source(t, tests, skip)
            for name, tests in (("benchmark", False), ("test_suite", True))
            for skip in ((), (OUTLIER,))
        }
        for t in tools
    }

    # Timing: per PR, the sum over its pattern files (median of repeats each).
    timing: dict[str, dict[str, float | None]] = {}
    for tool in TIMED:
        if not (outdir / tool).is_dir():
            continue
        timing[tool] = {}
        for pr in prs:
            s = pattern_seconds(outdir, tool, pr)
            timing[tool][pr] = sum(s.values()) if s else None

    stats = read_stats(outdir / "logs" / "stats.log")
    stats_novf = read_stats(outdir / "logs" / "stats-no-value-facts.log")

    # Packs checked (functions whose features may match) and modules read, per
    # pattern and per PR, from run_baseline.py's --summary counts.
    counts_by_tool: dict[str, dict[str, dict[str, int]]] = {}
    for tool in (
        "metaphir-index",
        "ablation-no-value-facts",
        "ablation-no-constraint-prefilter",
    ):
        per_pattern: dict[str, dict[str, int]] = {}
        for pr in prs:
            for stem, fields in pattern_counts(outdir, tool, pr).items():
                per_pattern.setdefault(stem, {}).update(fields)
        counts_by_tool[tool] = per_pattern
    counts = counts_by_tool["metaphir-index"]

    def median_ratio(field: str, total: str) -> float | None:
        values = [
            c[field] / c[total]
            for c in counts.values()
            if c.get(field) is not None and c.get(total)
        ]
        return statistics.median(values) if values else None

    def per_pr_counts(tool: str) -> dict[str, dict[str, int | None]]:
        result: dict[str, dict[str, int | None]] = {}
        for pr in prs:
            packs = files = 0
            total_functions = total_files = None
            have = False
            for pattern in PR_PATTERNS[pr]:
                c = counts_by_tool[tool].get(Path(pattern).stem, {})
                if c:
                    have = True
                packs += c.get("checked") or 0
                files += c.get("files_read") or 0
                total_functions = c.get("total_functions", total_functions)
                total_files = c.get("total_files", total_files)
            result[pr] = {
                "packs": packs if have else None,
                "files": files if have else None,
                "total_functions": total_functions,
                "total_files": total_files,
            }
        return result

    candidate_counts = per_pr_counts("metaphir-index")
    candidate_counts_by_tool = {tool: per_pr_counts(tool) for tool in counts_by_tool}
    # A full scan reads every function and every file.
    candidate_counts_by_tool["metaphir-scan"] = {
        pr: {
            "packs": c["total_functions"],
            "files": c["total_files"],
            "total_functions": c["total_functions"],
            "total_files": c["total_files"],
        }
        for pr, c in candidate_counts.items()
    }

    check_log = outdir / "logs" / "check-index.log"
    check = None
    if check_log.is_file() and (m := re.search(r"(\d+) difference", check_log.read_text())):
        check = int(m.group(1))
    index_log = (outdir / "logs" / "index.log").read_text() if (outdir / "logs" / "index.log").is_file() else ""
    index_secs = re.search(r"in ([\d.]+)s", index_log)
    novf_log = outdir / "logs" / "index-no-value-facts.log"
    novf_secs = re.search(r"seconds=([\d.]+)", novf_log.read_text()) if novf_log.is_file() else None

    gt_timing = read_timing(gt_path / "timing.txt")
    summary = {
        "title": title,
        "provenance": provenance(corpus),
        "rq1": {k: v for k, v in pattern_stats(sorted((REPO / "eval" / "patterns").glob("*.mpir"))).items() if k != "per_pattern"},
        "ground_truth": str(gt_path),
        "ground_truth_cpu_seconds": float(gt_timing.get("gt_seconds", "nan")),
        "per_pr": per_pr,
        "totals": totals,
        "totals_by_source": sources,
        "timing_seconds": timing,
        "candidate_counts": candidate_counts,
        "candidate_counts_by_tool": candidate_counts_by_tool,
        "index": {
            "build_seconds": float(index_secs.group(1)) if index_secs else None,
            "no_value_facts_build_seconds": float(novf_secs.group(1)) if novf_secs else None,
            "check_index_differences": check,
            "median_functions_checked": median_ratio("checked", "total_functions"),
            "median_files_read": median_ratio("files_read", "total_files"),
            "per_pattern": stats,
            "per_pattern_no_value_facts": stats_novf,
            "per_pattern_candidates": counts,
            "per_pattern_candidates_by_tool": counts_by_tool,
        },
        "tool_failures": {t: failures(outdir, t) for t in tools},
    }

    # ----------------------------------------------------------------- md
    md: list[str] = [f"# {title}", ""]
    md += [f"> {n}" for n in notes] + ([""] if notes else [])
    prov = summary["provenance"]
    md += ["## Setup", ""]
    rows = [
        ["MetaphIR", f"`{prov['metaphir_commit']}`"],
        ["LLVM", f"`{prov['llvm_commit']}` + `eval/patches/`"],
    ]
    if "corpus" in prov:
        c = prov["corpus"]
        rows += [
            ["Corpus", f"`{c['path']}`: {c['modules']} modules + {c['test_files']} test files, {c['bytes'] / 1e9:.2f} GB"],
        ]
    if stats:
        any_stats = next(iter(stats.values()))
        if "functions" in any_stats:
            rows.append(["Functions", str(any_stats["functions"][1])])
    m = prov["machine"]
    rows += [
        ["Machine", f"{m['cpu']}, {m['cores']} cores, {m['memory']}, {m['os']}"],
        ["Ground truth", (f"`{rel(gt_path)}`, " if not same_corpus else "")
         + f"{summary['ground_truth_cpu_seconds']:.0f} CPU-seconds (summed per module)"],
        ["Tool failures", ", ".join(f"{TOOL_NAMES[t]} {n}" for t, n in summary["tool_failures"].items())],
    ]
    md += [table(["", ""], rows), ""]

    r1 = summary["rq1"]
    md += [
        "## RQ1: Expressiveness", "",
        f"{r1['patterns']} patterns, {r1['instructions']} instruction lines, "
        f"{r1['constraints']} constraint lines, at most {r1['max_instructions']} "
        "instructions per pattern. Patterns using each feature "
        "(`eval/scripts/pattern_stats.py`):", "",
        table(["Feature", "Patterns"], [[k, str(v)] for k, v in r1["patterns_using"].items()]),
        "",
        "Baseline: see `eval/baselines/EXPRESSIVENESS.md` (daggrep expresses 3 of 23 "
        "patterns exactly).", "",
    ]

    md += ["## RQ2 and RQ4: Accuracy", "",
           "Functions where each fold fires (G) and where each tool's patterns "
           "match (P).", ""]
    header = ["PR", "\\|G\\|"]
    for t in tools:
        header += [f"{TOOL_NAMES[t]} \\|P\\|", "TP", "F1"]
    rows = []
    for pr in prs:
        row = [pr, str(per_pr[pr][tools[0]]["G"])]
        for t in tools:
            s = per_pr[pr][t]
            row += [str(s["P"]), str(s["TP"]), pct(s["f1"])]
        rows.append(row)
    md += [table(header, rows), ""]

    md += ["### Totals", ""]
    rows = []
    for t in tools:
        for scope, s in totals[t].items():
            rows.append([
                TOOL_NAMES[t], scope.replace("_", " "), str(s["G"]), str(s["P"]),
                str(s["TP"]), str(s["FP"]), str(s["FN"]), pct(s["precision"]),
                pct(s["recall"]), pct(s["f1"]), f"{s['exact_prs']}",
            ])
    md += [table(["Tool", "PRs", "\\|G\\|", "\\|P\\|", "TP", "FP", "FN",
                  "Precision", "Recall", "F1", "PRs with F1 100%"], rows), ""]

    md += ["### Benchmark vs test suite", "",
           "The same totals split by where the function comes from: "
           "llvm-opt-benchmark modules, or the upstream InstCombine/InstSimplify "
           "test files. Functions of a PR are scored within each source.", ""]
    rows = []
    for t in tools:
        for scope, s in sources[t].items():
            rows.append([
                TOOL_NAMES[t], scope.replace("_", " "), str(s["G"]), str(s["P"]),
                str(s["TP"]), str(s["FP"]), str(s["FN"]), pct(s["precision"]),
                pct(s["recall"]), pct(s["f1"]), f"{s['exact_prs']}",
            ])
    md += [table(["Tool", "Source", "\\|G\\|", "\\|P\\|", "TP", "FP", "FN",
                  "Precision", "Recall", "F1", "PRs with F1 100%"], rows), ""]

    md += ["## RQ3: Index", ""]
    ix = summary["index"]
    rows = [
        ["Index build", f"{secs(ix['build_seconds'])} s"],
        ["Index build without value facts", f"{secs(ix['no_value_facts_build_seconds'])} s"],
        ["Median functions whose packs are fetched", pct(ix["median_functions_checked"]) if ix["median_functions_checked"] is not None else "—"],
        ["Median modules read", pct(ix["median_files_read"]) if ix["median_files_read"] is not None else "—"],
    ]
    md += [table(["", ""], rows), ""]
    if check is not None:
        md += [f"Matching with the index found the same functions as matching "
               f"without it ({check} differences).", ""]
    if stats:
        def count_cell(name: str, field: str, total: str) -> str:
            c = counts.get(name, {})
            value, whole = c.get(field), c.get(total)
            return f"{value} ({pct(value / whole)})" if value is not None and whole else "—"

        rows = []
        for name in stats:
            rows.append([
                name,
                count_cell(name, "checked", "total_functions"),
                count_cell(name, "files_read", "total_files"),
            ])
        md += ["Left after pruning, per pattern. Packs checked is the number of "
               "functions whose features may match — the packs a published query "
               "fetches; files read is the number of modules it reads.", "",
               table(["Pattern", "Packs checked", "Files read"], rows), ""]

        # Value facts only change the patterns whose constraints read them; the
        # rest are identical, so listing them would hide the effect.
        value_facts = []
        for name in stats:
            c = counts.get(name, {})
            nv_c = counts_by_tool.get("ablation-no-value-facts", {}).get(name, {})
            checked, nv_checked = c.get("checked"), nv_c.get("checked")
            if checked is None or nv_checked is None or checked == nv_checked:
                continue
            value_facts.append([name, str(checked), str(nv_checked)])
        if value_facts:
            unchanged = len(stats) - len(value_facts)
            md += [
                "Value facts change these patterns only; "
                f"the other {unchanged} are unchanged. These patterns' "
                "constraints read value facts, so their counts above cannot be "
                "reproduced without them.", "",
                table(["Pattern", "Packs", "Packs w/o value facts"], value_facts), "",
            ]

    def variant_cell(tool: str, name: str, field: str, total: str) -> str:
        c = counts_by_tool.get(tool, {}).get(name, {})
        value, whole = c.get(field), c.get(total)
        return f"{value} ({pct(value / whole)})" if value is not None and whole else "—"

    variants = (
        "metaphir-index",
        "ablation-no-value-facts",
        "ablation-no-constraint-prefilter",
    )
    if stats and any(counts_by_tool[t] for t in variants[1:]):
        rows = []
        for name in stats:
            rows.append([
                name,
                *(cell for tool in variants for cell in (
                    variant_cell(tool, name, "checked", "total_functions"),
                    variant_cell(tool, name, "files_read", "total_files"),
                )),
            ])
        md += [
            "Candidate filtering by variant. `--no-constraint-prefilter` keeps "
            "the feature prefilter but does not evaluate the variants' "
            "constraints on a candidate's features, so a function passes when "
            "its features can match structurally even if a constraint would "
            "reject every match; it checks more packs. The no-value-facts index "
            "keeps more coarse candidates, but the fine features reject most of "
            "them before packs, so packs and modules read change only where a "
            "constraint reads value facts. A full scan reads every function and "
            "file.",
            "",
            table(
                ["Pattern", "Index packs", "Index files", "No-VF packs", "No-VF files",
                 "No-constraint packs", "No-constraint files"],
                rows,
            ),
            "",
        ]

    md += ["## RQ3 and RQ4: Query time", "",
           "Wall-clock seconds per PR (summed over its pattern files), each run "
           "over the whole corpus with 80 threads or processes, the median of "
           "3 runs. The corpus fits in the machine's page cache, so these are "
           "warm-cache numbers.", ""]
    cols = [t for t in TIMED if t in timing]
    rows = []
    for pr in prs:
        cc = candidate_counts[pr]
        rows.append([
            pr,
            str(cc["packs"]) if cc["packs"] is not None else "—",
            str(cc["files"]) if cc["files"] is not None else "—",
            *(secs(timing[t][pr]) for t in cols),
        ])
    for label, fn in (("median", statistics.median), ("total", sum)):
        packs = [c["packs"] for c in candidate_counts.values() if c["packs"] is not None]
        files = [c["files"] for c in candidate_counts.values() if c["files"] is not None]
        rows.append([
            f"**{label}**",
            str(fn(packs)) if packs else "—",
            str(fn(files)) if files else "—",
            *(
                secs(fn(v)) if (v := [x for x in timing[t].values() if x is not None]) else "—"
                for t in cols
            ),
        ])
    md += [
        "Packs checked and files read are summed over a PR's pattern files "
        "(modules may repeat); they are the candidates a published query reads "
        "for the pattern.", "",
        table(["PR", "Packs checked", "Files read", *(TIMED[t] for t in cols)], rows), "",
    ]

    return "\n".join(md) + "\n", summary


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("outdir", type=Path)
    ap.add_argument("--corpus", type=Path)
    ap.add_argument("--title", default="MetaphIR evaluation")
    ap.add_argument("--note", action="append", default=[])
    ap.add_argument(
        "--gt",
        type=Path,
        help="results directory whose ground truth to score against "
        "(default: <outdir>)",
    )
    ap.add_argument(
        "--gt-dir",
        default=GT_DIR,
        help=f"ground-truth subdirectory of --gt/<outdir> (default: {GT_DIR})",
    )
    ap.add_argument(
        "--suffix",
        default="",
        help="suffix for REPORT<sfx>.md and summary<sfx>.json, e.g. -pipeline",
    )
    args = ap.parse_args()
    md, summary = build(
        args.outdir, args.corpus, args.title, args.note, args.gt, args.gt_dir
    )
    report = args.outdir / f"REPORT{args.suffix}.md"
    summary_path = args.outdir / f"summary{args.suffix}.json"
    report.write_text(md)
    summary_path.write_text(json.dumps(summary, indent=2) + "\n")
    print(f"wrote {report} and {summary_path.name}")


if __name__ == "__main__":
    main()
