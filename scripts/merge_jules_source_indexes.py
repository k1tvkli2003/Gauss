#!/usr/bin/env python3
"""Validate and merge every Jules source-inventory lane into a coverage receipt.

The command is intentionally fail-closed: every batch output must exist, pass
its lane validator, have no ambiguity notes, and cover every expected global
question number exactly once before an index receipt is written.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Callable

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import validate_jules_answer_inventory as answer_validator
import validate_jules_source_inventory as question_validator


EXPECTED_COUNTS = {"math": 2042, "physics": 1630}


class MergeError(RuntimeError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wave", type=Path, help="Path to wave.json")
    parser.add_argument("--output", type=Path, help="Merged JSONL path")
    parser.add_argument("--receipt", type=Path, help="Coverage receipt path")
    return parser.parse_args()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise MergeError(f"{path}: expected object")
    return value


def exact_coverage(values: list[int], subject: str, lane: str) -> None:
    counts = collections.Counter(values)
    duplicates = sorted(number for number, count in counts.items() if count > 1)
    expected = set(range(1, EXPECTED_COUNTS[subject] + 1))
    actual = set(counts)
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if duplicates or missing or extra:
        raise MergeError(
            f"{subject} {lane} coverage failed: duplicates={duplicates[:20]}, "
            f"missing={missing[:20]}, extra={extra[:20]}"
        )


def topic_ranges(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_topic: dict[tuple[str, str, str], list[int]] = {}
    for row in rows:
        for number in row["numbered_questions"]:
            by_topic.setdefault(
                (row["subject"], row["topic_key"], row["question_pdf"]), []
            ).append(number)
    result: list[dict[str, Any]] = []
    for (subject, topic_key, question_pdf), values in sorted(
        by_topic.items(), key=lambda item: (item[0][0], min(item[1]))
    ):
        ordered = sorted(values)
        if ordered != list(range(ordered[0], ordered[-1] + 1)):
            raise MergeError(
                f"non-contiguous topic range {subject}/{topic_key}: "
                f"{ordered[0]}..{ordered[-1]} ({len(ordered)} starts)"
            )
        result.append(
            {
                "subject": subject,
                "topic_key": topic_key,
                "question_pdf": question_pdf,
                "first_question": ordered[0],
                "last_question": ordered[-1],
                "question_count": len(ordered),
            }
        )
    return result


def validate_batches(
    wave_path: Path,
    wave: dict[str, Any],
    *,
    validator: Any,
    validate_row: Callable[[dict[str, Any], dict[str, Any], int], None],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    root = wave_path.parent
    all_rows: list[dict[str, Any]] = []
    outputs: list[dict[str, Any]] = []
    batches = wave.get("batches")
    if not isinstance(batches, list) or len(batches) != wave.get("lane_count"):
        raise MergeError("wave batches do not match lane_count")
    for batch in batches:
        batch_dir = root / "batches" / batch["batch_id"]
        batch_path = batch_dir / "batch.json"
        output_path = batch_dir / batch["expected_output"]
        if not output_path.is_file():
            raise MergeError(f"missing lane output {output_path}")
        disk_batch = load_object(batch_path)
        if disk_batch != batch:
            raise MergeError(f"{batch_path}: differs from wave-bound batch")
        rows = validator.load_jsonl(output_path)
        tickets = batch["tickets"]
        if len(rows) != len(tickets):
            raise MergeError(
                f"{batch['batch_id']}: row count {len(rows)} != {len(tickets)}"
            )
        for index, (row, ticket) in enumerate(zip(rows, tickets, strict=True), 1):
            validate_row(row, ticket, index)
            if row["notes"]:
                raise MergeError(
                    f"{batch['batch_id']} row {index}: unresolved notes {row['notes']}"
                )
        all_rows.extend(rows)
        outputs.append(
            {
                "batch_id": batch["batch_id"],
                "prompt_sha256": batch["prompt_sha256"],
                "output_file": str(output_path.relative_to(root)).replace("\\", "/"),
                "output_sha256": sha256_file(output_path),
                "row_count": len(rows),
            }
        )
    return all_rows, outputs


def main() -> int:
    args = parse_args()
    wave_path = args.wave.resolve()
    wave = load_object(wave_path)
    contract = wave.get("prompt_contract")
    if contract == "gauss-source-inventory-v1":
        validator = question_validator
        validate_row = question_validator.validate_row
        kind = "question"
        default_name = "source-question-page-index.jsonl"
    elif contract == "gauss-answer-inventory-v1":
        validator = answer_validator
        validate_row = answer_validator.validate_row
        kind = "answer"
        default_name = "source-answer-page-index.jsonl"
    else:
        raise MergeError(f"unsupported wave contract {contract!r}")

    rows, outputs = validate_batches(
        wave_path, wave, validator=validator, validate_row=validate_row
    )
    if len(rows) != wave.get("source_page_count"):
        raise MergeError(f"merged row count {len(rows)} != source_page_count")
    ticket_ids = [row["ticket_id"] for row in rows]
    if len(ticket_ids) != len(set(ticket_ids)):
        raise MergeError("duplicate page ticket across lanes")

    coverage: dict[str, Any] = {}
    if kind == "question":
        for subject in EXPECTED_COUNTS:
            values = [
                number
                for row in rows
                if row["subject"] == subject
                for number in row["numbered_questions"]
            ]
            exact_coverage(values, subject, "question")
            coverage[subject] = {"question_count": len(values)}
        ranges = topic_ranges(rows)
    else:
        ranges = []
        for subject in EXPECTED_COUNTS:
            coverage[subject] = {}
            for role in ("solution", "key"):
                values = [
                    number
                    for row in rows
                    if row["subject"] == subject and row["role"] == role
                    for number in row["numbered_items"]
                ]
                exact_coverage(values, subject, role)
                coverage[subject][f"{role}_count"] = len(values)

    output_path = args.output or wave_path.parent / default_name
    receipt_path = args.receipt or output_path.with_suffix(".receipt.json")
    rendered_index = (
        "\n".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) for row in rows)
        + "\n"
    ).encode("utf-8")
    receipt = {
        "schema_version": 1,
        "index_kind": kind,
        "prompt_contract": contract,
        "wave_file": wave_path.name,
        "wave_sha256": sha256_file(wave_path),
        "index_file": output_path.name,
        "index_sha256": sha256_bytes(rendered_index),
        "page_count": len(rows),
        "lane_count": len(outputs),
        "coverage": coverage,
        "topic_ranges": ranges,
        "lane_outputs": outputs,
        "unresolved_notes": 0,
        "exact_global_coverage": True,
        "immutable_sources_edited": False,
        "runtime_usable": False,
    }
    write_atomic(output_path, rendered_index)
    write_atomic(
        receipt_path,
        (json.dumps(receipt, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )
    print(json.dumps(receipt, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, KeyError, TypeError, ValueError, MergeError) as error:
        print(f"source index merge error: {error}")
        raise SystemExit(1)
