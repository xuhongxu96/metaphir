#!/usr/bin/env python3
"""Tests for check_fold_plugin.py."""

from __future__ import annotations

import unittest

from check_fold_plugin import blocks, first_missing


class BlocksTest(unittest.TestCase):
    def test_skips_lines_that_differ_and_blanks(self) -> None:
        text = "x\n  // BEGIN pr1,pr2 a/b.cpp\n  f() { // differs\n\n    int y;\n  // END\nz\n"
        self.assertEqual(blocks(text), [("pr1,pr2", "a/b.cpp", ["int y;"])])


class FirstMissingTest(unittest.TestCase):
    def test_in_order(self) -> None:
        self.assertIsNone(first_missing(["a", "c"], ["a", "b", "c"]))

    def test_out_of_order(self) -> None:
        self.assertEqual(first_missing(["c", "a"], ["a", "b", "c"]), "a")

    def test_absent(self) -> None:
        self.assertEqual(first_missing(["d"], ["a"]), "d")


if __name__ == "__main__":
    unittest.main()
