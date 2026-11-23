#!/usr/bin/env python3
"""Regenerate FileCheck directives in MetaphIR lexer, parser, matcher and pass
tests.

A test whose RUN line pipes MLIR (from metaphir-opt, or metaphir-parse
--emit=mlir) to FileCheck gets, after the input of each of its cases, the
CHECK lines mlir/utils/generate-test-checks.py writes for what the tools
print now. Cases are separated by '// -----', and the RUN line then has
--split-input-file. Locations are matched by any text. Review what is
written: it records the output, right or wrong.
"""

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
LABEL_RE = re.compile(r"^\s*\?[^\s:]+:\s*$")
LET_RE = re.compile(r"^\s*;;\s*let\b")
MATCH_TARGET_RE = re.compile(r"^target [0-9]+: @(?P<name>[-a-zA-Z$._0-9]+)$")
LLVM_FUNCTION_RE = re.compile(r"^\s*define\b.*@(?P<name>[-a-zA-Z$._0-9]+)\s*\(")

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEST_DIR = REPO_ROOT / "test"
TOOLS = ("metaphir-lex", "metaphir-parse", "metaphir-match", "metaphir-opt")
# What lit (test/lit.cfg.py) runs.
TEST_EXTENSIONS = {".ll", ".mlir", ".mpir"}
MLIR_CHECK_GENERATOR = (
    REPO_ROOT / "llvm-project" / "mlir" / "utils" / "generate-test-checks.py"
)
MLIR_LOCATION_RE = re.compile(r"#loc\d*")
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


