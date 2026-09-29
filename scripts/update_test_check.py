#!/usr/bin/env python3
"""Regenerate FileCheck directives in MetaphIR parser and matcher tests."""

from __future__ import annotations

import argparse
import collections
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Regular Expressions & Constants
# ---------------------------------------------------------------------------

RUN_RE = re.compile(r"^\s*(?P<comment>;|#|//)\s*RUN:\s*(?P<command>.*)$")
CHECK_RE = re.compile(
    r"^\s*(?:;|#|//)\s*(?!RUN:)[A-Z][A-Z0-9_-]*(?:-(?:NEXT|SAME|DAG|NOT))?:"
)
CHECK_HEAD_RE = re.compile(
    r"^\s*(?:;|#|//)\s*([A-Za-z0-9_.-]+?)(?::|-NEXT|-SAME|-NOT|-DAG)"
)
CHECK_PREFIX_RE = re.compile(
    r"--check-prefix(?:es)?(?:=|\s+)(?P<prefix>[A-Za-z0-9_-]+)"
)
POINTER_RE = re.compile(r"\b0x[0-9A-Fa-f]+\b")
SPLIT_RE = re.compile(r"^\s*(?:;|#|//)---\s+(?P<name>\S+)\s*$")
PARSER_INPUT_RE = re.compile(r"%metaphir-parse\s+(?P<input>%s|%t/\S+)")
ERROR_RE = re.compile(r":(?P<line>[0-9]+):[0-9]+: error: (?P<message>.*)$")
WARNING_RE = re.compile(r":(?P<line>[0-9]+):[0-9]+: warning: (?P<message>.*)$")
TOOL_ERROR_HEAD_RE = re.compile(
    r"^\s*(?:\S*/)?(?:metaphir-[a-z0-9]+|opt):\s*\S+:\d+:\d+:\s*(?:error:)"
)
MATCH_TARGET_RE = re.compile(r"^target [0-9]+: @(?P<name>[-a-zA-Z$._0-9]+)$")
LLVM_FUNCTION_RE = re.compile(r"^\s*define\b.*@(?P<name>[-a-zA-Z$._0-9]+)\s*\(")

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEST_DIR = REPO_ROOT / "test"
TOOLS = ("metaphir-lex", "metaphir-parse", "metaphir-match")
# lit (test/lit.cfg.py) only runs .ll files.
TEST_EXTENSIONS = {".ll"}
# Tests whose CHECK lines are maintained by hand carry this marker.
MANUAL_MARKER = "NOTE: CHECK lines are written by hand"


# ---------------------------------------------------------------------------
# Structured Data
# ---------------------------------------------------------------------------


@dataclass
class Diagnostic:
    line: int
    message: str


@dataclass
class ParserRun:
    """One `%metaphir-parse` invocation and the checks it produces."""

    section: str | None
    prefix: str
    output: list[str] = field(default_factory=list)
    diagnostic_line: int | None = None
    warnings: list[Diagnostic] = field(default_factory=list)


@dataclass
class SectionFunction:
    section: str | None
    function: str


@dataclass
class TargetGroup:
    name: str
    lines: list[str] = field(default_factory=list)


@dataclass
class MatcherGroup:
    """One target function's CHECK directives from a matcher run."""

    section: str | None
    function: str
    directives: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Formatting & Text Helpers
# ---------------------------------------------------------------------------


def directive_prefix(directive: str) -> str:
    match = CHECK_HEAD_RE.match(directive)
    return match.group(1) if match else ""


def get_check_prefix(command: str) -> str:
    """The prefix generated checks use: the first --check-prefix(es) value."""
    match = CHECK_PREFIX_RE.search(command)
    return match["prefix"] if match else "CHECK"


def substitute_vars(text: str, path: Path, temp_path: Path) -> str:
    return (
        text.replace("%t", str(temp_path))
        .replace("%S", str(path.parent))
        .replace("%s", str(path))
    )


def substitute_shell_vars(text: str, path: Path, temp_path: Path) -> str:
    """Like substitute_vars, but quotes the paths for use in a shell command."""
    return (
        text.replace("%t", shlex.quote(str(temp_path)))
        .replace("%S", shlex.quote(str(path.parent)))
        .replace("%s", shlex.quote(str(path)))
    )


