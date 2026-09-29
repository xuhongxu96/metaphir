"""Unit tests for run_eval.py (run with `python3 -m unittest` in this dir)."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import run_eval


def write_tool(directory: Path, body: str) -> Path:
    tool = directory / "fake-metaphir-match"
    tool.write_text("#!/bin/sh\n" + body)
    tool.chmod(0o755)
    return tool


class CollectPatternsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.pattern = self.dir / "p.mpir"
        self.pattern.write_text("")
        self.files = [self.dir / "a.bc", self.dir / "b.bc"]
        for f in self.files:
            f.write_text("")
        self.saved_tool = run_eval.METAPHIR_MATCH

    def tearDown(self) -> None:
        run_eval.METAPHIR_MATCH = self.saved_tool
        self.tmp.cleanup()

    def collect(self) -> bool:
        with redirect_stdout(io.StringIO()):
            return run_eval.collect_patterns(
                self.files, "prX", [self.pattern], self.dir, jobs=2
            )

    def test_tool_failure_is_reported_not_treated_as_no_match(self) -> None:
        run_eval.METAPHIR_MATCH = write_tool(
            self.dir, 'case "$2" in *b.bc) echo boom >&2; exit 1;; esac\n'
        )
        self.assertFalse(self.collect())
        failures = (self.dir / "prX_P_failures.txt").read_text()
        self.assertIn("b.bc", failures)
        self.assertIn("boom", failures)
        self.assertNotIn("a.bc", failures)

    def test_anchors_are_collected(self) -> None:
        run_eval.METAPHIR_MATCH = write_tool(
            self.dir, 'echo "target 0: @f"\necho "  { ?anch = %r }"\n'
        )
        self.assertTrue(self.collect())
        anchors = run_eval.load_anchors(self.dir / "prX_P.anchors")
        self.assertEqual(anchors, {("a.bc", "f", "r"), ("b.bc", "f", "r")})
        self.assertFalse((self.dir / "prX_P_failures.txt").exists())


class MetricsTest(unittest.TestCase):
    def test_identical_empty_sets_have_no_difference(self) -> None:
        out = io.StringIO()
        with redirect_stdout(out):
            run_eval.print_metrics(set(), set(), "x")
        self.assertIn("diff_rate=0.0000", out.getvalue())


if __name__ == "__main__":
    unittest.main()
