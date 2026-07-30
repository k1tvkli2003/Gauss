"""Extract the latest complete hash-bound JSONL reply from one Jules session.

Jules repair sessions sometimes put their answer in ``agentMessaged`` activity
text rather than a change-set artifact. This extractor preserves the raw
activity document elsewhere and promotes only the newest fenced JSONL block
whose rows exactly match the supplied repair-ticket input. The separate
``validate_jules_repair_harvest.py`` gate must still pass before review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable


JSONL_BLOCK = re.compile(r"```jsonl\s*(.*?)```", re.IGNORECASE | re.DOTALL)


def read_expected(path: Path) -> list[dict[str, Any]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, list) or any(not isinstance(row, dict) for row in value):
        raise ValueError("repair input must be a JSON array of ticket objects")
    return value


def activity_records(document: Any) -> Iterable[dict[str, Any]]:
    if isinstance(document, list):
        values = document
    elif isinstance(document, dict) and isinstance(document.get("activities"), list):
        values = document["activities"]
    else:
        values = [document]
    for value in values:
        if isinstance(value, dict):
            yield value


def parse_jsonl_block(raw: str) -> list[dict[str, Any]] | None:
    rows: list[dict[str, Any]] = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            return None
        if not isinstance(value, dict):
            return None
        rows.append(value)
    return rows or None


def matches_expected(rows: list[dict[str, Any]], expected: list[dict[str, Any]]) -> bool:
    if len(rows) != len(expected):
        return False
    for row, ticket in zip(rows, expected):
        if (
            row.get("ticket_id") != ticket.get("ticket_id")
            or row.get("question_id") != ticket.get("question_id")
            or row.get("source_sha256") != ticket.get("source_sha256")
        ):
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Repair input JSON")
    parser.add_argument(
        "--activities", required=True, type=Path, help="Saved Jules activity JSON"
    )
    parser.add_argument("--output", required=True, type=Path, help="Extracted JSONL")
    parser.add_argument("--report", type=Path, help="Optional extraction report")
    args = parser.parse_args()

    expected = read_expected(args.input)
    document = json.loads(args.activities.read_text(encoding="utf-8-sig"))
    candidates: list[tuple[int, str | None, list[dict[str, Any]]]] = []
    message_count = 0
    block_count = 0
    for activity_index, activity in enumerate(activity_records(document), 1):
        message = activity.get("agentMessaged", {}).get("agentMessage")
        if not isinstance(message, str):
            continue
        message_count += 1
        for block in JSONL_BLOCK.findall(message):
            block_count += 1
            rows = parse_jsonl_block(block)
            if rows is not None and matches_expected(rows, expected):
                candidates.append((activity_index, activity.get("createTime"), rows))

    if not candidates:
        report = {
            "valid": False,
            "reason": "no complete exact-order hash-bound JSONL block",
            "messages": message_count,
            "jsonl_blocks": block_count,
        }
        rendered = json.dumps(report, ensure_ascii=False, indent=2)
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(f"{rendered}\n", encoding="utf-8")
        print(rendered)
        return 1

    activity_index, create_time, rows = candidates[-1]
    serialized = "\n".join(
        json.dumps(row, ensure_ascii=False, separators=(",", ":")) for row in rows
    ) + "\n"
    # Hash the exact bytes that are persisted. Text-mode writes can translate
    # LF to CRLF on Windows, which would make the report attest a different
    # artifact than the one a later validator reads.
    output_bytes = serialized.encode("utf-8")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output_bytes)
    report = {
        "valid": True,
        "input_sha256": hashlib.sha256(args.input.read_bytes()).hexdigest(),
        "activities_sha256": hashlib.sha256(args.activities.read_bytes()).hexdigest(),
        "output_sha256": hashlib.sha256(output_bytes).hexdigest(),
        "rows": len(rows),
        "messages": message_count,
        "jsonl_blocks": block_count,
        "selected_activity_index": activity_index,
        "selected_create_time": create_time,
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(f"{rendered}\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"harvest error: {error}", file=sys.stderr)
        raise SystemExit(2)
