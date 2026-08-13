#!/usr/bin/env python3
"""Focused coverage tests for source-index merging."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("merge_jules_source_indexes.py")
SPEC = importlib.util.spec_from_file_location("source_index_merger", MODULE_PATH)
assert SPEC and SPEC.loader
MERGER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MERGER)


class SourceIndexMergeTest(unittest.TestCase):
    def test_exact_coverage_accepts_complete_subject(self) -> None:
        MERGER.exact_coverage(list(range(1, 2043)), "math", "question")

    def test_exact_coverage_rejects_duplicate_and_gap(self) -> None:
        values = list(range(1, 2043))
        values[100] = 100
        with self.assertRaisesRegex(MERGER.MergeError, "duplicates=.*100.*missing=.*101"):
            MERGER.exact_coverage(values, "math", "question")

    def test_topic_ranges_require_contiguous_source_numbers(self) -> None:
        rows = [
            {
                "subject": "math",
                "topic_key": "sets",
                "question_pdf": "1.pdf",
                "numbered_questions": [1, 2, 4],
            }
        ]
        with self.assertRaisesRegex(MERGER.MergeError, "non-contiguous topic range"):
            MERGER.topic_ranges(rows)

    def test_topic_ranges_capture_real_boundaries(self) -> None:
        rows = [
            {
                "subject": "math",
                "topic_key": "sets",
                "question_pdf": "1.pdf",
                "numbered_questions": list(range(1, 33)),
            },
            {
                "subject": "math",
                "topic_key": "patterns_sequences",
                "question_pdf": "2.pdf",
                "numbered_questions": list(range(33, 101)),
            },
        ]
        ranges = MERGER.topic_ranges(rows)
        self.assertEqual((ranges[0]["first_question"], ranges[0]["last_question"]), (1, 32))
        self.assertEqual((ranges[1]["first_question"], ranges[1]["last_question"]), (33, 100))


if __name__ == "__main__":
    unittest.main()
