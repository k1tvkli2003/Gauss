#!/usr/bin/env python3
"""Focused regression tests for solution/key page inventory validation."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("validate_jules_answer_inventory.py")
SPEC = importlib.util.spec_from_file_location("answer_inventory_validator", MODULE_PATH)
assert SPEC and SPEC.loader
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


def ticket(role: str = "solution") -> dict[str, object]:
    return {
        "ticket_id": f"answer-page:math:{role}:19:p0001:abcdef123456",
        "subject": "math",
        "role": role,
        "answer_pdf": "19.pdf",
        "pdf_page": 1,
        "page_file": f"{role.upper()}_math_19_p0001.jpg",
        "source_pdf_sha256": "a" * 64,
        "page_sha256": "b" * 64,
    }


def row(role: str = "solution") -> dict[str, object]:
    values = list(range(1, 15))
    return {
        **ticket(role),
        "page_kind": role,
        "printed_page_label": "1",
        "numbered_items": values,
        "first_global_question": values[0],
        "last_global_question": values[-1],
        "continues_from_previous": False,
        "continues_to_next": False,
        "notes": [],
    }


class AnswerInventoryValidatorTest(unittest.TestCase):
    def test_accepts_solution_page(self) -> None:
        VALIDATOR.validate_row(row(), ticket(), 1)

    def test_accepts_key_page(self) -> None:
        VALIDATOR.validate_row(row("key"), ticket("key"), 1)

    def test_rejects_key_solution_continuation(self) -> None:
        value = row("key")
        value["continues_to_next"] = True
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "key pages cannot"):
            VALIDATOR.validate_row(value, ticket("key"), 1)

    def test_rejects_out_of_range_question(self) -> None:
        value = row()
        value["numbered_items"] = [2043]
        value["first_global_question"] = 2043
        value["last_global_question"] = 2043
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "outside 1..2042"):
            VALIDATOR.validate_row(value, ticket(), 1)

    def test_rejects_role_mismatch(self) -> None:
        value = row()
        value["page_kind"] = "key"
        with self.assertRaisesRegex(VALIDATOR.ValidationError, "conflicts with ticket role"):
            VALIDATOR.validate_row(value, ticket(), 1)


if __name__ == "__main__":
    unittest.main()
