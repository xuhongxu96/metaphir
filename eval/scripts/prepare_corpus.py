#!/usr/bin/env python3
"""Prepare a MetaphIR evaluation corpus.

Four kinds, each written to a gitignored ``eval/corpus-<kind>``:

  original         every ``original/*.bc`` copied verbatim (no ``opt``)
  thinlto-prelink  ``opt -passes='thinlto-pre-link<O2>'``, folds disabled
  before-ic1       ``default<O2>`` up to the first InstCombine, folds disabled
  o2-final         ``opt -passes='default<O2>'``, folds disabled

``before-ic1`` is cut from ``opt -print-pipeline-passes``, so it follows the LLVM
that is built. The first InstCombine is a module-level step, so the cut is exact.
Later runs are inside the inliner's per-function walk, where O2 optimizes each
callee before inlining it, so a pipeline cut cannot give their exact input.

Every corpus also gets the top-level InstCombine and InstSimplify tests, copied
as ``InstCombine__<file>.ll`` / ``InstSimplify__<file>.ll``. Tests that do not
parse standalone (e.g. intentionally invalid IR) are skipped and logged.

A fresh clone rebuilds a corpus with

    eval/scripts/prepare_corpus.py --kind o2-final --bench-root <llvm-opt-benchmark>
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OPT = Path(
    os.environ.get("METAPHIR_OPT", REPO / "llvm-project" / "build" / "bin" / "opt")
)
# Local checkout of dtcxzyw/llvm-opt-benchmark (one sub-directory per project,
# each with an `original/` folder of .bc files).
BENCH_ROOT_ENV = "METAPHIR_BENCH_ROOT"
LLVM_TEST_DIR = REPO / "llvm-project" / "llvm" / "test" / "Transforms"
TEST_SUITES = ("InstCombine", "InstSimplify")
TEST_PREFIXES = tuple(f"{suite}__" for suite in TEST_SUITES)
LEGACY_TEST_RE = re.compile(r"^pr\d+__")
# The benchmark has 68,845 modules; this one's two velox modules carry invalid
# debug info, so every corpus is built from the same 68,843.
EXPECTED_MODULES = 68843
KNOWN_FAILURES = {
    "velox/original/EventBase.bc",
    "velox/original/ThreadPoolExecutor.bc",
}
# A pipeline, or ``before-instcombine:<N>`` for ``default<O2>`` up to its Nth
# InstCombine (see ``pipeline_before_instcombine``).
KINDS = {
    "original": None,
    "thinlto-prelink": "thinlto-pre-link<O2>",
    "before-ic1": "before-instcombine:1",
    "o2-final": "default<O2>",
}
BEFORE_INSTCOMBINE = "before-instcombine:"
INSTCOMBINE_RE = re.compile(r"(?<=[,(])instcombine<")


def pipeline_before_instcombine(opt: Path, n: int) -> str:
    """``default<O2>`` up to, not including, its Nth InstCombine run."""
    proc = subprocess.run(
        [str(opt), "-passes=default<O2>", "-print-pipeline-passes", "-disable-output"],
        input="",
        capture_output=True,
        text=True,
        check=True,
    )
    text = (proc.stdout + proc.stderr).strip()
    starts = [m.start() for m in INSTCOMBINE_RE.finditer(text)]
    if n > len(starts):
        sys.exit(f"default<O2> has {len(starts)} InstCombine runs, not {n}")
    prefix = text[: starts[n - 1]].rstrip(",")
    return prefix + ")" * (prefix.count("(") - prefix.count(")"))


def resolve_passes(spec: str, opt: Path) -> str:
    if spec.startswith(BEFORE_INSTCOMBINE):
        return pipeline_before_instcombine(opt, int(spec[len(BEFORE_INSTCOMBINE) :]))
    return spec


def module_entries(bench_root: Path) -> list[tuple[str, Path]]:
    """Every ``<proj>/original/*.bc``, named ``<proj>__<stem>.bc``."""
    entries: list[tuple[str, Path]] = []
    for proj_dir in sorted(bench_root.iterdir()):
        if not proj_dir.is_dir():
            continue
        original = proj_dir / "original"
        if not original.is_dir():
            continue
        for bc in sorted(original.glob("*.bc")):
            entries.append((f"{proj_dir.name}__{bc.stem}.bc", bc))
    return entries


def is_test_file(path: Path) -> bool:
    """A test copy from the current suite or the old per-PR copies."""
    if path.suffix != ".ll":
        return False
    return path.name.startswith(TEST_PREFIXES) or bool(
        LEGACY_TEST_RE.match(path.name)
    )


def parses(opt: Path, path: Path) -> bool:
    proc = subprocess.run(
        [str(opt), "-S", "-disable-output", str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        first = next(iter(proc.stderr.splitlines()), "")
        print(f"  SKIP {path}: {first}", file=sys.stderr)
        return False
    return True


def collect_test_suite(corpus: Path, opt: Path, jobs: int) -> tuple[int, int]:
    """Copy the parseable top-level InstCombine and InstSimplify tests."""
    entries: list[tuple[str, Path]] = []
    for suite in TEST_SUITES:
        directory = LLVM_TEST_DIR / suite
        for source in sorted(directory.glob("*.ll")):
            entries.append((f"{suite}__{source.name}", source))
    print(f"== test suite: {len(entries)} files from {LLVM_TEST_DIR} ==")

    def one(item: tuple[str, Path]) -> tuple[str, Path, bool]:
        name, source = item
        return name, source, parses(opt, source)

    ok = skipped = 0
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for name, source, valid in pool.map(one, entries):
            if not valid:
                skipped += 1
                continue
            shutil.copy2(source, corpus / name)
            ok += 1
    return ok, skipped


def copy_original(
    bench_root: Path, corpus: Path, modules_from: Path | None, jobs: int, opt: Path
) -> tuple[int, list[str]]:
    """Copy raw benchmark modules, preserving the preprocessed naming."""
    if modules_from is not None:
        sources = sorted(modules_from.glob("*.bc"))
        if not sources:
            sys.exit(f"no .bc modules in {modules_from}")
        ok = 0
        failures: list[str] = []
        for source in sources:
            proj, _, rest = source.name.partition("__")
            stem = Path(rest).stem
            src = bench_root / proj / "original" / f"{stem}.bc"
            if not src.is_file():
                failures.append(str(src))
                continue
            shutil.copy2(src, corpus / source.name)
            ok += 1
        return ok, failures

    entries = module_entries(bench_root)
    print(f"== copy {len(entries)} raw modules from {bench_root} ==")

    def one(item: tuple[str, Path]) -> tuple[str, Path, bool]:
        name, source = item
        return name, source, parses(opt, source)

    ok = 0
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for name, source, valid in pool.map(one, entries):
            if not valid:
                failures.append(str(source))
                continue
            shutil.copy2(source, corpus / name)
            ok += 1
    return ok, failures


def preprocess_benchmark(
    bench_root: Path, corpus: Path, passes: str, jobs: int, opt: Path
) -> tuple[int, list[str]]:
    """Run every ``original/*.bc`` through ``passes`` into the corpus."""
    entries = module_entries(bench_root)
    print(f"== preprocess {len(entries)} modules from {bench_root} ==")

    def one(item: tuple[int, tuple[str, Path]], tmp: Path) -> tuple[str, bool, str]:
        index, (name, src) = item
        tmp_bc = tmp / f"{index}.bc"
        env = dict(os.environ)
        env.pop("METAPHIR_EVAL_ENABLED", None)  # keep the folds disabled
        env.pop("METAPHIR_EVAL_ALL_FIRINGS", None)
        proc = subprocess.run(
            [str(opt), f"-passes={passes}", str(src), "-o", str(tmp_bc)],
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )
        if proc.returncode != 0:
            first = next(iter(proc.stderr.splitlines()), "")
            return str(src), False, f"  PREPROCESS FAILED {src}: {first}"
        shutil.move(str(tmp_bc), corpus / name)
        return str(src), True, ""

    ok = 0
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="metaphir-prep-") as tmp:
        tmp_path = Path(tmp)
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            results = pool.map(lambda item: one(item, tmp_path), enumerate(entries))
            for source, success, message in results:
                if success:
                    ok += 1
                else:
                    print(message, file=sys.stderr)
                    failures.append(source)
    return ok, failures


def clear_corpus(corpus: Path, tests_only: bool) -> None:
    """Fresh corpus: always drop old tests; drop everything on a full run."""
    if corpus.is_dir():
        for old in corpus.iterdir():
            if old.is_file() and (not tests_only or is_test_file(old)):
                old.unlink()
    corpus.mkdir(parents=True, exist_ok=True)


def relative_failures(failures: list[str], bench_root: Path) -> set[str]:
    """The failing modules as ``<proj>/<file>``, for the known-failure check."""
    result = set()
    for failure in failures:
        try:
            result.add(str(Path(failure).relative_to(bench_root)))
        except ValueError:
            result.add(failure)
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--kind", required=True, choices=sorted(KINDS))
    ap.add_argument("--corpus", type=Path)
    ap.add_argument(
        "--bench-root",
        type=Path,
        default=os.environ.get(BENCH_ROOT_ENV),
        help=f"llvm-opt-benchmark root (default: ${BENCH_ROOT_ENV})",
    )
    ap.add_argument("--opt", type=Path, default=OPT)
    ap.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 1)
    ap.add_argument(
        "--passes",
        help="override the pipeline for this kind (not allowed with original)",
    )
    ap.add_argument(
        "--modules-from",
        type=Path,
        help="for original: copy exactly the .bc modules of this prepared "
        "corpus (default: eval/corpus-o2-final when it exists)",
    )
    ap.add_argument(
        "--expect-modules",
        type=int,
        default=EXPECTED_MODULES,
        help=f"fail unless this many benchmark modules are copied "
        f"(default: {EXPECTED_MODULES})",
    )
    ap.add_argument(
        "--allow-known-failures",
        action="store_true",
        help="exit 0 when the only failures are the 2 known velox modules",
    )
    ap.add_argument(
        "--tests-only",
        action="store_true",
        help="only refresh the test copies; keep the benchmark modules",
    )
    args = ap.parse_args()

    if args.jobs < 1:
        ap.error("--jobs must be at least 1")
    if not args.opt.is_file():
        sys.exit(f"opt not found: {args.opt} (is the Release LLVM built?)")
    if args.kind == "original" and args.passes:
        ap.error("--passes is not allowed with --kind original")
    corpus = args.corpus or REPO / "eval" / f"corpus-{args.kind}"
    passes = args.passes or KINDS[args.kind]
    if passes is not None:
        passes = resolve_passes(passes, args.opt)

    if not args.tests_only:
        if args.bench_root is None:
            ap.error(f"--bench-root or ${BENCH_ROOT_ENV} is required")
        if not args.bench_root.is_dir():
            sys.exit(f"benchmark root not found: {args.bench_root}")

    clear_corpus(corpus, args.tests_only)

    tests, skipped = collect_test_suite(corpus, args.opt, args.jobs)
    print(f"  copied {tests} test file(s), skipped {skipped}")

    if args.tests_only:
        return 0

    if args.kind == "original":
        modules_from = args.modules_from
        if modules_from is None:
            candidate = REPO / "eval" / "corpus-o2-final"
            modules_from = candidate if candidate.is_dir() else None
        ok, failures = copy_original(
            args.bench_root, corpus, modules_from, args.jobs, args.opt
        )
    else:
        ok, failures = preprocess_benchmark(
            args.bench_root, corpus, passes, args.jobs, args.opt
        )

    print(f"  prepared {ok} benchmark modules, {len(failures)} failed")
    print(f"  corpus: {corpus}")

    if ok != args.expect_modules:
        print(
            f"error: expected {args.expect_modules} benchmark modules, got {ok}",
            file=sys.stderr,
        )
        return 1
    if failures:
        relative = relative_failures(failures, args.bench_root)
        if args.allow_known_failures and relative <= KNOWN_FAILURES:
            print(f"  known preprocessing failures: {', '.join(sorted(relative))}")
            return 0
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
