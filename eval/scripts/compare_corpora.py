#!/usr/bin/env python3
"""Compare the three evaluation corpora, direct and real scenario.

Each corpus's ``summary.json`` is the direct score (its own single-instcombine
GT); ``summary-pipeline.json`` is the real-scenario score (the e2e O2 run on
original).  The best real-scenario F1 (without the pr204089 outlier, matching
the reports' primary totals) is the website's default corpus.

  compare_corpora.py [--json] [--best] [--update-config web/public/config.json]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from corpora import CORPORA


def load(path: Path) -> dict | None:
    return json.loads(path.read_text()) if path.is_file() else None


def f1(summary: dict | None, which: str = "without_pr204089") -> float | None:
    if summary is None:
        return None
    return summary.get("totals", {}).get("metaphir-index", {}).get(which, {}).get("f1")


def pct(value: float | None) -> str:
    return "—" if value is None else f"{100 * value:.2f}%"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="print JSON instead of a table")
    ap.add_argument(
        "--best", action="store_true", help="print only the best corpus id"
    )
    ap.add_argument(
        "--update-config",
        type=Path,
        help="set the config's default to the best real-scenario corpus",
    )
    args = ap.parse_args()

    rows = []
    for name, corpus in CORPORA.items():
        direct = load(corpus.results / "summary.json")
        pipeline = load(corpus.results / "summary-pipeline.json")
        rows.append(
            {
                "corpus": name,
                "direct_all": f1(direct, "all"),
                "direct_without_outlier": f1(direct),
                "pipeline_all": f1(pipeline, "all"),
                "pipeline_without_outlier": f1(pipeline),
            }
        )

    scored = [r for r in rows if r["pipeline_without_outlier"] is not None]
    best = (
        max(scored, key=lambda r: r["pipeline_without_outlier"])["corpus"]
        if scored
        else None
    )

    if args.best:
        if best is None:
            sys.exit("no real-scenario summary found")
        print(best)
        return 0

    if args.json:
        print(json.dumps({"rows": rows, "best": best}, indent=2))
    else:
        print("| Corpus | Direct F1 | Direct F1 (no pr204089) | Real-scenario F1 | Real-scenario F1 (no pr204089) |")
        print("|---|---:|---:|---:|---:|")
        for r in rows:
            print(
                f"| {r['corpus']} | {pct(r['direct_all'])} | "
                f"{pct(r['direct_without_outlier'])} | {pct(r['pipeline_all'])} | "
                f"{pct(r['pipeline_without_outlier'])} |"
            )
        print(f"\nBest real scenario: {best}" if best else "\nNo real-scenario summaries.")

    if args.update_config:
        if best is None:
            sys.exit("refusing to update the config without a real-scenario summary")
        config = json.loads(args.update_config.read_text())
        if "corpora" not in config:
            sys.exit(f"{args.update_config} has no corpora list")
        config["default"] = best
        args.update_config.write_text(json.dumps(config, indent=2) + "\n")
        print(f"default = {best} in {args.update_config}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
