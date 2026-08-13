#!/usr/bin/env python3
"""Fail-closed transport/schema validator for one solution/key inventory lane."""

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
    "role",
    "answer_pdf",
    "pdf_page",
    "page_file",
    "source_pdf_sha256",
    "page_sha256",
    "page_kind",
    "printed_page_label",
    "numbered_items",
    "first_global_question",
    "last_global_question",
    "continues_from_previous",
    "continues_to_next",
    "notes",
}
BOUND_FIELDS = {
    "ticket_id",
    "subject",
    "role",
    "answer_pdf",
    "pdf_page",
    "page_file",
    "source_pdf_sha256",
    "page_sha256",
}
PAGE_KINDS = {"solution", "key", "mixed", "blank"}
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
        raise ValidationError(f"{path}: expected object")
    return value


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8")
    if raw.startswith("\ufeff") or "```" in raw:
        raise ValidationError(f"{path}: BOM/fence forbidden")
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            raise ValidationError(f"{path}: blank line {line_number}")
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValidationError(f"{path}: invalid JSON line {line_number}: {error}") from error
        if not isinstance(value, dict):
            raise ValidationError(f"{path}: non-object line {line_number}")
        rows.append(value)
    if not rows:
        raise ValidationError(f"{path}: empty output")
    return rows


def validate_row(row: dict[str, Any], ticket: dict[str, Any], index: int) -> None:
    label = f"row[{index}]"
    actual = set(row)
    if actual != EXPECTED_FIELDS:
        raise ValidationError(
            f"{label}: fields differ; missing={sorted(EXPECTED_FIELDS-actual)}, "
            f"extra={sorted(actual-EXPECTED_FIELDS)}"
        )
    for field in BOUND_FIELDS:
        if row[field] != ticket[field]:
            raise ValidationError(f"{label}.{field}: source binding mismatch")
    for field, value in row.items():
        if isinstance(value, str) and NON_ASCII_DIGITS.search(value):
            raise ValidationError(f"{label}.{field}: contains non-ASCII numeral")
    if row["page_kind"] not in PAGE_KINDS:
        raise ValidationError(f"{label}.page_kind: invalid value")
    if row["page_kind"] not in {ticket["role"], "mixed", "blank"}:
        raise ValidationError(f"{label}.page_kind: conflicts with ticket role")
    printed = row["printed_page_label"]
    if printed is not None and (not isinstance(printed, str) or not printed.strip()):
        raise ValidationError(f"{label}.printed_page_label: invalid")
    values = row["numbered_items"]
    if not isinstance(values, list) or any(
        isinstance(value, bool) or not isinstance(value, int) for value in values
    ):
        raise ValidationError(f"{label}.numbered_items: expected integers")
    if values != sorted(set(values)):
        raise ValidationError(f"{label}.numbered_items: must be sorted and unique")
    maximum = EXPECTED_COUNTS[row["subject"]]
    if any(value < 1 or value > maximum for value in values):
        raise ValidationError(f"{label}.numbered_items: outside 1..{maximum}")
    if row["first_global_question"] != (values[0] if values else None):
        raise ValidationError(f"{label}.first_global_question: mismatch")
    if row["last_global_question"] != (values[-1] if values else None):
        raise ValidationError(f"{label}.last_global_question: mismatch")
    for field in ("continues_from_previous", "continues_to_next"):
        if not isinstance(row[field], bool):
            raise ValidationError(f"{label}.{field}: expected boolean")
    if ticket["role"] == "key" and (
        row["continues_from_previous"] or row["continues_to_next"]
    ):
        raise ValidationError(f"{label}: key pages cannot claim solution continuation")
    notes = row["notes"]
    if not isinstance(notes, list) or any(
        not isinstance(note, str) or not note.strip() for note in notes
    ):
        raise ValidationError(f"{label}.notes: expected string array")
    if len(notes) != len(set(notes)):
        raise ValidationError(f"{label}.notes: duplicate")
    if row["page_kind"] == "blank" and values:
        raise ValidationError(f"{label}: blank page cannot evidence items")
    if row["page_kind"] != "blank" and not values and not (
        row["continues_from_previous"] or row["continues_to_next"]
    ):
        raise ValidationError(f"{label}: evidence page has no numbered items")


def main() -> int:
    args = parse_args()
    batch = load_object(args.batch)
    if batch.get("prompt_contract") != "gauss-answer-inventory-v1":
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
        "numbered_items": sum(len(row["numbered_items"]) for row in rows),
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
