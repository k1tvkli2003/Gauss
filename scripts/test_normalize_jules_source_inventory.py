#!/usr/bin/env python3
"""Focused tests for narrow Jules source-inventory transport normalization."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("normalize_jules_source_inventory.py")
SPEC = importlib.util.spec_from_file_location("source_inventory_normalizer", MODULE_PATH)
assert SPEC and SPEC.loader
NORMALIZER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NORMALIZER)


class SourceInventoryNormalizerTest(unittest.TestCase):
    def test_normalizes_exact_string_sentinel(self) -> None:
        source = {"ticket_id": "a", "notes": "[]", "page_kind": "question"}
        normalized, changed = NORMALIZER.normalize_row(source, 1)
        self.assertTrue(changed)
        self.assertEqual(normalized["notes"], [])
        self.assertEqual(normalized["page_kind"], source["page_kind"])
        self.assertEqual(source["notes"], "[]")

    def test_normalizes_exact_single_item_array_sentinel(self) -> None:
        normalized, changed = NORMALIZER.normalize_row(
            {"ticket_id": "a", "notes": ["[]"]}, 1
        )
        self.assertTrue(changed)
        self.assertEqual(normalized["notes"], [])

    def test_preserves_real_notes_without_interpreting_them(self) -> None:
        source = {"ticket_id": "a", "notes": ["printed number is unreadable"]}
        normalized, changed = NORMALIZER.normalize_row(source, 1)
        self.assertFalse(changed)
        self.assertEqual(normalized, source)

    def test_rejects_other_string_values(self) -> None:
        with self.assertRaisesRegex(NORMALIZER.NormalizationError, "unsupported string"):
            NORMALIZER.normalize_row({"ticket_id": "a", "notes": "none"}, 1)


if __name__ == "__main__":
    unittest.main()