def first_pipeline_stage(command: str) -> str:
    """Return the command before the first unquoted pipe (`|`, not `||`)."""
    quote: str | None = None
    index = 0
    while index < len(command):
        char = command[index]
        if quote:
            if char == "\\" and quote == '"':
                index += 1
            elif char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char == "\\":
            index += 1
        elif char == "|":
            if command.startswith("||", index):
                index += 2
                continue
            return command[:index].strip()
        index += 1
    return command.strip()


def sanitize_pointers(text: str) -> str:
    return POINTER_RE.sub("{{0x[0-9A-Fa-f]+}}", text)


def format_directives(
    lines: list[str], prefix: str, comment: str, is_first: bool = True
) -> list[str]:
    return [
        f"{comment} {prefix if is_first and i == 0 else prefix + '-NEXT'}: {line}"
        for i, line in enumerate(lines)
    ]


def strip_error_prefix(lines: list[str]) -> list[str]:
    """Drop the volatile '<tool>: <path>:<line>:<col>: ' prefix from tool error
    diagnostics so generated CHECKs don't embed the temp path."""
    result: list[str] = []
    for line in lines:
        if TOOL_ERROR_HEAD_RE.match(line):
            result.append(line[line.find("error:") :])
        else:
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
    """Drop blank lines adjacent to a CHECK directive so regeneration is idempotent."""
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


def separate_check_blocks(lines: list[str]) -> list[str]:
    """Ensure a blank line separates a CHECK block from following code lines."""
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


# ---------------------------------------------------------------------------
# File Discovery & Input Processing
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[DEFAULT_TEST_DIR],
        help="test files or directories (default: test/)",
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
            files.update(
                p
                for p in path.rglob("*")
                if p.is_file() and p.suffix in TEST_EXTENSIONS
            )
        elif path.is_file():
            files.add(path)
        else:
            raise SystemExit(f"test path does not exist: {path}")
    return sorted(files)


def test_kinds(lines: list[str], path: Path) -> tuple[set[str], str]:
    runs = [match for line in lines if (match := RUN_RE.match(line))]
    if not runs:
        return set(), ""
    kinds = {kind for run in runs for kind in TOOLS if f"%{kind}" in run["command"]}
    if not kinds:
        raise ValueError(f"{path}: no tool RUN directive")
    return kinds, runs[0]["comment"]


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


