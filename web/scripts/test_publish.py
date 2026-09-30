"""Tests for publish.py: which builds the bucket keeps.

  python3 -m unittest web/scripts/test_publish.py
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from publish import stale_builds  # noqa: E402


def file(build: str, name: str, uploaded_at: str) -> dict:
    return {
        "type": "file",
        "path": f"builds/{build}/{name}",
        "uploaded_at": f"2026-09-{uploaded_at}+00:00",
    }


def build(name: str, day: str, manifest: bool = True) -> list[dict]:
    files = [file(name, "packs.bin", f"{day}T10:00:00")]
    if manifest:
        files.append(file(name, "manifest.json", f"{day}T11:00:00"))
    return files


class StaleBuilds(unittest.TestCase):
    def test_keeps_the_most_recent(self):
        listing = [
            *build("a", "01"), *build("b", "02"), *build("c", "03"), *build("d", "04")
        ]
        stale, incomplete = stale_builds(listing, keep=3, current="d")
        self.assertEqual(stale, ["a"])
        self.assertEqual(incomplete, [])

    def test_by_when_the_manifest_was_uploaded_not_by_name(self):
        listing = [
            *build("z", "01"), *build("a", "04"), *build("m", "02"), *build("b", "03")
        ]
        stale, _ = stale_builds(listing, keep=2, current="a")
        self.assertEqual(stale, ["m", "z"])

    def test_keeps_the_current_build_whatever_its_date(self):
        # The build just published stays, whatever the dates say.
        listing = [
            *build("old", "01"), *build("b", "02"), *build("c", "03"), *build("d", "04")
        ]
        stale, _ = stale_builds(listing, keep=3, current="old")
        self.assertEqual(stale, ["b"])

    def test_leaves_incomplete_builds_but_reports_them(self):
        listing = [
            *build("a", "01"), *build("b", "02", manifest=False), *build("c", "03")
        ]
        stale, incomplete = stale_builds(listing, keep=1, current="c")
        self.assertEqual(stale, ["a"])
        self.assertEqual(incomplete, ["b"])

    def test_ignores_files_outside_builds(self):
        other = {"type": "file", "path": "README.md", "uploaded_at": None}
        listing = [*build("a", "01"), other]
        self.assertEqual(stale_builds(listing, keep=3, current="a"), ([], []))


if __name__ == "__main__":
    unittest.main()