def end_directive(prefix: str, comment: str) -> str:
    """A directive that nothing but blank lines follows: a trailing -NOT is
    checked to the end of the input, so output not checked fails the test."""
    return f"{comment} {prefix}-NOT: {{{{.}}}}"


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
        "--metaphir-opt",
        type=Path,
        help="path to metaphir-opt (otherwise use METAPHIR_OPT, PATH, or build/)",
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
    """Execute non-tool RUN commands other than split-file in the temp dir
    before running the parser or matcher."""
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
        for name in ("metaphir-index", "metaphir-opt"):
            command = command.replace(
                f"%{name}", shlex.quote(str(REPO_ROOT / "build" / "tools" / name))
            )
        proc = subprocess.run(
            command,
            shell=True,
            cwd=str(REPO_ROOT),
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
            setting_lines = [
                i
                for i in range(start, end)
                if i not in decl_lines and clean_lines[i].lstrip().startswith(";;")
            ]
            # A ';; let' prints as a 'let' line, after all the constraints.
            let_lines = [i for i in setting_lines if LET_RE.match(clean_lines[i])]
            constraint_lines = [i for i in setting_lines if i not in let_lines]
            pattern_output = [ln for ln in run.output if ln.startswith("pattern ")]
            constraint_output = [
                ln for ln in run.output if ln.startswith("constraint ")
            ]
            let_output = [ln for ln in run.output if ln.startswith("let ")]
            meta_output = [ln for ln in run.output if ln.startswith("meta ")]
            instruction_output = [
                ln
                for ln in run.output
                if not ln.startswith(("pattern ", "constraint ", "let ", "meta "))
            ]
            # A block label is printed before its block's first instruction;
            # one with none, which a branch refers to, is not printed.
            printed = set(instruction_output)
            instruction_lines = [
                i
                for i in instruction_lines
                if not LABEL_RE.match(clean_lines[i])
                or clean_lines[i].strip() in printed
            ]
            if len(instruction_output) != len(instruction_lines):
                raise ValueError(f"{path}: cannot map parser instructions to input")
            if len(constraint_output) != len(constraint_lines):
                raise ValueError(f"{path}: cannot map parser constraints to input")
            if len(let_output) != len(let_lines):
                raise ValueError(f"{path}: cannot map parser lets to input")
            if not instruction_lines:
                raise ValueError(f"{path}: parser test has no instruction input")
            # The lets and meta variables, printed last, are checked after the
            # last line they can come from.
            trailing_target = (
                setting_lines[-1] if setting_lines else instruction_lines[-1]
            )
            placed = (
                [(instruction_lines[0], line) for line in pattern_output]
                + list(zip(instruction_lines, instruction_output, strict=True))
                + list(zip(constraint_lines, constraint_output, strict=True))
                + [(trailing_target, line) for line in let_output + meta_output]
            )
            targets = [t for t, _ in placed]
            run_output = [ln for _, ln in placed]

        for i, (target, line) in enumerate(zip(targets, run_output, strict=True)):
            directive = run.prefix if i == 0 else f"{run.prefix}-NEXT"
            checks_by_line[target].append(f"{comment} {directive}: {line}")
        # A failed parse is checked by its messages only, not the source
        # lines that follow them.
        if run.diagnostic_line is None and targets:
            checks_by_line[targets[-1]].append(end_directive(run.prefix, comment))

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
            error_directives.append(end_directive(prefix, comment))
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
            if idx == len(target_groups) - 1:
                directives.append(end_directive(prefix, comment))
            generated.append(
                MatcherGroup(expected.section, expected.function, directives)
            )

    checks_by_line: dict[int, list[str]] = collections.defaultdict(list)
    for group in generated:
        # Another section may define a function of the same name. An input a
        # RUN line builds, such as a directory, is no section: the whole file
        # is searched.
        has_section = group.section is not None and any(
            (m := SPLIT_RE.match(line)) and m["name"] == group.section
            for line in clean_lines
        )
        start, end = (
            section_bounds(clean_lines, path, group.section)
            if has_section
            else (0, len(clean_lines))
        )
        definition = next(
            (
                i
                for i in range(start, end)
                if (m := LLVM_FUNCTION_RE.match(clean_lines[i]))
                and m["name"] == group.function
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


# ---------------------------------------------------------------------------
# Tests of MLIR output
#
# An MLIR input carries a location on each operation line, naming the line
# itself: loc("<file>":N:1). The tools keep locations, so each operation of
# the output names the input line it came from, and its CHECK lines go right
# after that line. A surface pattern (.mpir) needs no injected locations: the
# parser locates operations at their lines already.
# ---------------------------------------------------------------------------

CHECK_DIRECTIVE_RE = re.compile(r"^\s*(//|;|#)\s*CHECK[-A-Z]*:")
LOC_DEFINITION_RE = re.compile(r"^#(loc\d*) = (?P<body>.*)$")
LOC_REFERENCE_RE = re.compile(r"#(loc\d*)\b")
FILE_LOCATION_RE = re.compile(r'"(?P<file>[^"]*)":(?P<line>\d+):(?P<column>\d+)')
TRAILING_LOCATION_RE = re.compile(r" loc\(#(loc\d*)\)$")
INLINE_FILE_LOCATION_RE = re.compile(r' loc\("[^"]*":\d+:\d+\)')
OPERATION_LINE_RE = re.compile(
    r"^\s*(%|\"|mpir(_expr|_plan|_index)?\.|\})"
)


def is_comment_or_text(line: str) -> bool:
    return line.lstrip().startswith(("//", ";"))


def set_file_locations(lines: list[str], name: str, inject: bool) -> list[str]:
    """Writes each line's own number into the locations naming this file, and,
    if inject, gives an operation line without a location one."""
    result = []
    file_location = re.compile(rf'"{re.escape(name)}":\d+:\d+')
    for number, line in enumerate(lines, start=1):
        line = file_location.sub(f'"{name}":{number}:1', line)
        # Metaflags are located at the operation they are written on.
        if "loc(unknown)" in line and not LOC_DEFINITION_RE.match(line):
            line = line.replace("loc(unknown)", f'loc("{name}":{number}:1)')
        if (
            inject
            and not is_comment_or_text(line)
            and "loc(" not in line
            and OPERATION_LINE_RE.match(line)
            and not line.rstrip().endswith(("{", ",", "(", "[", "<", "\\"))
        ):
            line = f'{line.rstrip()} loc("{name}":{number}:1)'
        result.append(line)
    return result


def opening_line(lines: list[str], number: int) -> int:
    """The line a region's closing line (1-based) closes the opening of."""
    line = lines[number - 1]
    if not line.lstrip().startswith("}"):
        return number
    indent = len(line) - len(line.lstrip())
    for above in range(number - 1, 0, -1):
        text = lines[above - 1]
        if (
            text.rstrip().endswith("{")
            and len(text) - len(text.lstrip()) == indent
        ):
            return above
    return number


class LocationResolver:
    """What a location of the output names: the line of the input file it
    came from, or None if it names another file."""

    def __init__(self, definitions: dict[str, str], name: str) -> None:
        self.definitions = definitions
        self.name = name

    def resolve(self, text: str, depth: int = 0) -> int | None:
        if depth > 50:
            return None
        if "callsite(" in text and " at " in text:
            # A callsite is the caller: the line of the use, outermost first.
            caller = text.split(" at ", 1)[1]
            for reference in reversed(LOC_REFERENCE_RE.findall(caller)):
                found = self.resolve_name(reference, depth + 1)
                if found is not None:
                    return found
            return None
        match = FILE_LOCATION_RE.search(text)
        if match:
            # The file is named as the tool was given it, or as a location says.
            same = Path(match["file"]).name == self.name
            return int(match["line"]) if same else None
        for reference in LOC_REFERENCE_RE.findall(text):
            found = self.resolve_name(reference, depth + 1)
            if found is not None:
                return found
        return None

    def resolve_name(self, name: str, depth: int) -> int | None:
        body = self.definitions.get(name)
        return None if body is None else self.resolve(body, depth)


def output_keys(
    chunk: list[str], resolver: LocationResolver, opening
) -> list[int | None]:
    """The input line (or None) each non-blank line of the output is from. A
    region's opening line is from the line that opens it, given the line of
    its closing by opening (a function from input closing line to opening)."""
    keys: list[int | None] = []
    current: int | None = None
    nonblank = [line for line in chunk if line.strip()]
    for index, line in enumerate(nonblank):
        trailing = TRAILING_LOCATION_RE.search(line)
        if trailing:
            current = resolver.resolve_name(trailing.group(1), 0)
        elif line.rstrip().endswith("{"):
            # A region's location is on its closing line, after the region.
            indent = len(line) - len(line.lstrip())
            for later in nonblank[index + 1 :]:
                if later.lstrip().startswith("}") and (
                    len(later) - len(later.lstrip()) == indent
                ):
                    closing = TRAILING_LOCATION_RE.search(later)
                    if closing:
                        found = resolver.resolve_name(closing.group(1), 0)
                        current = None if found is None else opening(found)
                    break
        keys.append(current)
    return keys


def without_module(chunk: list[str]) -> list[str]:
    """The chunk without the module it prints in: the generator does not check
    the module's own lines."""
    lines = [line for line in chunk if line.strip()]
    if lines and lines[0].strip() == "module {":
        lines = lines[1:]
    if lines and re.match(r"^\}( loc\(#loc\d*\))?$", lines[-1].strip()):
        lines = lines[:-1]
    return lines


def clean_for_checks(chunk: list[str]) -> list[str]:
    """The output as lit compares it: without the location aliases."""
    result = []
    for line in chunk:
        if LOC_DEFINITION_RE.match(line):
            continue
        line = TRAILING_LOCATION_RE.sub("", line)
        # What lit's output, without debug information, does not print.
        line = INLINE_FILE_LOCATION_RE.sub("", line)
        # A '%name' in a string (a plan's slot names) is not an SSA value.
        result.append(LOC_REFERENCE_RE.sub("LOCREF", line).replace('"%', '"PERCENT'))
    return result


def mlir_checks_for(chunk: list[str], prefix: str) -> list[list[str]]:
    """The CHECK lines of one output chunk, grouped by the line they check:
    one group for each non-blank line other than the module's own. A line the
    generator splits (CHECK-SAME, CHECK-NEXT) stays in its group."""
    text = "\n".join(line for line in clean_for_checks(chunk) if line.strip())
    result = subprocess.run(
        [sys.executable, str(MLIR_CHECK_GENERATOR), "--check-prefix", prefix],
        input=text,
        capture_output=True,
        text=True,
        check=True,
    )
    groups: list[list[str]] = []
    for line in result.stdout.splitlines():
        if not re.match(rf"^// {re.escape(prefix)}(-[A-Z]+)?:", line):
            continue
        line = line.replace("LOCREF", "{{.*}}").replace('"PERCENT', '"%')
        if re.match(rf"^// {re.escape(prefix)}-(SAME|NEXT):", line) and groups:
            groups[-1].append(line)
        else:
            groups.append([line])
    expected = len(without_module(chunk))
    if len(groups) != expected:
        raise ValueError(
            f"the check generator wrote {len(groups)} lines for {expected} lines"
        )
    return groups


def mlir_stage_checks(
    shell: str, prefix: str, name: str, inputs: list[str], path: Path
) -> dict[int, list[str]]:
    """Runs one RUN pipeline on the input and returns, for each input line
    (1-based), the CHECK lines of the output that came from it."""
    with tempfile.TemporaryDirectory() as temporary:
        input_path = Path(temporary) / name
        input_path.write_text("\n".join(inputs) + "\n")
        command = shell.replace("%s", shlex.quote(str(input_path)))
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True, check=False
        )
    if result.returncode != 0:
        raise ValueError(f"{path}: {shell}\n{result.stderr}")
    by_line: dict[int, list[str]] = {}
    chunks = result.stdout.split("// -----")
    for chunk_text in chunks:
        chunk = chunk_text.splitlines()
        definitions = {
            found.group(1): found["body"]
            for found in map(LOC_DEFINITION_RE.match, chunk)
            if found
        }
        resolver = LocationResolver(definitions, name)
        whole = [line for line in chunk if not LOC_DEFINITION_RE.match(line)]
        body = without_module(whole)
        keys = output_keys(body, resolver, lambda line: opening_line(inputs, line))
        checks = mlir_checks_for(whole, prefix)
        assert len(keys) == len(checks)
        # The checks keep the order of the output: a line from an earlier
        # line of the input (a definition's, for one) stays where it is
        # written, after the line before it.
        current: int | None = None
        for key, group in zip(keys, checks):
            if key is None or (current is not None and key < current):
                key = current
            else:
                current = key
            if key is None:
                key = 0
            by_line.setdefault(key, []).extend(group)
    return by_line


def mlir_runs_to_stages(lines: list[str], comment: str) -> list[str]:
    """The RUN commands that pipe MLIR to FileCheck, each as one line."""
    commands: list[str] = []
    for line in lines:
        if match := RUN_RE.match(line):
            text = match["command"].rstrip()
            if commands and commands[-1].endswith("\\"):
                commands[-1] = commands[-1][:-1] + " " + text
            else:
                commands.append(text)
    return [
        command
        for command in commands
        if "FileCheck" in command and not command.startswith("not ")
        and ("%metaphir-opt" in command or "--emit=mlir" in command)
    ]


def update_mlir_test(
    path: Path, lines: list[str], comment: str, tools: dict[str, Path]
) -> str:
    name = path.name
    inject = path.suffix == ".mlir"
    # metaphir-parse locates each operation at its pattern line, and prints the
    # locations only with --mlir-print-debuginfo, as metaphir-opt does: the RUN
    # line says so, so that the checks it records are the ones it runs.
    lines = [
        re.sub(r"%metaphir-parse --emit=mlir(?! --mlir-print-debuginfo)",
               "%metaphir-parse --emit=mlir --mlir-print-debuginfo", line)
        if RUN_RE.match(line) else line
        for line in lines
    ]
    runs = mlir_runs_to_stages(lines, comment)
    # The lines without checks, located in this file.
    # Checks of any comment style: a file may hold the ones of an earlier run.
    clean = [line for line in lines if not CHECK_DIRECTIVE_RE.match(line)]
    clean = set_file_locations(clean, name, inject)
    insertions: dict[int, list[str]] = {}
    for command in runs:
        stages = command.split("|")
        check = next(i for i, stage in enumerate(stages) if "FileCheck" in stage)
        prefix = get_check_prefix(stages[check])
        shell = "|".join(stages[:check])
        if inject:
            shell = shell.replace("metaphir-opt", "metaphir-opt --mlir-print-debuginfo")
            shell = shell.replace("%metaphir-opt", "%metaphir-opt --mlir-print-debuginfo")
        for kind, tool in tools.items():
            shell = shell.replace(f"%{kind}", shlex.quote(str(tool)))
        for key, checks in mlir_stage_checks(shell, prefix, name, clean, path).items():
            insertions.setdefault(key, []).extend(checks)
    # Checks without a line of their own (a pattern's, in a file whose parser
    # does not locate it) go before the first line that has one.
    leading = insertions.pop(0, [])
    if leading:
        located = sorted(insertions)
        if located:
            insertions[max(0, located[0] - 1)] = leading + insertions.get(
                max(0, located[0] - 1), []
            )
        else:
            insertions[0] = leading
    output: list[str] = []
    for check in insertions.pop(0, []):
        output.append(comment + check[2:] if comment != "//" else check)
    for number, line in enumerate(clean, start=1):
        output.append(line)
        for check in insertions.pop(number, []):
            output.append(comment + check[2:] if comment != "//" else check)
    if insertions:
        raise ValueError(f"{path}: checks for lines {sorted(insertions)}")
    return "\n".join(set_file_locations(output, name, False)) + "\n"



SURFACE_RUN_RE = re.compile(
    r"^%metaphir-parse\s+%s\s*\|\s*FileCheck\s+%s\s*$"
)


def surface_runs(lines: list[str]) -> list[str]:
    """The RUN lines that check the surface printing of a pattern."""
    return [
        match["command"].strip()
        for line in lines
        if (match := RUN_RE.match(line)) and SURFACE_RUN_RE.match(match["command"].strip())
    ]


def surface_line_keys(output: list[str], inputs: list[str]) -> list[int]:
    """The input line (index into inputs, 0 for before them all) each line of
    the printed surface pattern comes from: an instruction by its result name,
    a constraint by its order among the ';;' lines, a meta variable by its
    first use."""
    keys: list[int] = []
    current = 0
    constraints = [i for i, line in enumerate(inputs) if line.lstrip().startswith(";;")]
    next_constraint = 0
    for line in output:
        text = line.strip()
        key = current
        if text.startswith("%"):
            name = text.split(" ", 1)[0]
            for i, candidate in enumerate(inputs):
                if candidate.lstrip().startswith(name + " ="):
                    key = i + 1
                    break
        elif text.startswith("constraint "):
            if next_constraint < len(constraints):
                key = constraints[next_constraint] + 1
            next_constraint += 1
        elif text.startswith("meta ?"):
            name = text.split()[1]
            for i, candidate in enumerate(inputs):
                if re.search(re.escape(name) + r"\b", candidate):
                    key = i + 1
                    break
        keys.append(key)
        current = key
    return keys


def update_surface_test(
    path: Path, lines: list[str], comment: str, tools: dict[str, Path]
) -> str:
    """The surface printing of a pattern, each printed line checked right after
    the input line it comes from. A line the printer puts out of input order
    (constraints and meta variables come after the instructions) is a CHECK-DAG,
    so that it may match where it is printed."""
    clean = [line for line in lines if not CHECK_DIRECTIVE_RE.match(line)]
    run_index = next(i for i, line in enumerate(clean) if RUN_RE.match(line))
    with tempfile.NamedTemporaryFile("w", suffix=path.suffix, delete=False) as temporary:
        temporary.write("\n".join(clean) + "\n")
    try:
        command = f"{shlex.quote(str(tools['metaphir-parse']))} {shlex.quote(temporary.name)}"
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    finally:
        os.unlink(temporary.name)
    if result.returncode != 0:
        raise ValueError(f"{path}: {command}\n{result.stderr}")
    output = result.stdout.splitlines()
    for line in output:
        if "{{" in line or "[[" in line:
            raise ValueError(f"{path}: output with FileCheck syntax: {line}")
    keys = surface_line_keys(output, clean)
    # Each printed line: CHECK when it follows the one before it, CHECK-DAG when
    # the printer put it out of input order.
    insertions: dict[int, list[str]] = {}
    previous = -1
    for index, (line, key) in enumerate(zip(output, keys)):
        if key < previous:
            key = previous
            directive = "CHECK-DAG"
        else:
            directive = "CHECK" if index == 0 or key != previous else "CHECK-NEXT"
        previous = key
        if not line.strip():
            directive = "CHECK-EMPTY"
        target = key if key > 0 else run_index + 1
        insertions.setdefault(target, []).append(
            f"{comment} {directive}: {line}".rstrip()
        )
    result_lines: list[str] = []
    for number, line in enumerate(clean, start=1):
        result_lines.append(line)
        result_lines += insertions.pop(number, [])
    if insertions:
        raise ValueError(f"{path}: checks for lines {sorted(insertions)}")
    return "\n".join(result_lines) + "\n"


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


# ---------------------------------------------------------------------------
# Tests of what any RUN pipeline gives FileCheck
#
# A test whose FileCheck reads a file a RUN line wrote, or what another
# command (grep, diff) made of a tool's output, is run as lit runs it, with
# each FileCheck replaced by a capture of its input. Each capture's lines are
# checked in order, under the FileCheck's prefix, where that prefix's
# directives were (or at the end of the file).
# ---------------------------------------------------------------------------

FILECHECK_RE = re.compile(r"\bFileCheck\b(?P<args>[^|&;]*)")
INPUT_REDIRECT_RE = re.compile(r"(?<![0-9&])<\s*(?P<file>\S+)")


def pipeline_stages(command: str) -> list[str]:
    """The stages of command's first pipeline, split at unquoted pipes."""
    stages: list[str] = []
    rest = command
    while True:
        stage = first_pipeline_stage(rest)
        stages.append(stage)
        if len(stage) >= len(rest.strip()):
            return stages
        rest = rest.strip()[len(stage) :].lstrip()[1:]


def checks_tool_output(command: str) -> bool:
    """Whether command is a tool pipeline the tool-specific generators read:
    tools piped into one FileCheck that reads its standard input."""
    stages = pipeline_stages(command)
    *tools, last = stages
    return (
        last.startswith("FileCheck")
        and not INPUT_REDIRECT_RE.search(last)
        and bool(tools)
        and all(
            re.match(r"^(not\s+)?%metaphir-[a-z]+\b", stage)
            and not re.search(r"(?<![0-9&])>", stage)
            for stage in tools
        )
    )


def needs_pipeline_run(lines: list[str]) -> bool:
    """Whether a FileCheck of the test reads anything but what tools pipe to
    it: a file, or another command's output."""
    for line in lines:
        if not (match := RUN_RE.match(line)):
            continue
        command = match["command"]
        if "FileCheck" in command and not checks_tool_output(command):
            return True
    return False


def tool_path(name: str) -> str:
    return shlex.quote(str(REPO_ROOT / "build" / "tools" / name))


def run_pipeline_captures(
    path: Path, lines: list[str], temporary: Path
) -> list[tuple[str, list[str]]]:
    """Runs the RUN lines with each FileCheck replaced by a capture of its
    input: each FileCheck's prefix, and the lines it would have read."""
    # The commands run in the temporary directory, as lit's do in theirs.
    path = path.resolve()
    test_temp = temporary / "t"
    captures: list[tuple[str, Path]] = []

    def capture(match: re.Match[str]) -> str:
        args = match["args"]
        target = temporary / f"capture{len(captures)}"
        captures.append((get_check_prefix(args), target))
        redirect = INPUT_REDIRECT_RE.search(args)
        source = f"< {redirect['file']}" if redirect else ""
        return f"cat {source} > {shlex.quote(str(target))} "

    for line in lines:
        if not (match := RUN_RE.match(line)):
            continue
        command = re.sub(
            r"%(metaphir-[a-z]+)", lambda m: tool_path(m[1]), match["command"]
        )
        command = FILECHECK_RE.sub(capture, command)
        command = substitute_shell_vars(command, path, test_temp)
        proc = subprocess.run(
            ["bash", "-o", "pipefail", "-c", command],
            cwd=str(temporary),
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise ValueError(
                f"{path}: RUN line failed: {match['command']}\n{proc.stderr.rstrip()}"
            )

    prefixes = [prefix for prefix, _ in captures]
    if len(set(prefixes)) != len(prefixes):
        raise ValueError(f"{path}: two FileChecks share a prefix")
    result: list[tuple[str, list[str]]] = []
    for prefix, target in captures:
        output = [
            sanitize_pointers(line).replace(str(test_temp), "{{.*}}")
            for line in target.read_text().splitlines()
        ]
        if not any(line.strip() for line in output):
            raise ValueError(f"{path}: the {prefix} FileCheck reads nothing")
        result.append((prefix, output))
    return result


def update_pipeline_test(path: Path, lines: list[str], comment: str) -> str:
    with tempfile.TemporaryDirectory() as temporary:
        captures = run_pipeline_captures(path, lines, Path(temporary))
    prefixes = {prefix for prefix, _ in captures}
    lines = strip_inter_check_blanks(lines)
    # Each prefix's checks go where its first directive was.
    kept: list[str] = []
    places: dict[str, int] = {}
    for line in lines:
        prefix = directive_prefix(line) if CHECK_RE.match(line) else None
        if prefix in prefixes:
            places.setdefault(prefix, len(kept))
            continue
        kept.append(line)
    while kept and not kept[-1].strip():
        kept.pop()
    blocks: dict[int, list[str]] = collections.defaultdict(list)
    for prefix, output in captures:
        directives = format_directives(
            [line for line in output if line.strip()], prefix, comment
        )
        directives.append(end_directive(prefix, comment))
        blocks[places.get(prefix, len(kept))].append("\n".join(directives))
    for place in sorted(blocks, reverse=True):
        block = "\n\n".join(blocks[place]).split("\n")
        if place == len(kept):
            block = [""] + block
        kept[place:place] = block
    return "\n".join(separate_check_blocks(kept)) + "\n"


def main() -> int:
    args = parse_args()
    # The LLVM tools that RUN lines use (split-file, FileCheck, not).
    llvm_bin = REPO_ROOT / "llvm-project" / "build" / "bin"
    os.environ["PATH"] = os.pathsep.join([str(llvm_bin), os.environ.get("PATH", "")])
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
            if needs_pipeline_run(lines):
                updated = update_pipeline_test(path, lines, comment)
            elif surface_runs(lines):
                surface_tools = {
                    "metaphir-parse": find_tool(
                        "metaphir-parse", args.metaphir_parse, "METAPHIR_PARSE"
                    )
                }
                updated = update_surface_test(path, lines, comment, surface_tools)
            elif mlir_runs_to_stages(lines, comment):
                mlir_tools = {
                    kind: find_tool(
                        kind,
                        getattr(args, kind.replace("-", "_"), None),
                        kind.upper().replace("-", "_"),
                    )
                    for kind in kinds
                }
                updated = update_mlir_test(path, lines, comment, mlir_tools)
            elif "metaphir-opt" in kinds:
                # Checked by --verify-diagnostics, or on what a tool reports.
                continue
            elif kinds == {"metaphir-lex"}:
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
            # Some errors (a RUN line shlex cannot split) do not say which
            # test they are about.
            message = str(error)
            print(
                message if message.startswith(str(path)) else f"{path}: {message}",
                file=sys.stderr,
            )
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
