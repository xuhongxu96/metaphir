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
DEFAULT_TEST_DIR = REPO_ROOT / "test"
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
MATCH_TARGET_RE = re.compile(r"^target [0-9]+: @(?P<name>[-a-zA-Z$._0-9]+)$")
LLVM_FUNCTION_RE = re.compile(
    r"^\s*define\b.*@(?P<name>[-a-zA-Z$._0-9]+)\s*\("
)


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


def test_kinds(lines: list[str], path: Path) -> tuple[set[str], str]:
    runs = [match for line in lines if (match := RUN_RE.match(line))]
    if not runs:
        print(f"{path}: no RUN directive", file=sys.stderr)
        return set(), ""
    kinds = {
        kind
        for run in runs
        for kind in ("metaphir-lex", "metaphir-parse", "metaphir-match")
        if f"%{kind}" in run["command"]
    }
    if not kinds:
        raise ValueError(f"{path}: no tool RUN directive")
    return kinds, runs[0]["comment"]


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


def compute_sections(clean_lines: list[str]) -> dict[str, str]:
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
    return sections


def write_sections(temporary_path: Path, sections: dict[str, str]) -> None:
    for name, contents in sections.items():
        output_path = temporary_path / name
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(contents)


def functions_in_input(
    input_path: Path, section_name: str | None, path: Path
) -> list[tuple[str | None, str]]:
    """Collect (section, function-name) pairs from a matcher input, which may be
    an .ll file, a .bc bitcode file, or a directory containing either."""
    inputs: list[Path] = []
    if input_path.is_dir():
        inputs = sorted(
            p for p in input_path.rglob("*") if p.suffix in (".ll", ".bc")
        )
    else:
        inputs = [input_path]
    results: list[tuple[str | None, str]] = []
    for input_file in inputs:
        if input_file.suffix == ".bc":
            proc = subprocess.run(
                ["llvm-dis", str(input_file), "-o", "-"],
                text=True,
                capture_output=True,
                check=False,
            )
            if proc.returncode:
                raise ValueError(
                    f"{path}: llvm-dis failed on {input_file}\n{proc.stderr.rstrip()}"
                )
            text = proc.stdout
        else:
            text = input_file.read_text()
        results.extend(
            (section_name, match["name"])
            for line in text.splitlines()
            if (match := LLVM_FUNCTION_RE.match(line))
        )
    return results


def run_setup_commands(
    lines: list[str], temporary_path: Path, path: Path
) -> None:
    """Execute non-tool RUN commands (mkdir/cp/llvm-as/...) in the temp dir so
    split inputs that are prepared by the RUN lines exist before matching."""
    for line in lines:
        match = RUN_RE.match(line)
        if not match:
            continue
        command = match["command"]
        if any(
            f"%{kind}" in command
            for kind in ("metaphir-lex", "metaphir-parse", "metaphir-match")
        ):
            continue
        if command.strip().startswith("split-file"):
            continue
        command = command.split("|", 1)[0].strip()
        command = command.replace("%t", str(temporary_path)).replace(
            "%S", str(path.parent)
        ).replace("%s", str(path))
        if command.startswith("not "):
            command = command[4:]
        proc = subprocess.run(
            command, shell=True, cwd=str(temporary_path), capture_output=True,
            text=True, check=False,
        )
        if proc.returncode != 0:
            raise ValueError(
                f"{path}: setup command failed: {command}\n{proc.stderr.rstrip()}"
            )


def section_bounds(
    clean_lines: list[str], path: Path, section_name: str | None
) -> tuple[int, int]:
    if section_name is None:
        return 0, len(clean_lines)
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
    return start, end


def gen_parser_checks(
    path: Path,
    clean_lines: list[str],
    comment: str,
    parser: Path,
    temporary_path: Path,
) -> dict[int, list[str]]:
    generated: list[tuple[str | None, str, list[str], int | None]] = []
    runs = [match for line in clean_lines if (match := RUN_RE.match(line))]
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
            raise ValueError(f"{path}: metaphir-parse was expected to {expectation}")
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
        start, end = section_bounds(clean_lines, path, section_name)
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
    return checks_by_line


