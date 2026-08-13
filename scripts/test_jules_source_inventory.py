#!/usr/bin/env python3
"""Focused regression tests for the source-page inventory transport gate."""

from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("validate_jules_source_inventory.py")
SPEC = importlib.util.spec_from_file_location("source_inventory_validator", MODULE_PATH)
assert SPEC and SPEC.loader
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


def ticket() -> dict[str, object]:
    return {
        "ticket_id": "source-page:math:sets:1:p0012:abcdef123456",
        "subject": "math",
        "topic_key": "sets",
        "question_pdf": "1.pdf",
        "pdf_page": 12,
        "page_file": "QUESTION_math_01_sets_1_p0012.jpg",
        "source_pdf_sha256": "a" * 64,
        "page_sha256": "b" * 64,
    }


def valid_row() -> dict[str, object]:
    return {
        **ticket(),
        "page_kind": "question",
        "printed_page_label": "10",
        "numbered_questions": list(range(1, 17)),
        "first_global_question": 1,
        "last_global_question": 16,
        "continues_from_previous": False,
        "continues_to_next": False,
        "notes": [],
    }


class SourceInventoryValidatorTest(unittest.TestCase):
    def test_accepts_exact_hash_bound_row(self) -> None:
        VALIDATOR.validate_row(valid_row(), ticket(), 1)

    def test_rejects_source_binding_mismatch(self) -> None:
        row = valid_row()
        row["page_sha256"] = "c" * 64
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "source binding mismatch"):
            VALIDATOR.validate_row(row, ticket(), 1)

    def test_rejects_non_ascii_printed_page_label(self) -> None:
        row = valid_row()
        row["printed_page_label"] = "۱۰"
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "non-ASCII numeral"):
            VALIDATOR.validate_row(row, ticket(), 1)

    def test_rejects_lesson_page_with_bank_numbers(self) -> None:
        row = valid_row()
        row["page_kind"] = "lesson"
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "cannot start bank questions"):
            VALIDATOR.validate_row(row, ticket(), 1)

    def test_rejects_notes_encoded_as_json_string(self) -> None:
        row = valid_row()
        row["notes"] = "[]"
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "expected string array"):
            VALIDATOR.validate_row(row, ticket(), 1)

    def test_rejects_empty_note_sentinel_inside_array(self) -> None:
        row = valid_row()
        row["notes"] = ["[]"]
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "sentinel is forbidden"):
            VALIDATOR.validate_row(row, ticket(), 1)

    def test_cli_rejects_reordered_rows(self) -> None:
        second_ticket = copy.deepcopy(ticket())
        second_ticket.update(
            {
                "ticket_id": "source-page:math:sets:1:p0013:123456abcdef",
                "pdf_page": 13,
                "page_file": "QUESTION_math_01_sets_1_p0013.jpg",
                "page_sha256": "c" * 64,
            }
        )
        second_row = {
            **second_ticket,
            "page_kind": "question",
            "printed_page_label": "11",
            "numbered_questions": list(range(17, 33)),
            "first_global_question": 17,
            "last_global_question": 32,
            "continues_from_previous": False,
            "continues_to_next": False,
            "notes": [],
        }
        batch = {
            "prompt_contract": "gauss-source-inventory-v1",
            "batch_id": "test",
            "prompt_sha256": "d" * 64,
            "item_count": 2,
            "tickets": [ticket(), second_ticket],
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            batch_path = root / "batch.json"
            output_path = root / "output.jsonl"
            batch_path.write_text(json.dumps(batch), encoding="utf-8")
            output_path.write_text(
                "\n".join(json.dumps(row, ensure_ascii=False) for row in [second_row, valid_row()])
                + "\n",
                encoding="utf-8",
            )
            original = VALIDATOR.parse_args
            try:
                VALIDATOR.parse_args = lambda: type(
                    "Args", (), {"batch": batch_path, "output": output_path, "report": None}
                )()
                with self.assertRaisesRegex(VALIDATOR.ValidationError, "source binding mismatch"):
                    VALIDATOR.main()
            finally:
                VALIDATOR.parse_args = original


if __name__ == "__main__":
    unittest.main()
