"""Unit tests for prepare_corpus.py (run with `python3 -m unittest`)."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

import prepare_corpus
from prs import PR


class CollectPRTestsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.tests = root / "Transforms"
        (self.tests / "InstCombine").mkdir(parents=True)
        (self.tests / "InstCombine" / "shared.ll").write_text("; shared\n")
        (self.tests / "InstCombine" / "own.ll").write_text("; own\n")
        self.corpus = root / "corpus"
        self.corpus.mkdir()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def collect(self, prs: dict[str, PR]) -> int:
        with (
            mock.patch.object(prepare_corpus, "LLVM_TEST_DIR", self.tests),
            mock.patch.object(prepare_corpus, "PRS", prs),
            redirect_stdout(io.StringIO()),
        ):
            return prepare_corpus.collect_pr_tests(self.corpus)

    def test_shared_test_file_is_copied_once(self) -> None:
        prs = {
            "pr2": PR((), ("InstCombine/shared.ll", "InstCombine/own.ll")),
            "pr1": PR((), ("InstCombine/shared.ll",)),
        }
        self.assertEqual(self.collect(prs), 2)
        # The first PR listing a file names its only copy.
        self.assertEqual(
            sorted(p.name for p in self.corpus.iterdir()),
            ["pr2__own.ll", "pr2__shared.ll"],
        )
        self.assertEqual((self.corpus / "pr2__shared.ll").read_text(), "; shared\n")

    def test_real_pr_table_has_no_duplicate_copies(self) -> None:
        # Every upstream test named in prs.py is copied exactly once.
        names = {rel for entry in prepare_corpus.PRS.values() for rel in entry.tests}
        for rel in names:
            path = self.tests / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"; {rel}\n")
        self.assertEqual(self.collect(prepare_corpus.PRS), len(names))
        self.assertEqual(len(list(self.corpus.iterdir())), len(names))


if __name__ == "__main__":
    unittest.main()