def gen_matcher_checks(
    path: Path,
    clean_lines: list[str],
    comment: str,
    matcher: Path,
    temporary_path: Path,
) -> tuple[dict[int, list[str]], list[str]]:
    generated: list[tuple[str | None, str, list[str]]] = []
    error_directives: list[str] = []
    for run in (match for line in clean_lines if (match := RUN_RE.match(line))):
        if "%metaphir-match" not in run["command"]:
            continue
        expected_failure = bool(
            re.search(r"\bnot\s+%metaphir-match\b", run["command"])
        )
        invocation = run["command"].split("|", 1)[0].strip()
        invocation = re.sub(
            r"\bnot\s+%metaphir-match\b", "%metaphir-match", invocation
        )
        invocation = invocation.replace("2>&1", "").strip()
        arguments = shlex.split(invocation)
        tool_index = arguments.index("%metaphir-match")
        arguments = arguments[tool_index + 1 :]
        target_arguments = arguments[1:]
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
        if expected_failure:
            if result.returncode == 0:
                raise ValueError(f"{path}: metaphir-match was expected to fail")
            prefix_match = CHECK_PREFIX_RE.search(run["command"])
            prefix = prefix_match["prefix"] if prefix_match else "CHECK"
            output = (result.stdout + result.stderr).splitlines()
            if not output:
                raise ValueError(
                    f"{path}: metaphir-match error run produced no output"
                )
            error_directives.extend(
                f"{comment} "
                f"{prefix if index == 0 else prefix + '-NEXT'}: "
                f"{line}"
                for index, line in enumerate(
                    strip_error_prefix(
                        [POINTER_RE.sub("{{0x[0-9A-Fa-f]+}}", line) for line in output]
                    )
                )
            )
            continue
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
        target_sections = [
            argument[3:] if argument.startswith("%t/") else None
            for argument in target_arguments
        ]
        section_functions: list[tuple[str | None, str]] = []
        for section_name, argument in zip(target_sections, arguments[1:]):
            input_path = (
                path if section_name is None else temporary_path / section_name
            )
            if not input_path.exists():
                raise ValueError(
                    f"{path}: matcher input {argument} does not exist"
                )
            section_functions.extend(
                functions_in_input(input_path, section_name, path)
            )

        target_groups: list[tuple[str, list[str]]] = []
        for line in output:
            if match := MATCH_TARGET_RE.match(line):
                target_groups.append((match["name"], [line]))
            elif target_groups:
                target_groups[-1][1].append(line)
            else:
                raise ValueError(f"{path}: malformed metaphir-match output")
        if len(target_groups) != len(section_functions):
            raise ValueError(
                f"{path}: cannot map matcher targets to LLVM functions"
            )
        for index, ((name, group), (section_name, expected_name)) in enumerate(
            zip(target_groups, section_functions)
        ):
            if name != expected_name:
                raise ValueError(
                    f"{path}: matcher target @{name} does not correspond to "
                    f"LLVM function @{expected_name}"
                )
            directives = [
                f"{comment} "
                f"{prefix if index == 0 and line_index == 0 else prefix + '-NEXT'}: "
                f"{line}"
                for line_index, line in enumerate(group)
            ]
            generated.append((section_name, name, directives))

    checks_by_line: dict[int, list[str]] = {}
    for section_name, function_name, directives in generated:
        definition = next(
            (
                index
                for index, line in enumerate(clean_lines)
                if (match := LLVM_FUNCTION_RE.match(line))
                and match["name"] == function_name
            ),
            None,
        )
        if definition is None:
            raise ValueError(
                f"{path}: no LLVM definition for matcher target @{function_name}"
            )
        function_end = next(
            (
                index
                for index in range(definition + 1, len(clean_lines))
                if clean_lines[index].strip() == "}"
            ),
            None,
        )
        if function_end is None:
            raise ValueError(
                f"{path}: unterminated LLVM definition @{function_name}"
            )
        checks_by_line.setdefault(function_end, []).extend(directives)
    return checks_by_line, error_directives


CHECK_HEAD_RE = re.compile(r"^\s*(?:;|#|//)\s*([A-Za-z0-9_.-]+?)(?::|-NEXT|-SAME|-NOT|-DAG)")
TOOL_ERROR_HEAD_RE = re.compile(
    r"^\s*(?:metaphir-[a-z0-9]+|opt):\s*\S+:\d+:\d+:\s*(?:error:)"
)


def directive_prefix(directive: str) -> str:
    match = CHECK_HEAD_RE.match(directive)
    return match.group(1) if match else ""