def run_setup_commands(lines: list[str], temporary_path: Path, path: Path) -> None:
    """Execute non-tool RUN commands in the temp dir before matching."""
    for line in lines:
        match = RUN_RE.match(line)
        if not match:
            continue
        command = match["command"]
        if any(f"%{kind}" in command for kind in TOOLS):
            continue
        if command.strip().startswith("split-file"):
            continue
        command = first_pipeline_stage(command).removeprefix("not ")
        command = substitute_shell_vars(command, path, temporary_path)
        proc = subprocess.run(
            command,
            shell=True,
            cwd=str(temporary_path),
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise ValueError(
                f"{path}: setup command failed: {command}\n{proc.stderr.rstrip()}"
            )


def find_llvm_tool(name: str) -> str:
    """Locate an LLVM tool on PATH or in the pinned llvm-project build."""
    if found := shutil.which(name):
        return found
    candidate = REPO_ROOT / "llvm-project" / "build" / "bin" / name
    if candidate.is_file() and os.access(candidate, os.X_OK):
        return str(candidate)
    raise ValueError(f"could not find {name} on PATH or in {candidate.parent}")


def functions_in_input(
    input_path: Path, section_name: str | None, path: Path
) -> list[SectionFunction]:
    """Collect (section, function-name) pairs from a matcher input."""
    inputs = (
        sorted(p for p in input_path.rglob("*") if p.suffix in (".ll", ".bc"))
        if input_path.is_dir()
        else [input_path]
    )
    results: list[SectionFunction] = []
    for input_file in inputs:
        if input_file.suffix == ".bc":
            proc = subprocess.run(
                [find_llvm_tool("llvm-dis"), str(input_file), "-o", "-"],
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
            SectionFunction(section_name, match["name"])
            for line in text.splitlines()
            if (match := LLVM_FUNCTION_RE.match(line))
        )
    return results


def find_declaration_lines(lines: list[str], start: int, end: int) -> set[int]:
    """Find line indices of top-level declarations (match/constraint/metaflag)."""
    decl_keywords = ("match", "constraint", "metaflag")
    decl_lines: set[int] = set()
    inside_decl = False
    brace_depth = 0

    for i in range(start, end):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith((";", "#", "//")):
            continue

        first = stripped.split()[0]
        if not inside_decl and any(
            first == kw or first.startswith(f"{kw}:") or first.startswith(f"{kw}[")
            for kw in decl_keywords
        ):
            inside_decl = True
            brace_depth = 0

        if inside_decl:
            decl_lines.add(i)
            brace_depth += lines[i].count("{") - lines[i].count("}")
            if brace_depth <= 0:
                # Check for 'or' branch continuation
                is_or = False
                for j in range(i + 1, end):
                    next_s = lines[j].strip()
                    if not next_s or next_s.startswith((";", "#", "//")):
                        continue
                    is_or = next_s == "or" or any(
                        next_s.startswith(p) for p in ("or ", "or\t", "or{", "or[")
                    )
                    break
                inside_decl = is_or

    return decl_lines


# ---------------------------------------------------------------------------
# Check Generators
# ---------------------------------------------------------------------------


def update_lexer_test(path: Path, lines: list[str], comment: str, lexer: Path) -> str:
    lines = strip_inter_check_blanks(lines)
    clean_lines = [line for line in lines if not CHECK_RE.match(line)]

    with tempfile.NamedTemporaryFile(mode="w", suffix=".ll", delete=False) as tmp:
        tmp.write("\n".join(clean_lines) + "\n")
        tmp_path = Path(tmp.name)

    try:
        result = subprocess.run(
            [lexer, "--line-numbers", str(tmp_path)],
            text=True,
            capture_output=True,
            check=False,
        )
    finally:
        tmp_path.unlink(missing_ok=True)

    if result.returncode and not result.stdout:
        raise ValueError(f"{path}: metaphir-lex failed:\n{result.stderr.rstrip()}")

    tokens_by_line: dict[int, list[str]] = collections.defaultdict(list)
    for raw_line in result.stdout.splitlines():
        if match := re.match(r"^(\d+):\s*(.*)$", raw_line):
            line_no = int(match.group(1))
            tokens_by_line[line_no].append(sanitize_pointers(match.group(2)))

    max_clean = len(clean_lines)
    trailing = [
        tok
        for lno, toks in sorted(tokens_by_line.items())
        if lno > max_clean
        for tok in toks
    ]
    last_line = max((lno for lno in tokens_by_line if lno <= max_clean), default=None)

    updated: list[str] = []
    emitted_any = False
    for idx, line in enumerate(clean_lines, start=1):
        updated.append(line)
        tokens = tokens_by_line.get(idx, [])
        if idx == last_line:
            tokens.extend(trailing)
        for token in tokens:
            directive = "CHECK" if not emitted_any else "CHECK-NEXT"
            updated.append(f"{comment} {directive}: {token}")
            emitted_any = True

    while updated and not updated[-1].strip():
        updated.pop()
    return "\n".join(separate_check_blocks(updated)) + "\n"


def gen_parser_checks(
    path: Path,
    clean_lines: list[str],
    comment: str,
    parser: Path,
    temporary_path: Path,
) -> dict[int, list[str]]:
    generated: list[ParserRun] = []
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
                Diagnostic(int(m["line"]), m["message"])
                for line in result.stderr.splitlines()
                if (m := ERROR_RE.search(line))
            ]
            output = [d.message for d in diagnostics]
            diagnostic_line = diagnostics[0].line if diagnostics else None
            warnings: list[Diagnostic] = []
        else:
            output = result.stdout.splitlines()
            diagnostic_line = None
            warnings = [
                Diagnostic(int(m["line"]), f"warning: {m['message']}")
                for line in result.stderr.splitlines()
                if (m := WARNING_RE.search(line))
            ]
        if not output and not warnings:
            raise ValueError(f"{path}: metaphir-parse produced no checkable output")
        output = [sanitize_pointers(line) for line in output]
        generated.append(
            ParserRun(
                section_name,
                get_check_prefix(command),
                output,
                diagnostic_line,
                warnings,
            )
        )

    checks_by_line: dict[int, list[str]] = collections.defaultdict(list)
    for run in generated:
        start, end = section_bounds(clean_lines, path, run.section)
        if run.diagnostic_line is not None:
            targets = [start + run.diagnostic_line - 1] * len(run.output)
            run_output = run.output
        else:
            decl_lines = find_declaration_lines(clean_lines, start, end)
            instruction_lines = [
                i
                for i in range(start, end)
                if i not in decl_lines
                and clean_lines[i].strip()
                and not clean_lines[i].lstrip().startswith((";", "#", "//"))
            ]
            constraint_lines = [
                i
                for i in range(start, end)
                if i not in decl_lines and clean_lines[i].lstrip().startswith(";;")
            ]
            pattern_output = [ln for ln in run.output if ln.startswith("pattern ")]
            constraint_output = [
                ln for ln in run.output if ln.startswith("constraint ")
            ]
            meta_output = [ln for ln in run.output if ln.startswith("meta ")]
            instruction_output = [
                ln
                for ln in run.output
                if not ln.startswith(("pattern ", "constraint ", "meta "))
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
                + list(zip(instruction_lines, instruction_output, strict=True))
                + list(zip(constraint_lines, constraint_output, strict=True))
                + [(trailing_target, line) for line in meta_output]
            )
            targets = [t for t, _ in placed]
            run_output = [ln for _, ln in placed]

        for i, (target, line) in enumerate(zip(targets, run_output, strict=True)):
            directive = run.prefix if i == 0 else f"{run.prefix}-NEXT"
            checks_by_line[target].append(f"{comment} {directive}: {line}")

        if run.warnings and targets:
            checks_by_line[targets[0]][0:0] = [
                f"{comment} {run.prefix}: {w.message}" for w in run.warnings
            ]
    return checks_by_line


