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
    tool.write_text("#!/bin/sh\n" + body.replace("$DIR", str(directory)))
    tool.chmod(0o755)
    return tool


class RunMetaphirTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.pattern = self.dir / "p.mpir"
        self.files = [self.dir / "a.bc", self.dir / "b.bc"]
        self.index = self.dir / "corpus.mpidx"
        self.saved_tool = run_eval.METAPHIR_MATCH

    def tearDown(self) -> None:
        run_eval.METAPHIR_MATCH = self.saved_tool
        self.tmp.cleanup()

    def run_tool(self, body: str, index: Path | None = None):
        run_eval.METAPHIR_MATCH = write_tool(self.dir, body)
        with redirect_stdout(io.StringIO()):
            return run_eval.run_metaphir(self.pattern, self.files, 3, index)

    def test_functions_are_collected(self) -> None:
        funcs, errors = self.run_tool(
            'echo "$@" > "$DIR/args"\n'
            'cat "$(echo "$@" | sed "s/.*@//")" > "$DIR/files"\n'
            'echo "$DIR/a.bc\t@f\t{?x = %r}"\n'
            'echo "$DIR/a.bc\t@f\t{?x = %s}"\n'
            'echo "$DIR/b.bc\t@g\t{}"\n',
            self.index,
        )
        self.assertEqual(funcs, {("a.bc", "f"), ("b.bc", "g")})
        self.assertEqual(errors, [])
        self.assertEqual(
            (self.dir / "args").read_text().split()[:6],
            ["--matches-only", "-j", "3", "--index", str(self.index), str(self.pattern)],
        )
        self.assertEqual(
            (self.dir / "files").read_text().splitlines(),
            [f'"{f}"' for f in self.files],
        )

    def test_module_error_is_reported_with_the_other_functions(self) -> None:
        funcs, errors = self.run_tool(
            'echo "$DIR/a.bc\t@f\t{}"\n'
            'echo "metaphir-match: error: $DIR/b.bc: boom" >&2\n'
            "exit 1\n"
        )
        self.assertEqual(funcs, {("a.bc", "f")})
        self.assertEqual(len(errors), 1)
        self.assertIn("b.bc: boom", errors[0])

    def test_crash_is_an_error(self) -> None:
        _, errors = self.run_tool('echo "$DIR/a.bc\t@f\t{}"\nkill -SEGV $$\n')
        self.assertEqual(len(errors), 1)
        self.assertIn("rc=-11", errors[0])


class ResponseFileTest(unittest.TestCase):
    def test_quotes_paths(self) -> None:
        self.assertEqual(
            run_eval.response_file_line(Path('/a b/c"d\\e.bc')),
            '"/a b/c\\"d\\\\e.bc"\n',
        )


class FunctionsTest(unittest.TestCase):
    def test_round_trip(self) -> None:
        funcs = {("b.bc", "g"), ("a.bc", "f")}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "x.functions"
            run_eval.save_functions(path, funcs)
            self.assertEqual(path.read_text(), "a.bc\tf\nb.bc\tg\n")
            self.assertEqual(run_eval.load_functions(path), funcs)


class ScoresTest(unittest.TestCase):
    def test_scores(self) -> None:
        s = run_eval.scores({1, 2, 3}, {2, 3, 4, 5})
        self.assertEqual((s["TP"], s["FP"], s["FN"]), (2, 2, 1))
        self.assertAlmostEqual(s["f1"], 4 / 7)

    def test_empty_sets_are_exact(self) -> None:
        s = run_eval.scores(set(), set())
        self.assertEqual((s["precision"], s["recall"], s["f1"]), (1.0, 1.0, 1.0))


class FoldIdTest(unittest.TestCase):
    def test_suffixes_belong_to_their_pr_only(self) -> None:
        self.assertTrue(run_eval.fold_id_matches("pr213313_and", "pr213313"))
        self.assertTrue(run_eval.fold_id_matches("pr213313", "pr213313"))
        self.assertFalse(run_eval.fold_id_matches("pr2133130", "pr213313"))


if __name__ == "__main__":
    unittest.main()
