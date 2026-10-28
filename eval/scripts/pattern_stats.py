#!/usr/bin/env python3
"""Count what the evaluation patterns use (RQ1).

Reads eval/patterns/*.mpir and the standard library, and prints, as JSON, the
size of the patterns and how many of them use each language feature.

    pattern_stats.py [--patterns <dir>]
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
STDLIB = REPO / "metaphir" / "StdLib" / "stdlib.mpir"

# Directives are written as constraint lines but configure the matcher.
DIRECTIVES = ("treatIntAsVec",)
# Metaflags and constraint functions that ask LLVM's value tracking.
VALUE_TRACKING = re.compile(
    r":known\w+|:notUndef|:notPoison|isKnown\w+|isGuaranteedNotToBe\w+|"
    r"noOverflow\(|inSignedRange\(|computeKnownBits"
)


def stdlib_names() -> tuple[set[str], set[str]]:
    """The composites and the metaflags the standard library defines."""
    text = STDLIB.read_text()
    composites = set(re.findall(r"^match(?::\w+)*\s+(\w+)", text, re.M))
    metaflags = set(re.findall(r"^metaflag(?::\w+)*\s+:(\w+)", text, re.M))
    return composites, metaflags


def stats(patterns: list[Path]) -> dict[str, object]:
    composites, metaflags = stdlib_names()
    # Built-in constant classes, besides the ones the standard library defines.
    constant_classes = {
        m for m in metaflags if m not in {"s", "su"} and not m.startswith(
            ("known", "not")
        )
    } | {"apIntAllowPoison", "lowBitMask", "constantInt", "odd", "allOnes"}

    per_pattern: dict[str, dict[str, object]] = {}
    uses: dict[str, int] = {
        "constant_class": 0,
        "commutative": 0,
        "one_use": 0,
        "stdlib_composite": 0,
        "value_tracking": 0,
        "intrinsic": 0,
        "own_composite": 0,
        "or_self": 0,
    }
    for path in patterns:
        insts = constraints = 0
        body_lines = []
        in_def = 0
        for raw in path.read_text().splitlines():
            line = raw.strip()
            if not line or (line.startswith(";") and not line.startswith(";;")):
                continue
            if line.startswith(";;"):
                if not line[2:].strip().startswith(DIRECTIVES):
                    constraints += 1
                body_lines.append(line)
                continue
            if line.startswith("match"):
                in_def += 1
            if in_def:
                if line.startswith("}") and not line.startswith("} or"):
                    in_def -= 1
                # A pattern's own composite counts its alternatives' lines.
                insts += line.startswith("%")
                body_lines.append(line)
                continue
            if line.startswith("%"):
                insts += 1
            body_lines.append(line)
        text = "\n".join(body_lines)
        tokens = set(re.findall(r":(\w+)", text))
        opcodes = set(re.findall(r"=\s*(\w+)", text))
        feats = {
            "constant_class": bool(tokens & constant_classes),
            "commutative": "c" in tokens,
            "one_use": bool(tokens & {"s", "su"}) or "hasOneUse" in text,
            "stdlib_composite": bool(opcodes & composites),
            "value_tracking": bool(VALUE_TRACKING.search(text)),
            "intrinsic": "@llvm." in text,
            "own_composite": bool(re.search(r"^match", text, re.M)),
            "or_self": "o" in tokens,
        }
        for k, v in feats.items():
            uses[k] += v
        per_pattern[path.stem] = {
            "instructions": insts,
            "constraints": constraints,
            **{k: v for k, v in feats.items() if v},
        }
    return {
        "patterns": len(patterns),
        "instructions": sum(p["instructions"] for p in per_pattern.values()),
        "constraints": sum(p["constraints"] for p in per_pattern.values()),
        "max_instructions": max(p["instructions"] for p in per_pattern.values()),
        "patterns_using": uses,
        "per_pattern": per_pattern,
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--patterns", type=Path, default=REPO / "eval" / "patterns")
    args = ap.parse_args()
    print(json.dumps(stats(sorted(args.patterns.glob("*.mpir"))), indent=2))


if __name__ == "__main__":
    main()
