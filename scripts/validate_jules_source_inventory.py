#!/usr/bin/env python3
"""Fail-closed transport/schema validator for a Jules source-page inventory lane."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


EXPECTED_FIELDS = {
    "ticket_id",
    "subject",
    "topic_key",
    "question_pdf",
    "pdf_page",
    "page_file",
    "source_pdf_sha256",
    "page_sha256",
    "page_kind",
    "printed_page_label",
    "numbered_questions",
    "first_global_question",
    "last_global_question",
    "continues_from_previous",
    "continues_to_next",
    "notes",
}
BOUND_FIELDS = {
    "ticket_id",
    "subject",
    "topic_key",
    "question_pdf",
    "pdf_page",
    "page_file",
    "source_pdf_sha256",
    "page_sha256",
}
PAGE_KINDS = {"lesson", "question", "mixed", "blank"}
EXPECTED_COUNTS = {"math": 2042, "physics": 1630}
NON_ASCII_DIGITS = re.compile(r"[\u0660-\u0669\u06f0-\u06f9]")


class ValidationError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--report", type=Path)
    return parser.parse_args()


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValidationError(f"{path}: expected JSON object")
    return value


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8")
    if raw.startswith("\ufeff"):
        raise ValidationError(f"{path}: UTF-8 BOM is forbidden")
    if "```" in raw:
        raise ValidationError(f"{path}: Markdown fences are forbidden")
    lines = raw.splitlines()
    if not lines:
        raise ValidationError(f"{path}: empty output")
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(lines, 1):
        if not line.strip():
            raise ValidationError(f"{path}: blank line {line_number}")
        try:
            row = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValidationError(f"{path}: invalid JSON line {line_number}: {error}") from error
        if not isinstance(row, dict):
            raise ValidationError(f"{path}: line {line_number} is not an object")
        rows.append(row)
    return rows


def require_exact_fields(value: dict[str, Any], label: str) -> None:
    actual = set(value)
    if actual != EXPECTED_FIELDS:
        raise ValidationError(
            f"{label}: fields differ; missing={sorted(EXPECTED_FIELDS - actual)}, "
            f"extra={sorted(actual - EXPECTED_FIELDS)}"
        )


def validate_row(row: dict[str, Any], ticket: dict[str, Any], index: int) -> None:
    label = f"row[{index}]"
    require_exact_fields(row, label)
    for field in BOUND_FIELDS:
        if row[field] != ticket[field]:
            raise ValidationError(f"{label}.{field}: source binding mismatch")
    for field, value in row.items():
        if isinstance(value, str) and NON_ASCII_DIGITS.search(value):
            raise ValidationError(f"{label}.{field}: contains non-ASCII numeral")
    if row["page_kind"] not in PAGE_KINDS:
        raise ValidationError(f"{label}.page_kind: invalid value")
    printed = row["printed_page_label"]
    if printed is not None and (not isinstance(printed, str) or not printed.strip()):
        raise ValidationError(f"{label}.printed_page_label: expected non-empty string or null")
    if isinstance(printed, str) and NON_ASCII_DIGITS.search(printed):
        raise ValidationError(f"{label}.printed_page_label: non-ASCII numeral")
    numbers = row["numbered_questions"]
    if not isinstance(numbers, list) or any(
        isinstance(number, bool) or not isinstance(number, int) for number in numbers
    ):
        raise ValidationError(f"{label}.numbered_questions: expected integer array")
    if numbers != sorted(set(numbers)):
        raise ValidationError(f"{label}.numbered_questions: must be sorted and unique")
    maximum = EXPECTED_COUNTS[row["subject"]]
    if any(number < 1 or number > maximum for number in numbers):
        raise ValidationError(f"{label}.numbered_questions: outside subject range 1..{maximum}")
    expected_first = numbers[0] if numbers else None
    expected_last = numbers[-1] if numbers else None
    if row["first_global_question"] != expected_first:
        raise ValidationError(f"{label}.first_global_question: does not match list")
    if row["last_global_question"] != expected_last:
        raise ValidationError(f"{label}.last_global_question: does not match list")
    for field in ("continues_from_previous", "continues_to_next"):
        if not isinstance(row[field], bool):
            raise ValidationError(f"{label}.{field}: expected boolean")
    notes = row["notes"]
    if not isinstance(notes, list) or any(
        not isinstance(note, str) or not note.strip() for note in notes
    ):
        raise ValidationError(f"{label}.notes: expected string array")
    if any(note.strip().lower() in {"[]", "none", "null", "n/a", "no notes"} for note in notes):
        raise ValidationError(f"{label}.notes: empty-note sentinel is forbidden")
    if len(notes) != len(set(notes)):
        raise ValidationError(f"{label}.notes: duplicate value")
    if row["page_kind"] in {"lesson", "blank"} and numbers:
        raise ValidationError(f"{label}: lesson/blank page cannot start bank questions")
    if row["page_kind"] in {"question", "mixed"} and not numbers and not (
        row["continues_from_previous"] or row["continues_to_next"]
    ):
        raise ValidationError(f"{label}: question/mixed page has no numbered evidence")


def main() -> int:
    args = parse_args()
    batch = load_object(args.batch)
    if batch.get("prompt_contract") != "gauss-source-inventory-v1":
        raise ValidationError("unsupported prompt contract")
    tickets = batch.get("tickets")
    if not isinstance(tickets, list) or len(tickets) != batch.get("item_count"):
        raise ValidationError("batch tickets do not match item_count")
    rows = load_jsonl(args.output)
    if len(rows) != len(tickets):
        raise ValidationError(f"row count {len(rows)} != ticket count {len(tickets)}")
    for index, (row, ticket) in enumerate(zip(rows, tickets, strict=True), 1):
        validate_row(row, ticket, index)
    report = {
        "schema_version": 1,
        "batch_id": batch["batch_id"],
        "prompt_sha256": batch["prompt_sha256"],
        "row_count": len(rows),
        "numbered_question_starts": sum(len(row["numbered_questions"]) for row in rows),
        "transport_schema_hash_order_gates": "passed",
        "source_numbering_certified": False,
        "runtime_usable": False,
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, KeyError, TypeError, ValueError, ValidationError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
