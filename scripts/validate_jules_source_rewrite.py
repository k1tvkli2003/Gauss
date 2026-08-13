#!/usr/bin/env python3
"""Fail-closed validator for source-first Jules recovery/rewrite drafts.

This validator proves transport, schema, hash binding, order, evidence naming,
ASCII-digit compliance, media-coordinate safety, and basic rewrite invariants.
It deliberately does not certify source fidelity or scientific correctness;
those require independent visual/scientific receipts before promotion.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable


EXPECTED_FIELDS = {
    "ticket_id",
    "question_id",
    "source_sha256",
    "status",
    "recovered",
    "friendly",
    "answer",
    "media",
    "corrections",
    "evidence",
    "blockers",
}
CONTENT_FIELDS = {"stem", "options", "solution"}
ANSWER_FIELDS = {
    "printed_key_option",
    "independent_option",
    "final_option",
    "agreement",
}
MEDIA_FIELDS = {"source", "page_file", "placement", "crop_box", "alt_fa"}
CORRECTION_FIELDS = {"field", "printed", "corrected", "reason"}
EVIDENCE_FIELDS = {
    "question_pages",
    "solution_pages",
    "key_page",
    "source_recovery",
    "independent_derivation",
    "scientific_review",
    "rewrite_fidelity_review",
}
SOURCE_FILES_FIELDS = {"question_pages", "solution_pages", "key_page"}
STATUS_VALUES = {"draft", "needs_source_followup"}
CORRECTION_FIELD_VALUES = {
    "stem",
    "option_1",
    "option_2",
    "option_3",
    "option_4",
    "solution",
    "answer",
}
PLACEMENT_VALUES = {
    "stem",
    "option_1",
    "option_2",
    "option_3",
    "option_4",
    "solution",
}
NON_ASCII_DIGITS = re.compile(r"[\u0660-\u0669\u06f0-\u06f9]")
PERSIAN = re.compile(r"[\u0600-\u06ff]")
LATEX_COMMAND = re.compile(r"\\[A-Za-z]+")
NUMBER = re.compile(r"(?<![A-Za-z])[-+]?\d+(?:[.,]\d+)?(?:[eE][-+]?\d+)?")
IDENTIFIER = re.compile(r"(?<![A-Za-z])[A-Za-z](?:_[A-Za-z0-9{}]+)?")
OPERATOR = re.compile(r"(?:<=|>=|!=|==|->|=>|[=<>+\-*/^%|])")
EMOJI = re.compile(
    "[\U0001F1E6-\U0001F1FF\U0001F300-\U0001FAFF\u2600-\u27BF]"
)


class ValidationError(RuntimeError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch", type=Path, help="Path to batch.json")
    parser.add_argument("output", type=Path, help="Path to exact JSONL output")
    parser.add_argument("--report", type=Path, help="Optional JSON report path")
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
        raise ValidationError(f"{path}: Markdown fences are forbidden in JSONL")
    lines = raw.splitlines()
    if not lines:
        raise ValidationError(f"{path}: empty output")
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(lines, 1):
        if not line.strip():
            raise ValidationError(f"{path}: blank line {line_number}")
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValidationError(
                f"{path}: line {line_number} is not JSON: {error}"
            ) from error
        if not isinstance(value, dict):
            raise ValidationError(f"{path}: line {line_number} is not an object")
        rows.append(value)
    return rows


def walk_strings(value: Any, path: str = "$") -> Iterable[tuple[str, str]]:
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from walk_strings(item, f"{path}[{index}]")
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from walk_strings(item, f"{path}.{key}")


def require_exact_fields(value: Any, expected: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValidationError(f"{label}: expected object")
    actual = set(value)
    if actual != expected:
        raise ValidationError(
            f"{label}: fields differ; missing={sorted(expected - actual)}, "
            f"extra={sorted(actual - expected)}"
        )
    return value


def require_nonempty_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"{label}: expected non-empty string")
    return value


def technical_atoms(value: str) -> collections.Counter[str]:
    atoms: list[str] = []
    atoms.extend(command.lower() for command in LATEX_COMMAND.findall(value))
    atoms.extend(number.replace(",", ".") for number in NUMBER.findall(value))
    atoms.extend(identifier.lower() for identifier in IDENTIFIER.findall(value))
    atoms.extend(OPERATOR.findall(value))
    return collections.Counter(atoms)


def validate_content(value: Any, label: str) -> dict[str, Any]:
    content = require_exact_fields(value, CONTENT_FIELDS, label)
    require_nonempty_string(content["stem"], f"{label}.stem")
    require_nonempty_string(content["solution"], f"{label}.solution")
    options = content["options"]
    if not isinstance(options, list) or len(options) != 4:
        raise ValidationError(f"{label}.options: expected exactly four options")
    for index, option in enumerate(options, 1):
        require_nonempty_string(option, f"{label}.options[{index}]")
    return content


def correction_replacements(corrections: list[dict[str, Any]], field: str) -> list[str]:
    names = {field}
    if field.startswith("options["):
        names = {f"option_{int(field[8:-1]) + 1}"}
    return [item["corrected"] for item in corrections if item["field"] in names]


def validate_rewrite_invariants(
    recovered: dict[str, Any],
    friendly: dict[str, Any],
    corrections: list[dict[str, Any]],
    label: str,
) -> None:
    pairs = [("stem", recovered["stem"], friendly["stem"])]
    pairs.extend(
        (f"options[{index}]", recovered["options"][index], friendly["options"][index])
        for index in range(4)
    )
    pairs.append(("solution", recovered["solution"], friendly["solution"]))
    for field, source, rewritten in pairs:
        source_atoms = technical_atoms(source)
        rewritten_atoms = technical_atoms(rewritten)
        for replacement in correction_replacements(corrections, field):
            rewritten_atoms.update(technical_atoms(replacement))
        missing = source_atoms - rewritten_atoms
        if missing:
            raise ValidationError(
                f"{label}.{field}: friendly rewrite lost technical atoms {dict(missing)}"
            )
        if PERSIAN.search(source) and not PERSIAN.search(rewritten):
            raise ValidationError(f"{label}.{field}: Persian prose disappeared")
        for paragraph_index, paragraph in enumerate(re.split(r"\n\s*\n", rewritten), 1):
            if len(EMOJI.findall(paragraph)) > 1:
                raise ValidationError(
                    f"{label}.{field}: paragraph {paragraph_index} has more than one emoji"
                )


def validate_answer(value: Any, status: str, label: str) -> dict[str, Any]:
    answer = require_exact_fields(value, ANSWER_FIELDS, label)
    for field in ("printed_key_option", "independent_option", "final_option"):
        option = answer[field]
        if option is not None and (isinstance(option, bool) or not isinstance(option, int) or option not in range(1, 5)):
            raise ValidationError(f"{label}.{field}: expected 1..4 or null")
    agreement = answer["agreement"]
    if agreement is not None and not isinstance(agreement, bool):
        raise ValidationError(f"{label}.agreement: expected boolean or null")
    if status == "draft":
        if any(answer[field] is None for field in ("printed_key_option", "independent_option", "final_option")):
            raise ValidationError(f"{label}: draft requires three resolved answer options")
        if agreement is not True:
            raise ValidationError(f"{label}: draft requires full answer agreement")
    return answer


def validate_corrections(value: Any, label: str) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        raise ValidationError(f"{label}: expected array")
    result: list[dict[str, Any]] = []
    for index, item in enumerate(value):
        correction = require_exact_fields(item, CORRECTION_FIELDS, f"{label}[{index}]")
        if correction["field"] not in CORRECTION_FIELD_VALUES:
            raise ValidationError(f"{label}[{index}].field: invalid value")
        for field in ("printed", "corrected", "reason"):
            require_nonempty_string(correction[field], f"{label}[{index}].{field}")
        if correction["printed"].strip() == correction["corrected"].strip():
            raise ValidationError(f"{label}[{index}]: correction makes no change")
        result.append(correction)
    return result


def validate_media(
    value: Any,
    attachments: dict[str, dict[str, Any]],
    label: str,
) -> None:
    if not isinstance(value, list):
        raise ValidationError(f"{label}: expected array")
    seen: set[tuple[str, str, str, tuple[int, ...] | None]] = set()
    for index, item in enumerate(value):
        media = require_exact_fields(item, MEDIA_FIELDS, f"{label}[{index}]")
        if media["source"] not in {"question", "solution"}:
            raise ValidationError(f"{label}[{index}].source: invalid value")
        if media["placement"] not in PLACEMENT_VALUES:
            raise ValidationError(f"{label}[{index}].placement: invalid value")
        page_file = require_nonempty_string(media["page_file"], f"{label}[{index}].page_file")
        attachment = attachments.get(page_file)
        if attachment is None or attachment["role"] != media["source"]:
            raise ValidationError(f"{label}[{index}]: page_file is not matching source evidence")
        require_nonempty_string(media["alt_fa"], f"{label}[{index}].alt_fa")
        crop = media["crop_box"]
        if (
            not isinstance(crop, list)
            or len(crop) != 4
            or any(isinstance(number, bool) or not isinstance(number, int) for number in crop)
        ):
            raise ValidationError(f"{label}[{index}].crop_box: expected four integers")
        left, top, right, bottom = crop
        width, height = attachment["rendered_size"]
        if not (0 <= left < right <= width and 0 <= top < bottom <= height):
            raise ValidationError(f"{label}[{index}].crop_box: outside rendered page")
        if left == 0 and top == 0 and right == width and bottom == height:
            raise ValidationError(f"{label}[{index}].crop_box: whole-page crops are forbidden")
        crop_key = tuple(crop)
        unique = (media["source"], page_file, media["placement"], crop_key)
        if unique in seen:
            raise ValidationError(f"{label}[{index}]: duplicate media request")
        seen.add(unique)


def validate_row(
    row: dict[str, Any],
    ticket: dict[str, Any],
    attachments: dict[str, dict[str, Any]],
    index: int,
) -> str:
    label = f"row[{index}]"
    require_exact_fields(row, EXPECTED_FIELDS, label)
    for path, value in walk_strings(row, label):
        if NON_ASCII_DIGITS.search(value):
            raise ValidationError(f"{path}: contains Persian/Arabic numeral")
        if "```" in value:
            raise ValidationError(f"{path}: contains Markdown fence")
    for field in ("ticket_id", "question_id", "source_sha256"):
        if row[field] != ticket[field]:
            raise ValidationError(f"{label}.{field}: source binding mismatch")
    status = row["status"]
    if status not in STATUS_VALUES:
        raise ValidationError(f"{label}.status: invalid value")
    corrections = validate_corrections(row["corrections"], f"{label}.corrections")
    recovered = validate_content(row["recovered"], f"{label}.recovered")
    friendly = validate_content(row["friendly"], f"{label}.friendly")
    validate_rewrite_invariants(recovered, friendly, corrections, f"{label}.friendly")
    validate_answer(row["answer"], status, f"{label}.answer")
    validate_media(row["media"], attachments, f"{label}.media")
    evidence = require_exact_fields(row["evidence"], EVIDENCE_FIELDS, f"{label}.evidence")
    source_files = require_exact_fields(
        ticket["source_files"], SOURCE_FILES_FIELDS, f"{label}.ticket.source_files"
    )
    for field, role in (("question_pages", "question"), ("solution_pages", "solution")):
        expected_pages = source_files[field]
        if (
            not isinstance(expected_pages, list)
            or not expected_pages
            or any(not isinstance(page, str) or not page for page in expected_pages)
            or len(expected_pages) != len(set(expected_pages))
        ):
            raise ValidationError(f"{label}.ticket.source_files.{field}: invalid page list")
        if evidence[field] != expected_pages:
            raise ValidationError(f"{label}.evidence.{field}: wrong ordered page list")
        for page in expected_pages:
            attachment = attachments.get(page)
            if attachment is None or attachment.get("role") != role:
                raise ValidationError(
                    f"{label}.ticket.source_files.{field}: missing {role} attachment {page}"
                )
    key_page = source_files["key_page"]
    key_attachment = attachments.get(key_page)
    if not isinstance(key_page, str) or key_attachment is None or key_attachment.get("role") != "key":
        raise ValidationError(f"{label}.ticket.source_files.key_page: invalid key attachment")
    if evidence["key_page"] != key_page:
        raise ValidationError(f"{label}.evidence.key_page: wrong file")
    for field in EVIDENCE_FIELDS - {"question_pages", "solution_pages", "key_page"}:
        require_nonempty_string(evidence[field], f"{label}.evidence.{field}")
    blockers = row["blockers"]
    if not isinstance(blockers, list) or any(not isinstance(value, str) or not value.strip() for value in blockers):
        raise ValidationError(f"{label}.blockers: expected non-empty-string array")
    if len(blockers) != len(set(blockers)):
        raise ValidationError(f"{label}.blockers: duplicate value")
    if status == "draft" and blockers:
        raise ValidationError(f"{label}.blockers: draft must have no blockers")
    if status == "needs_source_followup" and not blockers:
        raise ValidationError(f"{label}.blockers: follow-up status requires blockers")
    return status


def main() -> int:
    args = parse_args()
    batch = load_object(args.batch)
    if batch.get("schema_version") != 2 or batch.get("prompt_contract") != "gauss-source-rewrite-v2":
        raise ValidationError("batch prompt contract is missing or unsupported")
    prompt_path = args.batch.parent / "prompt.md"
    if not prompt_path.is_file() or sha256_file(prompt_path) != batch.get("prompt_sha256"):
        raise ValidationError("batch prompt is missing or hash-mismatched")
    index_binding = batch.get("source_index_binding")
    required_index_fields = {
        "question_index_file",
        "question_index_sha256",
        "question_index_receipt_file",
        "question_index_receipt_sha256",
        "answer_index_file",
        "answer_index_sha256",
        "answer_index_receipt_file",
        "answer_index_receipt_sha256",
        "exact_question_coverage",
        "exact_answer_coverage",
    }
    require_exact_fields(index_binding, required_index_fields, "batch.source_index_binding")
    if (
        index_binding["exact_question_coverage"] is not True
        or index_binding["exact_answer_coverage"] is not True
    ):
        raise ValidationError("batch source indexes do not prove exact coverage")
    tickets = batch.get("tickets")
    if not isinstance(tickets, list) or len(tickets) != batch.get("item_count"):
        raise ValidationError("batch tickets do not match item_count")
    rows = load_jsonl(args.output)
    if len(rows) != len(tickets):
        raise ValidationError(f"row count {len(rows)} != ticket count {len(tickets)}")
    attachment_rows = batch.get("attachments", [])
    if not isinstance(attachment_rows, list):
        raise ValidationError("batch attachments must be an array")
    attachments = {item["file"]: item for item in attachment_rows}
    if len(attachments) != len(attachment_rows):
        raise ValidationError("batch attachments contain duplicate filenames")
    actual_attachment_bytes = 0
    for filename, attachment in attachments.items():
        image_path = args.batch.parent / "images" / filename
        if not image_path.is_file():
            raise ValidationError(f"missing batch attachment {filename}")
        if image_path.stat().st_size != attachment.get("bytes"):
            raise ValidationError(f"attachment byte mismatch {filename}")
        if sha256_file(image_path) != attachment.get("sha256"):
            raise ValidationError(f"attachment hash mismatch {filename}")
        actual_attachment_bytes += image_path.stat().st_size
    if actual_attachment_bytes != batch.get("attachment_bytes"):
        raise ValidationError("batch attachment byte total mismatch")
    statuses = collections.Counter(
        validate_row(row, ticket, attachments, index)
        for index, (row, ticket) in enumerate(zip(rows, tickets, strict=True), 1)
    )
    report = {
        "schema_version": 2,
        "batch_id": batch["batch_id"],
        "prompt_sha256": batch["prompt_sha256"],
        "row_count": len(rows),
        "status_counts": dict(sorted(statuses.items())),
        "transport_schema_hash_order_ascii_media_gates": "passed",
        "source_fidelity_certified": False,
        "scientific_correctness_certified": False,
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
