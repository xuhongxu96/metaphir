"""Tests for publish.py: per-corpus pruning and config upsert.

  python3 -m unittest web/scripts/test_publish.py
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from publish import stale_builds, upsert_config  # noqa: E402


def file(corpus: str, build: str, name: str, uploaded_at: str) -> dict:
    return {
        "type": "file",
        "path": f"builds/{corpus}/{build}/{name}",
        "uploaded_at": f"2026-09-{uploaded_at}+00:00",
    }


def build(
    corpus: str, name: str, day: str, manifest: bool = True
) -> list[dict]:
    files = [file(corpus, name, "packs.bin", f"{day}T10:00:00")]
    if manifest:
        files.append(file(corpus, name, "manifest.json", f"{day}T11:00:00"))
    return files


class StaleBuilds(unittest.TestCase):
    corpus = "o2-final"

    def test_keeps_the_most_recent(self):
        listing = [
            *build(self.corpus, "a", "01"),
            *build(self.corpus, "b", "02"),
            *build(self.corpus, "c", "03"),
            *build(self.corpus, "d", "04"),
        ]
        stale, incomplete = stale_builds(listing, keep=3, current="d", corpus=self.corpus)
        self.assertEqual(stale, ["a"])
        self.assertEqual(incomplete, [])

    def test_by_when_the_manifest_was_uploaded_not_by_name(self):
        listing = [
            *build(self.corpus, "z", "01"),
            *build(self.corpus, "a", "04"),
            *build(self.corpus, "m", "02"),
            *build(self.corpus, "b", "03"),
        ]
        stale, _ = stale_builds(listing, keep=2, current="a", corpus=self.corpus)
        self.assertEqual(stale, ["m", "z"])

    def test_keeps_the_current_build_whatever_its_date(self):
        listing = [
            *build(self.corpus, "old", "01"),
            *build(self.corpus, "b", "02"),
            *build(self.corpus, "c", "03"),
            *build(self.corpus, "d", "04"),
        ]
        stale, _ = stale_builds(listing, keep=3, current="old", corpus=self.corpus)
        self.assertEqual(stale, ["b"])

    def test_leaves_incomplete_builds_but_reports_them(self):
        listing = [
            *build(self.corpus, "a", "01"),
            *build(self.corpus, "b", "02", manifest=False),
            *build(self.corpus, "c", "03"),
        ]
        stale, incomplete = stale_builds(listing, keep=1, current="c", corpus=self.corpus)
        self.assertEqual(stale, ["a"])
        self.assertEqual(incomplete, ["b"])

    def test_ignores_other_corpora_and_legacy_paths(self):
        listing = [
            *build("original", "a", "01"),
            *build(self.corpus, "b", "02"),
            {"type": "file", "path": "builds/legacy/packs.bin", "uploaded_at": None},
            {"type": "file", "path": "README.md", "uploaded_at": None},
        ]
        stale, incomplete = stale_builds(listing, keep=1, current="b", corpus=self.corpus)
        self.assertEqual((stale, incomplete), ([], []))

    def test_another_corpus_is_never_stale(self):
        listing = [
            *build("original", "a", "01"),
            *build("original", "b", "02"),
            *build(self.corpus, "c", "03"),
        ]
        stale, incomplete = stale_builds(listing, keep=1, current="c", corpus=self.corpus)
        self.assertEqual((stale, incomplete), ([], []))


class UpsertConfig(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "config.json"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def read(self) -> dict:
        return json.loads(self.path.read_text())

    def test_preserves_other_entries_and_default(self):
        self.path.write_text(
            json.dumps(
                {
                    "default": "original",
                    "corpora": [
                        {"id": "original", "label": "Original", "data": "old"}
                    ],
                }
            )
        )
        upsert_config(self.path, "o2-final", "new", "O2 final", "desc", False)
        config = self.read()
        self.assertEqual(config["default"], "original")
        self.assertEqual(config["corpora"][0]["data"], "old")
        self.assertEqual(
            config["corpora"][1],
            {"id": "o2-final", "label": "O2 final", "description": "desc", "data": "new"},
        )

    def test_updates_existing_and_can_become_default(self):
        self.path.write_text(
            json.dumps(
                {
                    "default": "original",
                    "corpora": [
                        {"id": "original", "label": "Original", "data": "old"},
                        {"id": "o2-final", "label": "Old label", "data": "older"},
                    ],
                }
            )
        )
        upsert_config(self.path, "o2-final", "new", "O2 final", None, True)
        config = self.read()
        self.assertEqual(config["default"], "o2-final")
        self.assertEqual(len(config["corpora"]), 2)
        self.assertEqual(config["corpora"][1]["data"], "new")
        self.assertEqual(config["corpora"][1]["label"], "O2 final")
        self.assertEqual(config["corpora"][0]["data"], "old")

    def test_legacy_data_becomes_a_list(self):
        self.path.write_text(json.dumps({"data": "legacy"}))
        upsert_config(self.path, "o2-final", "new", None, None, False)
        config = self.read()
        self.assertNotIn("data", config)
        self.assertEqual(config["default"], "o2-final")
        self.assertEqual(config["corpora"], [{"id": "o2-final", "label": "o2-final", "data": "new"}])


if __name__ == "__main__":
    unittest.main()
