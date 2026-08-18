#!/usr/bin/env python3
"""Regenerate FileCheck directives in MetaphIR parser tests."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEST_DIR = REPO_ROOT / "test" / "Parser"
RUN_RE = re.compile(r"^\s*(?P<comment>;|#|//)\s*RUN:\s*(?P<command>.*)$")
CHECK_RE = re.compile(
    r"^\s*(?:;|#|//)\s*(?!RUN:)[A-Z][A-Z0-9_-]*(?:-(?:NEXT|SAME|DAG|NOT))?:"
)
LOCAL_RE = re.compile(r"^\s*%(?P<name>[-a-zA-Z$._0-9]+)(?=\s|=)")
TOKEN_LOCAL_RE = re.compile(r"^LocalVar(?:ID)? (?P<name>\S+)$")
POINTER_RE = re.compile(r"\b0x[0-9A-Fa-f]+\b")
SPLIT_RE = re.compile(r"^\s*(?:;|#|//)---\s+(?P<name>\S+)\s*$")
PARSER_INPUT_RE = re.compile(r"%metaphir-parse\s+(?P<input>%s|%t/\S+)")
CHECK_PREFIX_RE = re.compile(r"--check-prefix(?:=|\s+)(?P<prefix>[A-Z0-9_-]+)")
ERROR_RE = re.compile(r":(?P<line>[0-9]+):[0-9]+: error: (?P<message>.*)$")


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
    parser.add_argument(
        "--metaphir-parse",
        type=Path,
        help="path to metaphir-parse (otherwise use METAPHIR_PARSE, PATH, or build/)",
    )
    parser.add_argument(
        "--metaphir-match",
        type=Path,
        help="path to metaphir-match (otherwise use METAPHIR_MATCH, PATH, or build/)",
    )
    return parser.parse_args()


def find_tool(name: str, argument: Path | None, environment: str) -> Path:
    candidates: list[Path | str] = []
    if argument is not None:
        candidates.append(argument)
    if value := os.environ.get(environment):
        candidates.append(value)
    if value := shutil.which(name):
        candidates.append(value)
    candidates += [
        REPO_ROOT / "build" / "tools" / name,
        REPO_ROOT / "build" / name,
    ]
    for candidate in candidates:
        path = Path(candidate).expanduser()
        if path.is_file() and os.access(path, os.X_OK):
            return path.resolve()
    option = name.replace("metaphir-", "--metaphir-")
    raise SystemExit(f"could not find {name}; pass {option} PATH")


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
    tool_runs = [
        run
        for run in runs
        if any(
            f"%{kind}" in run["command"]
            for kind in ("metaphir-lex", "metaphir-parse", "metaphir-match")
        )
    ]
    kinds = {
        kind
        for run in tool_runs
        for kind in ("metaphir-lex", "metaphir-parse", "metaphir-match")
        if f"%{kind}" in run["command"]
    }
    if len(kinds) != 1 or any(
        not any(f"%{kind}" in run["command"] for kind in kinds) for run in tool_runs
    ):
        raise ValueError(f"{path}: unsupported or mixed RUN directives")
    return kinds.pop(), runs[0]["comment"]


def lexer_groups(output: str, path: Path) -> list[tuple[str | None, list[str]]]:
    groups: list[tuple[str | None, list[str]]] = []
    tokens = output.splitlines()
    for index, token in enumerate(tokens):
        if (match := TOKEN_LOCAL_RE.fullmatch(token)) and (
            index + 1 < len(tokens) and tokens[index + 1] == "equal"
        ):
            groups.append((match["name"], []))
        if not groups:
            groups.append((None, []))
        # Pointer-valued token details are process-specific and need a regex.
        groups[-1][1].append(POINTER_RE.sub("{{0x[0-9A-Fa-f]+}}", token))
    if not groups:
        raise ValueError(f"{path}: lexer produced no tokens")
    return groups


def separate_check_blocks(lines: list[str]) -> list[str]:
    separated: list[str] = []
    for index, line in enumerate(lines):
        separated.append(line)
        if not CHECK_RE.match(line):
            continue
        next_line = lines[index + 1] if index + 1 < len(lines) else None
        if (
            next_line is not None
            and next_line.strip()
            and not CHECK_RE.match(next_line)
        ):
            separated.append("")
    return separated


def update_lexer_test(path: Path, lines: list[str], comment: str, lexer: Path) -> str:
    result = subprocess.run([lexer, path], text=True, capture_output=True, check=False)
    # Error-token tests intentionally make the lexer fail after printing the
    # token stream that FileCheck consumes.  Only a failure with no stream is
    # unusable for regeneration.
    if result.returncode and not result.stdout:
        raise ValueError(f"{path}: metaphir-lex failed:\n{result.stderr.rstrip()}")

    groups = lexer_groups(result.stdout, path)
    by_name: dict[str, list[str]] = {}
    anonymous: list[str] | None = None
    for local_name, tokens in groups:
        if local_name is None:
            anonymous = tokens
            continue
        if local_name in by_name:
            raise ValueError(f"{path}: duplicate local %{local_name} in lexer output")
        by_name[local_name] = tokens

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
    index = 0
    while index < len(clean_lines):
        line = clean_lines[index]
        updated.append(line)
        match = LOCAL_RE.match(line)
        if not match or match["name"] not in by_name:
            index += 1
            continue
        local_name = match["name"]
        if local_name in seen:
            raise ValueError(f"{path}: duplicate input line for local %{local_name}")
        seen.add(local_name)
        while index + 1 < len(clean_lines) and clean_lines[
            index + 1
        ].lstrip().startswith(";;"):
            index += 1
            updated.append(clean_lines[index])
        for token in by_name[local_name]:
            directive = "CHECK" if not emitted_any else "CHECK-NEXT"
            updated.append(f"{comment} {directive}: {token}")
            emitted_any = True
        index += 1

    missing = by_name.keys() - seen
    if missing:
        raise ValueError(
            f"{path}: no input line for local %{', %'.join(sorted(missing))}"
        )
    if anonymous is not None:
        while updated and not updated[-1].strip():
            updated.pop()
        for token in anonymous:
            directive = "CHECK" if not emitted_any else "CHECK-NEXT"
            updated.append(f"{comment} {directive}: {token}")
            emitted_any = True
    while updated and not updated[-1].strip():
        updated.pop()
    return "\n".join(separate_check_blocks(updated)) + "\n"


def update_parser_test(path: Path, lines: list[str], comment: str, parser: Path) -> str:
    clean_lines = [line for line in lines if not CHECK_RE.match(line)]
    sections: dict[str, str] = {}
    current_section: str | None = None
    section_lines: list[str] = []
    for line in clean_lines:
        if match := SPLIT_RE.match(line):
            if current_section is not None:
                sections[current_section] = "\n".join(section_lines) + "\n"
            current_section = match["name"]
            section_lines = []
        elif current_section is not None:
            section_lines.append(line)
    if current_section is not None:
        sections[current_section] = "\n".join(section_lines) + "\n"

    generated: list[tuple[str | None, str, list[str], int | None]] = []
    runs = [match for line in lines if (match := RUN_RE.match(line))]
    with tempfile.TemporaryDirectory() as temporary:
        temporary_path = Path(temporary)
        for name, contents in sections.items():
            (temporary_path / name).write_text(contents)
        for run in runs:
            command = run["command"]
            input_match = PARSER_INPUT_RE.search(command)
            if input_match is None:
                continue
            input_name = input_match["input"]
            section_name = None if input_name == "%s" else input_name[3:]
            input_path = path if section_name is None else temporary_path / section_name
            if not input_path.is_file():
                raise ValueError(f"{path}: split input {input_name} does not exist")
            expected_failure = bool(re.search(r"\bnot\s+%metaphir-parse\b", command))
            result = subprocess.run(
                [parser, input_path], text=True, capture_output=True, check=False
            )
            if expected_failure == (result.returncode == 0):
                expectation = "fail" if expected_failure else "succeed"
                raise ValueError(
                    f"{path}: metaphir-parse was expected to {expectation}"
                )
            if expected_failure:
                diagnostics = [
                    (int(match["line"]), match["message"])
                    for line in result.stderr.splitlines()
                    if (match := ERROR_RE.search(line))
                ]
                output = [message for _, message in diagnostics]
                diagnostic_line = diagnostics[0][0] if diagnostics else None
            else:
                output = result.stdout.splitlines()
                diagnostic_line = None
            if not output:
                raise ValueError(f"{path}: metaphir-parse produced no checkable output")
            output = [POINTER_RE.sub("{{0x[0-9A-Fa-f]+}}", line) for line in output]
            prefix_match = CHECK_PREFIX_RE.search(command)
            prefix = prefix_match["prefix"] if prefix_match else "CHECK"
            generated.append((section_name, prefix, output, diagnostic_line))

    checks_by_line: dict[int, list[str]] = {}
    for section_name, prefix, output, diagnostic_line in generated:
        if section_name is None:
            start = 0
            end = len(clean_lines)
        else:
            marker = next(
                (
                    index
                    for index, line in enumerate(clean_lines)
                    if (match := SPLIT_RE.match(line)) and match["name"] == section_name
                ),
                None,
            )
            if marker is None:
                raise ValueError(f"{path}: no section marker for {section_name}")
            start = marker + 1
            end = next(
                (
                    index
                    for index in range(start, len(clean_lines))
                    if SPLIT_RE.match(clean_lines[index])
                ),
                len(clean_lines),
            )

        if diagnostic_line is not None:
            targets = [start + diagnostic_line - 1] * len(output)
        else:
            instruction_lines = [
                index
                for index in range(start, end)
                if clean_lines[index].strip()
                and not clean_lines[index].lstrip().startswith((";", "#", "//"))
            ]
            constraint_lines = [
                index
                for index in range(start, end)
                if clean_lines[index].lstrip().startswith(";;")
            ]
            pattern_output = [line for line in output if line.startswith("pattern ")]
            constraint_output = [
                line for line in output if line.startswith("constraint ")
            ]
            meta_output = [line for line in output if line.startswith("meta ")]
            instruction_output = [
                line
                for line in output
                if not line.startswith(("pattern ", "constraint ", "meta "))
            ]
            if len(instruction_output) != len(instruction_lines):
                raise ValueError(f"{path}: cannot map parser instructions to input")
            if len(constraint_output) != len(constraint_lines):
                raise ValueError(f"{path}: cannot map parser constraints to input")
            if not instruction_lines:
                raise ValueError(f"{path}: parser test has no instruction input")
            trailing_target = (
                constraint_lines[-1] if constraint_lines else instruction_lines[-1]
            )
            placed = (
                [(instruction_lines[0], line) for line in pattern_output]
                + list(zip(instruction_lines, instruction_output))
                + list(zip(constraint_lines, constraint_output))
                + [(trailing_target, line) for line in meta_output]
            )
            output = [line for _, line in placed]
            targets = [target for target, _ in placed]

        for index, (target, output_line) in enumerate(zip(targets, output)):
            directive = prefix if index == 0 else prefix + "-NEXT"
            checks_by_line.setdefault(target, []).append(
                f"{comment} {directive}: {output_line}"
            )

    for target in sorted(checks_by_line, reverse=True):
        clean_lines[target + 1 : target + 1] = checks_by_line[target]
    while clean_lines and not clean_lines[-1].strip():
        clean_lines.pop()
    return "\n".join(separate_check_blocks(clean_lines)) + "\n"


def update_matcher_test(
    path: Path, lines: list[str], comment: str, matcher: Path
) -> str:
    clean_lines = [line for line in lines if not CHECK_RE.match(line)]
    sections: dict[str, str] = {}
    current_section: str | None = None
    section_lines: list[str] = []
    for line in clean_lines:
        if match := SPLIT_RE.match(line):
            if current_section is not None:
                sections[current_section] = "\n".join(section_lines) + "\n"
            current_section = match["name"]
            section_lines = []
        elif current_section is not None:
            section_lines.append(line)
    if current_section is not None:
        sections[current_section] = "\n".join(section_lines) + "\n"

    generated: list[tuple[str | None, str, list[str]]] = []
    with tempfile.TemporaryDirectory() as temporary:
        temporary_path = Path(temporary)
        for name, contents in sections.items():
            output_path = temporary_path / name
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(contents)

        for run in (match for line in lines if (match := RUN_RE.match(line))):
            if "%metaphir-match" not in run["command"]:
                continue
            invocation = run["command"].split("|", 1)[0].strip()
            arguments = shlex.split(invocation)
            tool_index = arguments.index("%metaphir-match")
            arguments = arguments[tool_index + 1 :]
            pattern_argument = arguments[0]
            section_name = (
                pattern_argument[3:] if pattern_argument.startswith("%t/") else None
            )
            arguments = [
                str(path)
                if argument == "%s"
                else argument.replace("%S", str(path.parent)).replace(
                    "%t", str(temporary_path)
                )
                for argument in arguments
            ]
            result = subprocess.run(
                [matcher, *arguments], text=True, capture_output=True, check=False
            )
            if result.returncode:
                raise ValueError(
                    f"{path}: metaphir-match failed:\n{result.stderr.rstrip()}"
                )
            output = result.stdout.splitlines()
            if not output:
                raise ValueError(
                    f"{path}: metaphir-match produced no checkable output"
                )
            prefix_match = CHECK_PREFIX_RE.search(run["command"])
            prefix = prefix_match["prefix"] if prefix_match else "CHECK"
            generated.append((section_name, prefix, output))

    checks_by_line: dict[int, list[str]] = {}
    for section_name, prefix, output in generated:
        if section_name is None:
            start = 0
            end = len(clean_lines)
        else:
            marker = next(
                (
                    index
                    for index, line in enumerate(clean_lines)
                    if (match := SPLIT_RE.match(line)) and match["name"] == section_name
                ),
                None,
            )
            if marker is None:
                raise ValueError(f"{path}: no section marker for {section_name}")
            start = marker + 1
            end = next(
                (
                    index
                    for index in range(start, len(clean_lines))
                    if SPLIT_RE.match(clean_lines[index])
                ),
                len(clean_lines),
            )
        input_lines = [
            index
            for index in range(start, end)
            if clean_lines[index].strip()
            and not clean_lines[index].lstrip().startswith((";", "#", "//"))
        ]
        if not input_lines:
            raise ValueError(f"{path}: matcher pattern has no input")
        checks_by_line.setdefault(input_lines[-1], []).extend(
            f"{comment} {prefix if index == 0 else prefix + '-NEXT'}: {line}"
            for index, line in enumerate(output)
        )

    for target in sorted(checks_by_line, reverse=True):
        clean_lines[target + 1 : target + 1] = checks_by_line[target]
    while clean_lines and not clean_lines[-1].strip():
        clean_lines.pop()
    return "\n".join(separate_check_blocks(clean_lines)) + "\n"


def main() -> int:
    args = parse_args()
    lexer: Path | None = None
    parser: Path | None = None
    matcher: Path | None = None
    changed = 0
    for path in collect_files(args.paths):
        original = path.read_text()
        lines = original.splitlines()
        updated: str | None = None
        try:
            kind, comment = test_kind(lines, path)
            if kind == "metaphir-lex":
                lexer = lexer or find_tool(
                    "metaphir-lex", args.metaphir_lex, "METAPHIR_LEX"
                )
                updated = update_lexer_test(path, lines, comment, lexer)
            elif kind == "metaphir-parse":
                parser = parser or find_tool(
                    "metaphir-parse", args.metaphir_parse, "METAPHIR_PARSE"
                )
                updated = update_parser_test(path, lines, comment, parser)
            elif kind == "metaphir-match":
                matcher = matcher or find_tool(
                    "metaphir-match", args.metaphir_match, "METAPHIR_MATCH"
                )
                updated = update_matcher_test(path, lines, comment, matcher)
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