def gen_matcher_checks(
    path: Path,
    clean_lines: list[str],
    comment: str,
    matcher: Path,
    temporary_path: Path,
) -> tuple[dict[int, list[str]], list[str]]:
    generated: list[MatcherGroup] = []
    error_directives: list[str] = []
    for run in (m for line in clean_lines if (m := RUN_RE.match(line))):
        if "%metaphir-match" not in run["command"]:
            continue
        command = run["command"]
        expected_failure = bool(re.search(r"\bnot\s+%metaphir-match\b", command))
        invocation = first_pipeline_stage(command)
        invocation = (
            re.sub(r"\bnot\s+%metaphir-match\b", "%metaphir-match", invocation)
            .replace("2>&1", "")
            .strip()
        )
        arguments = shlex.split(invocation)
        tool_index = arguments.index("%metaphir-match")
        raw_args = arguments[tool_index + 1 :]
        # Options are passed through; positional arguments are the pattern
        # followed by the target inputs.
        positional = [arg for arg in raw_args if not arg.startswith("-")]
        if not positional:
            raise ValueError(f"{path}: %metaphir-match RUN line has no pattern")
        target_args = positional[1:]
        substituted_args = [
            substitute_vars(arg, path, temporary_path) for arg in raw_args
        ]
        substituted_targets = [
            substitute_vars(arg, path, temporary_path) for arg in target_args
        ]

        result = subprocess.run(
            [matcher, *substituted_args], text=True, capture_output=True, check=False
        )
        prefix = get_check_prefix(command)

        if expected_failure:
            if result.returncode == 0:
                raise ValueError(f"{path}: metaphir-match was expected to fail")
            output = (result.stdout + result.stderr).splitlines()
            if not output:
                raise ValueError(f"{path}: metaphir-match error run produced no output")
            cleaned = strip_error_prefix([sanitize_pointers(ln) for ln in output])
            error_directives.extend(format_directives(cleaned, prefix, comment))
            continue

        if result.returncode:
            raise ValueError(
                f"{path}: metaphir-match failed:\n{result.stderr.rstrip()}"
            )
        output = result.stdout.splitlines()
        if not output:
            raise ValueError(f"{path}: metaphir-match produced no checkable output")

        target_sections = [
            arg[3:] if arg.startswith("%t/") else None for arg in target_args
        ]
        section_functions: list[SectionFunction] = []
        for section_name, arg in zip(target_sections, substituted_targets, strict=True):
            input_path = path if section_name is None else temporary_path / section_name
            if not input_path.exists():
                raise ValueError(f"{path}: matcher input {arg} does not exist")
            section_functions.extend(functions_in_input(input_path, section_name, path))

        target_groups: list[TargetGroup] = []
        for line in output:
            if match := MATCH_TARGET_RE.match(line):
                target_groups.append(TargetGroup(match["name"], [line]))
            elif target_groups:
                target_groups[-1].lines.append(line)
            else:
                raise ValueError(f"{path}: malformed metaphir-match output")

        if len(target_groups) != len(section_functions):
            raise ValueError(f"{path}: cannot map matcher targets to LLVM functions")

        for idx, (group, expected) in enumerate(
            zip(target_groups, section_functions, strict=True)
        ):
            if group.name != expected.function:
                raise ValueError(
                    f"{path}: matcher target @{group.name} does not correspond to "
                    f"LLVM function @{expected.function}"
                )
            directives = format_directives(
                group.lines, prefix, comment, is_first=(idx == 0)
            )
            generated.append(
                MatcherGroup(expected.section, expected.function, directives)
            )

    checks_by_line: dict[int, list[str]] = collections.defaultdict(list)
    for group in generated:
        definition = next(
            (
                i
                for i, line in enumerate(clean_lines)
                if (m := LLVM_FUNCTION_RE.match(line)) and m["name"] == group.function
            ),
            None,
        )
        if definition is None:
            raise ValueError(
                f"{path}: no LLVM definition for matcher target @{group.function}"
            )
        function_end = next(
            (
                i
                for i in range(definition + 1, len(clean_lines))
                if clean_lines[i].strip() == "}"
            ),
            None,
        )
        if function_end is None:
            raise ValueError(f"{path}: unterminated LLVM definition @{group.function}")
        checks_by_line[function_end].extend(group.directives)

    return checks_by_line, error_directives


