"""Fail-closed structural validator for blind Jules repair-lane JSONL.

The repair lane may propose source-preserving overlays, but it is not allowed to
silently certify an answer, mutate an immutable source record, or promote a
free-form agent response. This tool validates only machine-checkable transport
and overlay-shape constraints; independent mathematical review remains a
separate gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any


REQUIRED_TOP_LEVEL_FIELDS = {
    "ticket_id",
    "question_id",
    "source_sha256",
    "status",
    "patch",
    "evidence",
    "effective_option",
    "blockers",
}
REQUIRED_EVIDENCE_FIELDS = {
    "independent_solve",
    "solution_review",
    "adversarial_review",
}
REQUIRED_PATCH_FIELDS = {
    "target",
    "kind",
    "solution_addendum",
    "preserve_source",
}


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            raise ValueError(f"line {line_number} is blank")
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError(f"line {line_number} is not a JSON object")
        rows.append(value)
    return rows


def issue(errors: list[str], row_number: int, message: str) -> None:
    errors.append(f"row {row_number}: {message}")


def nonempty_string(value: Any, *, minimum: int = 1) -> bool:
    return isinstance(value, str) and len(value.strip()) >= minimum


def validate_rows(
    expected: list[dict[str, Any]], rows: list[dict[str, Any]]
) -> list[str]:
    errors: list[str] = []
    if len(rows) != len(expected):
        errors.append(f"row count {len(rows)} does not match expected {len(expected)}")

    seen_ids: set[str] = set()
    for row_number, row in enumerate(rows, 1):
        expected_row = expected[row_number - 1] if row_number <= len(expected) else None
        fields = set(row)
        if fields != REQUIRED_TOP_LEVEL_FIELDS:
            missing = sorted(REQUIRED_TOP_LEVEL_FIELDS - fields)
            unexpected = sorted(fields - REQUIRED_TOP_LEVEL_FIELDS)
            if missing:
                issue(errors, row_number, f"missing top-level fields {missing}")
            if unexpected:
                issue(errors, row_number, f"unexpected top-level fields {unexpected}")

        question_id = row.get("question_id")
        if not isinstance(question_id, str) or not question_id:
            issue(errors, row_number, "question_id is invalid")
        elif question_id in seen_ids:
            issue(errors, row_number, "duplicate question_id")
        else:
            seen_ids.add(question_id)

        if expected_row is not None:
            for key in ("ticket_id", "question_id", "source_sha256"):
                if row.get(key) != expected_row.get(key):
                    issue(errors, row_number, f"{key} does not match input order")
        if not isinstance(row.get("source_sha256"), str) or not all(
            character in "0123456789abcdef" for character in row.get("source_sha256", "")
        ) or len(row.get("source_sha256", "")) != 64:
            issue(errors, row_number, "source_sha256 is invalid")

        status = row.get("status")
        if status not in {"draft", "under_review"}:
            issue(errors, row_number, "status must be draft or under_review")

        evidence = row.get("evidence")
        if not isinstance(evidence, dict) or set(evidence) != REQUIRED_EVIDENCE_FIELDS:
            issue(errors, row_number, "evidence fields are incomplete or unexpected")
        elif any(not nonempty_string(evidence[key], minimum=8) for key in REQUIRED_EVIDENCE_FIELDS):
            issue(errors, row_number, "evidence values must be non-empty review summaries")

        option = row.get("effective_option")
        if option is not None and (not isinstance(option, int) or not 1 <= option <= 4):
            issue(errors, row_number, "effective_option must be null or a 1-based option")

        blockers = row.get("blockers")
        if not isinstance(blockers, list) or any(
            not nonempty_string(blocker) for blocker in blockers
        ) or len(set(blockers)) != len(blockers):
            issue(errors, row_number, "blockers must be a unique non-empty string array")

        patch = row.get("patch")
        if status == "draft":
            if not isinstance(patch, dict) or set(patch) != REQUIRED_PATCH_FIELDS:
                issue(errors, row_number, "draft patch fields are incomplete or unexpected")
            else:
                if patch.get("target") != "solution":
                    issue(errors, row_number, "draft patch target must be solution")
                if patch.get("kind") != "addendum":
                    issue(errors, row_number, "draft patch kind must be addendum")
                if not nonempty_string(patch.get("solution_addendum"), minimum=8):
                    issue(errors, row_number, "draft addendum is empty or too short")
                if patch.get("preserve_source") is not True:
                    issue(errors, row_number, "draft patch must preserve source")
            if blockers != []:
                issue(errors, row_number, "draft patch cannot retain blockers")
        elif status == "under_review":
            if patch != {}:
                issue(errors, row_number, "under_review patch must be empty")
            if not blockers:
                issue(errors, row_number, "under_review requires a concrete blocker")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Original repair input JSON")
    parser.add_argument("--output", required=True, type=Path, help="Jules JSONL response")
    parser.add_argument("--report", type=Path, help="Optional JSON validation report")
    args = parser.parse_args()

    expected = read_json(args.input)
    if not isinstance(expected, list) or any(not isinstance(row, dict) for row in expected):
        raise SystemExit("input must be a JSON array of repair ticket objects")
    rows = read_jsonl(args.output)
    errors = validate_rows(expected, rows)
    report = {
        "input": str(args.input),
        "output": str(args.output),
        "input_sha256": hashlib.sha256(args.input.read_bytes()).hexdigest(),
        "output_sha256": hashlib.sha256(args.output.read_bytes()).hexdigest(),
        "expected_rows": len(expected),
        "actual_rows": len(rows),
        "status_counts": dict(Counter(row.get("status") for row in rows)),
        "valid": not errors,
        "errors": errors,
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(f"{rendered}\n", encoding="utf-8")
    print(rendered)
    return 0 if not errors else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"validation error: {error}", file=sys.stderr)
        raise SystemExit(2)