def strip_error_prefix(lines: list[str]) -> list[str]:
    """Drop the volatile '<tool>: <path>:<line>:<col>: ' prefix from tool error
    diagnostics so generated CHECKs don't embed the temp path. Only lines that
    actually look like a tool diagnostic are rewritten."""
    result: list[str] = []
    for line in lines:
        if TOOL_ERROR_HEAD_RE.match(line):
            line = line[line.find("error:"):]
        result.append(line)
    return result


def separate_prefix_groups(directives: list[str]) -> list[str]:
    """Insert a blank line between consecutive directives with different prefixes."""
    block: list[str] = []
    last: str | None = None
    for directive in directives:
        prefix = directive_prefix(directive)
        if last is not None and prefix != last:
            block.append("")
        block.append(directive)
        last = prefix
    return block


def strip_inter_check_blanks(lines: list[str]) -> list[str]:
    """Drop blank lines adjacent to a CHECK directive so regeneration is
    idempotent (separator blanks from a previous run are not doubled)."""
    nonblank = [index for index, line in enumerate(lines) if line.strip()]
    check = {index for index, line in enumerate(lines) if CHECK_RE.match(line)}
    drop: set[int] = set()
    for index, line in enumerate(lines):
        if line.strip():
            continue
        prev = next((j for j in reversed(nonblank) if j < index), None)
        nxt = next((j for j in nonblank if j > index), None)
        if prev in check or nxt in check:
            drop.add(index)
    return [line for index, line in enumerate(lines) if index not in drop]


def apply_checks(
    clean_lines: list[str],
    checks_by_line: dict[int, list[str]],
    error_directives: list[str],
) -> str:
    for target in sorted(checks_by_line, reverse=True):
        clean_lines[target + 1 : target + 1] = separate_prefix_groups(
            checks_by_line[target]
        )
    if error_directives:
        if clean_lines and clean_lines[-1].strip():
            clean_lines.append("")
        clean_lines.extend(separate_prefix_groups(error_directives))
    while clean_lines and not clean_lines[-1].strip():
        clean_lines.pop()
    return "\n".join(separate_check_blocks(clean_lines)) + "\n"


def update_test(
    path: Path, lines: list[str], comment: str, kinds: set[str], tools: dict[str, Path]
) -> str:
    lines = strip_inter_check_blanks(lines)
    clean_lines = [line for line in lines if not CHECK_RE.match(line)]
    checks_by_line: dict[int, list[str]] = {}
    error_directives: list[str] = []
    if kinds <= {"metaphir-parse", "metaphir-match"}:
        sections = compute_sections(clean_lines)
        with tempfile.TemporaryDirectory() as temporary:
            temporary_path = Path(temporary)
            write_sections(temporary_path, sections)
            run_setup_commands(lines, temporary_path, path)
            if "metaphir-parse" in kinds:
                parser_checks = gen_parser_checks(
                    path, clean_lines, comment, tools["parser"], temporary_path
                )
                for target, directives in parser_checks.items():
                    checks_by_line.setdefault(target, []).extend(directives)
            if "metaphir-match" in kinds:
                matcher_checks, matcher_errors = gen_matcher_checks(
                    path, clean_lines, comment, tools["matcher"], temporary_path
                )
                for target, directives in matcher_checks.items():
                    checks_by_line.setdefault(target, []).extend(directives)
                error_directives.extend(matcher_errors)
        return apply_checks(clean_lines, checks_by_line, error_directives)
    raise ValueError(
        f"{path}: unsupported combination of tools: {', '.join(sorted(kinds))}"
    )


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
            kinds, comment = test_kinds(lines, path)
            if not kinds:
                continue
            if kinds == {"metaphir-lex"}:
                lexer = lexer or find_tool(
                    "metaphir-lex", args.metaphir_lex, "METAPHIR_LEX"
                )
                updated = update_lexer_test(path, lines, comment, lexer)
            else:
                tools: dict[str, Path] = {}
                if "metaphir-parse" in kinds:
                    tools["parser"] = parser or find_tool(
                        "metaphir-parse", args.metaphir_parse, "METAPHIR_PARSE"
                    )
                if "metaphir-match" in kinds:
                    tools["matcher"] = matcher or find_tool(
                        "metaphir-match", args.metaphir_match, "METAPHIR_MATCH"
                    )
                if "metaphir-lex" in kinds:
                    raise ValueError(
                        f"{path}: lexer tests cannot be combined with other tools"
                    )
                updated = update_test(path, lines, comment, kinds, tools)
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
