#!/usr/bin/env python3
"""Normalize only explicit empty-note serialization artifacts in Jules inventory JSONL.

The raw Jules artifact remains immutable evidence. This narrow transport pass may
convert `"notes":"[]"` or `"notes":["[]"]` to `"notes":[]`; it must not alter
any other field or interpret source-page content.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


class NormalizationError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    return parser.parse_args()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def load_rows(path: Path) -> tuple[bytes, list[dict[str, Any]]]:
    raw = path.read_bytes()
    text = raw.decode("utf-8")
    if text.startswith("\ufeff"):
        raise NormalizationError(f"{path}: UTF-8 BOM is forbidden")
    if "```" in text:
        raise NormalizationError(f"{path}: Markdown fences are forbidden")
    lines = text.splitlines()
    if not lines:
        raise NormalizationError(f"{path}: empty input")
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(lines, 1):
        if not line.strip():
            raise NormalizationError(f"{path}: blank line {line_number}")
        try:
            row = json.loads(line)
        except json.JSONDecodeError as error:
            raise NormalizationError(
                f"{path}: invalid JSON line {line_number}: {error}"
            ) from error
        if not isinstance(row, dict):
            raise NormalizationError(f"{path}: line {line_number} is not an object")
        rows.append(row)
    return raw, rows


def normalize_row(row: dict[str, Any], index: int) -> tuple[dict[str, Any], bool]:
    if "notes" not in row:
        raise NormalizationError(f"row[{index}]: missing notes")
    normalized = dict(row)
    notes = row["notes"]
    if notes == "[]" or notes == ["[]"]:
        normalized["notes"] = []
        return normalized, True
    if isinstance(notes, str):
        raise NormalizationError(
            f"row[{index}].notes: unsupported string; only exact '[]' is normalizable"
        )
    return normalized, False


def main() -> int:
    args = parse_args()
    raw, rows = load_rows(args.input)
    normalized_rows: list[dict[str, Any]] = []
    changed_tickets: list[str] = []
    for index, row in enumerate(rows, 1):
        normalized, changed = normalize_row(row, index)
        normalized_rows.append(normalized)
        if changed:
            ticket_id = normalized.get("ticket_id")
            if not isinstance(ticket_id, str) or not ticket_id:
                raise NormalizationError(f"row[{index}].ticket_id: expected non-empty string")
            changed_tickets.append(ticket_id)

    output_text = "".join(
        json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n"
        for row in normalized_rows
    )
    output_bytes = output_text.encode("utf-8")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output_bytes)
    report = {
        "schema_version": 1,
        "normalization_contract": "gauss-source-inventory-empty-notes-v1",
        "input_sha256": sha256_bytes(raw),
        "output_sha256": sha256_bytes(output_bytes),
        "row_count": len(normalized_rows),
        "changed_row_count": len(changed_tickets),
        "changed_ticket_ids": changed_tickets,
        "allowed_change": "notes exact empty-array sentinel to empty array only",
        "source_content_interpreted": False,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeError, KeyError, TypeError, ValueError, NormalizationError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
