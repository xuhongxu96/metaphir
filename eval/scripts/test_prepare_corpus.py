"""Unit tests for prepare_corpus.py (run with `python3 -m unittest`)."""

from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

import prepare_corpus


class IsTestFileTest(unittest.TestCase):
    def test_suite_and_legacy_names(self) -> None:
        self.assertTrue(prepare_corpus.is_test_file(Path("InstCombine__add.ll")))
        self.assertTrue(prepare_corpus.is_test_file(Path("InstSimplify__cast.ll")))
        self.assertTrue(prepare_corpus.is_test_file(Path("pr204089__cast.ll")))
        self.assertFalse(prepare_corpus.is_test_file(Path("other.ll")))
        self.assertFalse(prepare_corpus.is_test_file(Path("InstCombine__add.bc")))
        self.assertFalse(prepare_corpus.is_test_file(Path("preserve-profile.ll")))


class ClearCorpusTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.corpus = Path(self.tmp.name) / "corpus"
        self.corpus.mkdir()
        for name in ("a.bc", "InstCombine__x.ll", "pr123__y.ll", "other.ll"):
            (self.corpus / name).write_text(name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_tests_only_keeps_modules(self) -> None:
        prepare_corpus.clear_corpus(self.corpus, tests_only=True)
        self.assertEqual(
            sorted(p.name for p in self.corpus.iterdir()),
            ["a.bc", "other.ll"],
        )

    def test_full_run_clears_everything(self) -> None:
        prepare_corpus.clear_corpus(self.corpus, tests_only=False)
        self.assertEqual(list(self.corpus.iterdir()), [])


class CollectTestSuiteTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.tests = root / "Transforms"
        for suite, names in {
            "InstCombine": ("a.ll", "b.ll"),
            "InstSimplify": ("a.ll", "bad.ll"),
        }.items():
            (self.tests / suite).mkdir(parents=True)
            for name in names:
                (self.tests / suite / name).write_text(f"; {suite}/{name}\n")
        self.corpus = root / "corpus"
        self.corpus.mkdir()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_copies_parseable_files_with_suite_prefix(self) -> None:
        def parses(_opt: Path, path: Path) -> bool:
            return path.name != "bad.ll"

        with (
            mock.patch.object(prepare_corpus, "LLVM_TEST_DIR", self.tests),
            mock.patch.object(prepare_corpus, "parses", parses),
            redirect_stdout(io.StringIO()),
        ):
            copied, skipped = prepare_corpus.collect_test_suite(
                self.corpus, Path("opt"), 2
            )
        self.assertEqual((copied, skipped), (3, 1))
        self.assertEqual(
            sorted(p.name for p in self.corpus.iterdir()),
            ["InstCombine__a.ll", "InstCombine__b.ll", "InstSimplify__a.ll"],
        )


class CopyOriginalTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.bench = root / "bench"
        (self.bench / "proj" / "original").mkdir(parents=True)
        (self.bench / "proj" / "original" / "a.bc").write_bytes(b"a")
        (self.bench / "proj" / "original" / "b.bc").write_bytes(b"b")
        self.prepared = root / "prepared"
        self.prepared.mkdir()
        (self.prepared / "proj__a.bc").write_bytes(b"a")
        (self.prepared / "proj__b.bc").write_bytes(b"b")
        self.corpus = root / "corpus"
        self.corpus.mkdir()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_modules_from_preserves_names(self) -> None:
        ok, failures = prepare_corpus.copy_original(
            self.bench, self.corpus, self.prepared, 1, Path("opt")
        )
        self.assertEqual((ok, failures), (2, []))
        self.assertEqual(
            sorted(p.name for p in self.corpus.iterdir()),
            ["proj__a.bc", "proj__b.bc"],
        )
        self.assertEqual((self.corpus / "proj__a.bc").read_bytes(), b"a")


if __name__ == "__main__":
    unittest.main()
