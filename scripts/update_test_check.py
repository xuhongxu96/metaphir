#!/usr/bin/env python3
"""Regenerate FileCheck directives in MetaphIR parser tests."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEST_DIR = REPO_ROOT / "test" / "Parser"
RUN_RE = re.compile(r"^\s*(?P<comment>;|#|//)\s*RUN:\s*(?P<command>.*)$")
CHECK_RE = re.compile(r"^\s*(?:;|#|//)\s*CHECK(?:-[A-Z0-9_-]+)?:")
LOCAL_ID_RE = re.compile(r"^\s*%(?P<id>[0-9]+)(?=\s|=)")
TOKEN_ID_RE = re.compile(r"^LocalVarID (?P<id>[0-9]+)$")
POINTER_RE = re.compile(r"\b0x[0-9A-Fa-f]+\b")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[DEFAULT_TEST_DIR],
        help="test files or directories (default: test/Parser)",
    )
    parser.add_argument(
        "--metaphir-lex",
        type=Path,
        help="path to metaphir-lex (otherwise use METAPHIR_LEX, PATH, or build/)",
    )
    return parser.parse_args()


def find_lexer(argument: Path | None) -> Path:
    candidates: list[Path | str] = []
    if argument is not None:
        candidates.append(argument)
    if value := os.environ.get("METAPHIR_LEX"):
        candidates.append(value)
    if value := shutil.which("metaphir-lex"):
        candidates.append(value)
    candidates += [REPO_ROOT / "build" / "tools" / "metaphir-lex",
                   REPO_ROOT / "build" / "metaphir-lex"]
    for candidate in candidates:
        path = Path(candidate).expanduser()
        if path.is_file() and os.access(path, os.X_OK):
            return path.resolve()
    raise SystemExit("could not find metaphir-lex; pass --metaphir-lex PATH")


def collect_files(paths: list[Path]) -> list[Path]:
    files: set[Path] = set()
    for path in paths:
        if path.is_dir():
            files.update(p for p in path.rglob("*") if p.is_file())
        elif path.is_file():
            files.add(path)
        else:
            raise SystemExit(f"test path does not exist: {path}")
    return sorted(files)


def test_kind(lines: list[str], path: Path) -> tuple[str, str]:
    runs = [match for line in lines if (match := RUN_RE.match(line))]
    if not runs:
        print(f"{path}: no RUN directive", file=sys.stderr)
        return "skip", ""
    kinds = {"metaphir-lex" for run in runs if "%metaphir-lex" in run["command"]}
    if len(kinds) != 1 or any("%metaphir-lex" not in run["command"] for run in runs):
        raise ValueError(f"{path}: unsupported or mixed RUN directives")
    return kinds.pop(), runs[0]["comment"]


def lexer_groups(output: str, path: Path) -> list[tuple[str, list[str]]]:
    groups: list[tuple[str, list[str]]] = []
    for token in output.splitlines():
        if match := TOKEN_ID_RE.fullmatch(token):
            groups.append((match["id"], []))
        if not groups:
            raise ValueError(f"{path}: lexer output does not start with LocalVarID")
        # Pointer-valued token details are process-specific and need a regex.
        groups[-1][1].append(POINTER_RE.sub("{{0x[0-9A-Fa-f]+}}", token))
    if not groups:
        raise ValueError(f"{path}: lexer produced no LocalVarID tokens")
    return groups


def update_lexer_test(path: Path, lines: list[str], comment: str, lexer: Path) -> str:
    result = subprocess.run(
        [lexer, path], text=True, capture_output=True, check=False
    )
    # Error-token tests intentionally make the lexer fail after printing the
    # token stream that FileCheck consumes.  Only a failure with no stream is
    # unusable for regeneration.
    if result.returncode and not result.stdout:
        raise ValueError(f"{path}: metaphir-lex failed:\n{result.stderr.rstrip()}")

    groups = lexer_groups(result.stdout, path)
    by_id: dict[str, list[str]] = {}
    for local_id, tokens in groups:
        if local_id in by_id:
            raise ValueError(f"{path}: duplicate LocalVarID {local_id} in lexer output")
        by_id[local_id] = tokens

    clean_lines: list[str] = []
    for line in lines:
        if CHECK_RE.match(line):
            # Old tests commonly separate their CHECK block from the input
            # with a blank line.  Checks generated here belong directly below
            # the corresponding input line.
            while clean_lines and not clean_lines[-1].strip():
                clean_lines.pop()
            continue
        clean_lines.append(line)
    seen: set[str] = set()
    updated: list[str] = []
    emitted_any = False
    for line in clean_lines:
        updated.append(line)
        match = LOCAL_ID_RE.match(line)
        if not match or match["id"] not in by_id:
            continue
        local_id = match["id"]
        if local_id in seen:
            raise ValueError(f"{path}: duplicate input line for LocalVarID {local_id}")
        seen.add(local_id)
        for token in by_id[local_id]:
            directive = "CHECK" if not emitted_any else "CHECK-NEXT"
            updated.append(f"{comment} {directive}: {token}")
            emitted_any = True

    missing = by_id.keys() - seen
    if missing:
        raise ValueError(f"{path}: no input line for LocalVarID {', '.join(sorted(missing))}")
    while updated and not updated[-1].strip():
        updated.pop()
    return "\n".join(updated) + "\n"


def main() -> int:
    args = parse_args()
    lexer: Path | None = None
    changed = 0
    for path in collect_files(args.paths):
        original = path.read_text()
        lines = original.splitlines()
        updated: str | None = None
        try:
            kind, comment = test_kind(lines, path)
            if kind == "metaphir-lex":
                lexer = lexer or find_lexer(args.metaphir_lex)
                updated = update_lexer_test(path, lines, comment, lexer)
            elif kind == "skip":
                continue
            else:
                raise ValueError(f"{path}: unsupported test kind {kind}")
        except ValueError as error:
            print(error, file=sys.stderr)
            return 1
        assert updated is not None
        if updated != original:
            path.write_text(updated)
            changed += 1
            print(f"updated {path}")
    print(f"updated {changed} test(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
