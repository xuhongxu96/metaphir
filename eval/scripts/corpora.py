#!/usr/bin/env python3
"""The evaluation corpora, their paths, and their ground-truth references.

Three cut points:

  original         raw original/*.bc, no opt
  thinlto-prelink  opt -passes='thinlto-pre-link<O2>', evaluated folds disabled
  o2-final         opt -passes='default<O2>', evaluated folds disabled

Each corpus is scored twice: direct (its own ``gt/``) and real scenario (the
e2e ``default<O2>`` run on the original corpus, ``original/gt-pipeline``).

  corpora.py get <name> <field>     print one value (for run_all.sh)
  corpora.py list                   list the corpora
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EVAL = REPO / "eval"


@dataclass(frozen=True)
class Corpus:
    name: str
    kind: str
    passes: str | None
    corpus: Path
    index: Path
    results: Path
    gt_pipeline_results: Path
    gt_pipeline_dir: str = "gt-pipeline"

    def field(self, name: str) -> str:
        value = getattr(self, name)
        if value is None:
            return ""
        return str(value)


def _corpus(name: str, kind: str, passes: str | None) -> Corpus:
    return Corpus(
        name=name,
        kind=kind,
        passes=passes,
        corpus=EVAL / f"corpus-{name}",
        index=EVAL / f"corpus-{name}.mpidx",
        results=EVAL / "results" / name,
        gt_pipeline_results=EVAL / "results" / "original",
    )


CORPORA: dict[str, Corpus] = {
    "original": _corpus("original", "original", None),
    "thinlto-prelink": _corpus(
        "thinlto-prelink", "thinlto-prelink", "thinlto-pre-link<O2>"
    ),
    "o2-final": _corpus("o2-final", "o2-final", "default<O2>"),
}

FIELDS = tuple(Corpus.__dataclass_fields__)


def get(name: str) -> Corpus:
    try:
        return CORPORA[name]
    except KeyError:
        raise SystemExit(
            f"unknown corpus {name!r}; choose from {', '.join(CORPORA)}"
        ) from None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="command", required=True)
    g = sub.add_parser("get", help="print one field of a corpus")
    g.add_argument("name", choices=sorted(CORPORA))
    g.add_argument("field", choices=FIELDS)
    sub.add_parser("list", help="list the corpora")
    args = ap.parse_args()

    if args.command == "list":
        for name, corpus in CORPORA.items():
            print(f"{name}\t{corpus.corpus}\t{corpus.index}\t{corpus.results}")
        return 0
    print(get(args.name).field(args.field))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