# ---------------------------------------------------------------------------
# Assembly & Driver
# ---------------------------------------------------------------------------


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
    exit_code = 0

    for path in collect_files(args.paths):
        original = path.read_text()
        if MANUAL_MARKER in original:
            continue
        lines = original.splitlines()
        try:
            kinds, comment = test_kinds(lines, path)
            if not kinds:
                continue
            if kinds == {"metaphir-lex"}:
                if lexer is None:
                    lexer = find_tool("metaphir-lex", args.metaphir_lex, "METAPHIR_LEX")
                updated = update_lexer_test(path, lines, comment, lexer)
            else:
                tools: dict[str, Path] = {}
                if "metaphir-parse" in kinds:
                    if parser is None:
                        parser = find_tool(
                            "metaphir-parse", args.metaphir_parse, "METAPHIR_PARSE"
                        )
                    tools["parser"] = parser
                if "metaphir-match" in kinds:
                    if matcher is None:
                        matcher = find_tool(
                            "metaphir-match", args.metaphir_match, "METAPHIR_MATCH"
                        )
                    tools["matcher"] = matcher
                if "metaphir-lex" in kinds:
                    raise ValueError(
                        f"{path}: lexer tests cannot be combined with other tools"
                    )
                updated = update_test(path, lines, comment, kinds, tools)
        except ValueError as error:
            print(error, file=sys.stderr)
            exit_code = 1
            continue

        assert updated is not None
        if updated != original:
            path.write_text(updated)
            changed += 1
            print(f"updated {path}")

    print(f"updated {changed} test(s)")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
