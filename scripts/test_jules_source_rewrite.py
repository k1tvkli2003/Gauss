#!/usr/bin/env python3
"""Focused gates for the source-index-bound Jules rewrite pipeline."""

from __future__ import annotations

import copy
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import prepare_jules_source_rewrite_wave as prepare


SCRIPT_DIR = Path(__file__).resolve().parent
VALIDATOR = SCRIPT_DIR / "validate_jules_source_rewrite.py"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class SourceRewritePreparationTest(unittest.TestCase):
    def test_continuation_pages_requires_a_two_sided_handshake(self) -> None:
        start = {
            "subject": "math",
            "question_pdf": "2.pdf",
            "pdf_page": 3,
            "continues_to_next": True,
        }
        following = {
            "subject": "math",
            "question_pdf": "2.pdf",
            "pdf_page": 4,
            "continues_from_previous": True,
            "continues_to_next": False,
        }
        rows = {
            ("math", "2.pdf", 3): start,
            ("math", "2.pdf", 4): following,
        }
        self.assertEqual(
            prepare.continuation_pages(start, rows, pdf_field="question_pdf"),
            [start, following],
        )
        broken = copy.deepcopy(rows)
        broken[("math", "2.pdf", 4)]["continues_from_previous"] = False
        with self.assertRaisesRegex(ValueError, "handshake"):
            prepare.continuation_pages(start, broken, pdf_field="question_pdf")

    def test_unique_number_map_rejects_duplicate_source_assignment(self) -> None:
        rows = [
            {"subject": "math", "numbered_questions": [33]},
            {"subject": "math", "numbered_questions": [33]},
        ]
        with self.assertRaisesRegex(ValueError, "duplicate source page mapping"):
            prepare.unique_number_map(rows, numbers_field="numbered_questions")


class SourceRewriteValidatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "images").mkdir()
        self.files = {
            "QUESTION_math_2_p0003.jpg": ("question", b"question-page"),
            "QUESTION_math_2_p0004.jpg": ("question", b"question-continuation"),
            "SOLUTION_math_19_p0007.jpg": ("solution", b"solution-page"),
            "KEY_math_19_p0191.jpg": ("key", b"key-page"),
        }
        attachments = []
        for filename, (role, data) in self.files.items():
            (self.root / "images" / filename).write_bytes(data)
            attachments.append(
                {
                    "role": role,
                    "subject": "math",
                    "file": filename,
                    "source_pdf": "2.pdf" if role == "question" else "19.pdf",
                    "source_pdf_sha256": "a" * 64,
                    "indexed_page_sha256": "b" * 64,
                    "pdf_page": 3,
                    "original_size": [2480, 3507],
                    "rendered_size": [1280, 1810],
                    "sha256": sha256(data),
                    "bytes": len(data),
                }
            )
        prompt = b"source-bound prompt\n"
        (self.root / "prompt.md").write_bytes(prompt)
        self.ticket = {
            "ticket_id": "source-rewrite:q-33:" + "c" * 12,
            "question_id": "q-33",
            "source_sha256": "c" * 64,
            "subject": "math",
            "topic_key": "sets",
            "source_topic_key": "patterns_sequences",
            "question_number": 33,
            "source_files": {
                "question_pages": [
                    "QUESTION_math_2_p0003.jpg",
                    "QUESTION_math_2_p0004.jpg",
                ],
                "solution_pages": ["SOLUTION_math_19_p0007.jpg"],
                "key_page": "KEY_math_19_p0191.jpg",
            },
            "recorded_provenance": {"question_number": 33},
            "blocking_issues": ["legacy_locator_untrusted"],
        }
        binding = {
            "question_index_file": "question.jsonl",
            "question_index_sha256": "d" * 64,
            "question_index_receipt_file": "question.receipt.json",
            "question_index_receipt_sha256": "e" * 64,
            "answer_index_file": "answer.jsonl",
            "answer_index_sha256": "f" * 64,
            "answer_index_receipt_file": "answer.receipt.json",
            "answer_index_receipt_sha256": "1" * 64,
            "exact_question_coverage": True,
            "exact_answer_coverage": True,
        }
        self.batch = {
            "schema_version": 2,
            "prompt_contract": "gauss-source-rewrite-v2",
            "batch_id": "source-rewrite-test-01",
            "lane": 1,
            "question_ids": ["q-33"],
            "item_count": 1,
            "tickets": [self.ticket],
            "attachments": attachments,
            "attachment_bytes": sum(len(data) for _, data in self.files.values()),
            "max_upload_bytes": 5_000_000,
            "prompt_sha256": sha256(prompt),
            "expected_output": "source-rewrite-test-01.output.jsonl",
            "source_index_binding": binding,
        }
        self.row = {
            "ticket_id": self.ticket["ticket_id"],
            "question_id": "q-33",
            "source_sha256": "c" * 64,
            "status": "draft",
            "recovered": {
                "stem": "حاصل $1+1$ چیست؟",
                "options": ["$1$", "$2$", "$3$", "$4$"],
                "solution": "چون $1+1=2$، پاسخ گزینه $2$ است.",
            },
            "friendly": {
                "stem": "حاصل $1+1$ چیست؟",
                "options": ["$1$", "$2$", "$3$", "$4$"],
                "solution": "چون $1+1=2$، پاسخ گزینه $2$ است.",
            },
            "answer": {
                "printed_key_option": 2,
                "independent_option": 2,
                "final_option": 2,
                "agreement": True,
            },
            "media": [],
            "corrections": [],
            "evidence": {
                "question_pages": self.ticket["source_files"]["question_pages"],
                "solution_pages": self.ticket["source_files"]["solution_pages"],
                "key_page": self.ticket["source_files"]["key_page"],
                "source_recovery": "صورت و گزینه‌ها از صفحه چاپی خوانده شد.",
                "independent_derivation": "محاسبه مستقل انجام شد.",
                "scientific_review": "رابطه دوباره بررسی شد.",
                "rewrite_fidelity_review": "همه اتم‌های فنی حفظ شدند.",
            },
            "blockers": [],
        }

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_validator(self, row: dict[str, object]) -> subprocess.CompletedProcess[str]:
        batch_path = self.root / "batch.json"
        output_path = self.root / self.batch["expected_output"]
        batch_path.write_text(
            json.dumps(self.batch, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        output_path.write_text(
            json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )
        return subprocess.run(
            [sys.executable, str(VALIDATOR), str(batch_path), str(output_path)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_v2_row_passes(self) -> None:
        result = self.run_validator(self.row)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('"runtime_usable": false', result.stdout)

    def test_swapped_question_page_order_fails_closed(self) -> None:
        row = copy.deepcopy(self.row)
        row["evidence"]["question_pages"].reverse()
        result = self.run_validator(row)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("wrong ordered page list", result.stderr)

    def test_tampered_attachment_fails_closed(self) -> None:
        (self.root / "images" / "KEY_math_19_p0191.jpg").write_bytes(b"tampered")
        result = self.run_validator(self.row)
        self.assertNotEqual(result.returncode, 0)
        self.assertRegex(result.stderr, "attachment (byte|hash) mismatch")

    def test_persian_digit_fails_closed(self) -> None:
        row = copy.deepcopy(self.row)
        row["friendly"]["stem"] = "حاصل $۱+1$ چیست؟"
        result = self.run_validator(row)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("contains Persian/Arabic numeral", result.stderr)

    def test_media_requires_a_tight_crop(self) -> None:
        row = copy.deepcopy(self.row)
        row["media"] = [
            {
                "source": "question",
                "page_file": "QUESTION_math_2_p0003.jpg",
                "placement": "stem",
                "crop_box": None,
                "alt_fa": "شکل لازم سؤال",
            }
        ]
        result = self.run_validator(row)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected four integers", result.stderr)


if __name__ == "__main__":
    unittest.main()
