"""Unit tests for run_baseline.py (run with `python3 -m unittest` in this dir)."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import run_baseline


class ParseDaggrepTest(unittest.TestCase):
    def test_functions_are_collected(self) -> None:
        out = "/c/a.bc\t@f\n/c/b.bc\t@g\n/c/a.bc\t@f\n"
        self.assertEqual(
            run_baseline.parse_daggrep(out), {("a.bc", "f"), ("b.bc", "g")}
        )

    def test_no_output_is_no_function(self) -> None:
        self.assertEqual(run_baseline.parse_daggrep(""), set())


class PatternFilesTest(unittest.TestCase):
    def test_alternatives_belong_to_their_pr_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            for name in ("pr1.ll", "pr1_a.ll", "pr12.ll", "pr1x.ll"):
                (d / name).write_text("")
            with mock.patch.dict(run_baseline.PATTERN_DIRS, {"daggrep": (d, ".ll")}):
                files = run_baseline.pattern_files("daggrep", "pr1")
        self.assertEqual([f.name for f in files], ["pr1.ll", "pr1_a.ll"])


class CollectTest(unittest.TestCase):
    def test_union_over_alternatives_and_timing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            pats = d / "pats"
            pats.mkdir()
            for name in ("pr1_a.ll", "pr1_b.ll"):
                (pats / name).write_text("")
            found = {
                "pr1_a": ({("m.bc", "f")}, []),
                "pr1_b": ({("m.bc", "f"), ("m.bc", "g")}, []),
            }
            fake = lambda pattern, files, jobs: found[pattern.stem]  # noqa: E731
            with (
                mock.patch.dict(run_baseline.PATTERN_DIRS, {"daggrep": (pats, ".ll")}),
                mock.patch.dict(run_baseline.RUNNERS, {"daggrep": fake}),
            ):
                ok = run_baseline.collect("daggrep", "pr1", [d / "m.bc"], d, 1, 1)
            self.assertTrue(ok)
            self.assertEqual(
                (d / "pr1_P.functions").read_text(), "m.bc\tf\nm.bc\tg\n"
            )
            timing = (d / "pr1_P_timing.txt").read_text()
            self.assertIn("seconds[pr1_a]=", timing)
            self.assertIn("P_functions=2", timing)

    def test_failures_are_recorded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            (d / "pr1.ll").write_text("")
            fake = lambda pattern, files, jobs: (set(), ["boom"])  # noqa: E731
            with (
                mock.patch.dict(run_baseline.PATTERN_DIRS, {"daggrep": (d, ".ll")}),
                mock.patch.dict(run_baseline.RUNNERS, {"daggrep": fake}),
            ):
                ok = run_baseline.collect("daggrep", "pr1", [], d, 1, 1)
            self.assertFalse(ok)
            self.assertEqual((d / "pr1_P_failures.txt").read_text(), "boom\n")


if __name__ == "__main__":
    unittest.main()
