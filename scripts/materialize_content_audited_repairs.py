"""Materialize only independently content-audited Jules repair drafts.

The source corpus and media are immutable. This tool cross-checks each audit
row against the harvested transport row by order, question ID, and source hash,
then appends only accepted or explicitly corrected solution addenda to the
derived repair overlay. Rows kept under review remain quarantined.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any


AUDIT_TOP_FIELDS = {
    "schemaVersion",
    "group",
    "sourceKeyHidden",
    "auditedRows",
    "items",
}
AUDIT_ITEM_FIELDS = {
    "question_id",
    "source_sha256",
    "transport_status",
    "verdict",
    "independently_derived_option",
    "mathematical_assessment",
    "issues",
    "corrected_addendum",
}
BLIND_INPUT_FIELDS = {
    "ticket_id",
    "question_id",
    "source_sha256",
    "blocking_issues",
    "stem",
    "options",
    "solution",
}
TEXT_BLOCK_FIELDS = {"type", "text"}
TRANSPORT_FIELDS = {
    "ticket_id",
    "question_id",
    "source_sha256",
    "status",
    "patch",
    "evidence",
    "effective_option",
    "blockers",
}
PATCH_FIELDS = {"target", "kind", "solution_addendum", "preserve_source"}
EVIDENCE_FIELDS = {
    "independent_solve",
    "solution_review",
    "adversarial_review",
}
OVERLAY_FIELDS = {
    "schema_version",
    "question_id",
    "source_sha256",
    "status",
    "patch",
    "evidence",
}
VERDICTS = {"accept_draft", "keep_under_review", "reject_draft"}
QUESTION_ID = re.compile(r"^[a-z0-9_-]+$")
SHA256 = re.compile(r"^[a-f0-9]{64}$")
GROUP = re.compile(r"^repair-(\d{3}(?:-\d{3})+)$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"{path}: expected a JSON object")
    return value


def read_json_array(path: Path) -> list[dict[str, Any]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, list), f"{path}: expected a JSON array")
    require(all(isinstance(row, dict) for row in value), f"{path}: array contains a non-object")
    return value


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        require(bool(raw.strip()), f"{path}: line {line_number} is blank")
        value = json.loads(raw)
        require(isinstance(value, dict), f"{path}: line {line_number} is not an object")
        rows.append(value)
    return rows


def validate_text(value: Any, *, minimum: int, label: str) -> str:
    require(isinstance(value, str), f"{label}: expected text")
    require(len(value.strip()) >= minimum, f"{label}: text is too short")
    return value


def validate_transport(row: dict[str, Any], *, source: Path, index: int) -> None:
    label = f"{source}: row {index}"
    require(set(row) == TRANSPORT_FIELDS, f"{label}: unexpected transport fields")
    require(
        isinstance(row["question_id"], str) and QUESTION_ID.fullmatch(row["question_id"]),
        f"{label}: invalid question ID",
    )
    require(
        isinstance(row["source_sha256"], str) and SHA256.fullmatch(row["source_sha256"]),
        f"{label}: invalid source hash",
    )
    require(row["status"] in {"draft", "under_review"}, f"{label}: invalid status")
    require(isinstance(row["blockers"], list), f"{label}: blockers must be an array")
    if row["status"] == "under_review":
        require(row["patch"] == {}, f"{label}: under-review row carries a patch")
        require(bool(row["blockers"]), f"{label}: under-review row has no blocker")
        return
    require(row["blockers"] == [], f"{label}: draft retains blockers")
    require(isinstance(row["patch"], dict), f"{label}: patch is not an object")
    require(set(row["patch"]) == PATCH_FIELDS, f"{label}: unexpected patch fields")
    require(row["patch"]["target"] == "solution", f"{label}: target is not solution")
    require(row["patch"]["kind"] == "addendum", f"{label}: patch is not an addendum")
    require(row["patch"]["preserve_source"] is True, f"{label}: source is not preserved")
    validate_text(
        row["patch"]["solution_addendum"], minimum=8, label=f"{label}: solution addendum"
    )
    require(isinstance(row["evidence"], dict), f"{label}: evidence is not an object")
    require(set(row["evidence"]) == EVIDENCE_FIELDS, f"{label}: incomplete evidence")
    for key in EVIDENCE_FIELDS:
        validate_text(row["evidence"][key], minimum=8, label=f"{label}: evidence.{key}")


def validate_text_blocks(value: Any, *, label: str) -> None:
    require(isinstance(value, list), f"{label}: expected a text-block array")
    for index, block in enumerate(value, 1):
        block_label = f"{label}: block {index}"
        require(isinstance(block, dict), f"{block_label}: expected an object")
        require(set(block) == TEXT_BLOCK_FIELDS, f"{block_label}: unexpected fields")
        require(block["type"] == "text", f"{block_label}: non-text content is not blind-safe")
        validate_text(block["text"], minimum=1, label=f"{block_label}.text")


def validate_blind_remote_input(
    artifact_root: Path,
    batch: str,
    transports: list[dict[str, Any]],
) -> None:
    """Prove the harvested session received only the allowed key-blind ticket view."""

    workspace = artifact_root.parent
    input_path = workspace / f"repair-{batch}.input.json"
    prompt_path = workspace / f"repair-{batch}.prompt.md"
    session_path = artifact_root / f"repair-{batch}" / "session.json"
    inputs = read_json_array(input_path)
    require(len(inputs) == len(transports), f"{input_path}: transport row count mismatch")
    for index, (item, transport) in enumerate(zip(inputs, transports, strict=True), 1):
        label = f"{input_path}: row {index}"
        require(set(item) == BLIND_INPUT_FIELDS, f"{label}: source-key-blind fields mismatch")
        require(item["ticket_id"] == transport["ticket_id"], f"{label}: ticket order mismatch")
        require(item["question_id"] == transport["question_id"], f"{label}: question order mismatch")
        require(item["source_sha256"] == transport["source_sha256"], f"{label}: source hash mismatch")
        require(isinstance(item["blocking_issues"], list), f"{label}: blocking issues are invalid")
        require(
            all(isinstance(issue, str) and issue.strip() for issue in item["blocking_issues"]),
            f"{label}: blocking issue is invalid",
        )
        validate_text_blocks(item["stem"], label=f"{label}.stem")
        require(isinstance(item["options"], list), f"{label}.options: expected an array")
        for option_index, option in enumerate(item["options"], 1):
            validate_text_blocks(option, label=f"{label}.options[{option_index}]")
        validate_text_blocks(item["solution"], label=f"{label}.solution")

    prompt = prompt_path.read_text(encoding="utf-8")
    serialized_input = json.dumps(inputs, ensure_ascii=False, separators=(",", ":")) + "\n"
    require(prompt.endswith(serialized_input), f"{prompt_path}: prompt payload differs from blind input")
    session = read_json(session_path)
    require(session.get("prompt") == prompt, f"{session_path}: remote prompt differs from blind prompt")


def validate_overlay(row: dict[str, Any], *, source: Path, index: int) -> None:
    label = f"{source}: row {index}"
    require(set(row) == OVERLAY_FIELDS, f"{label}: unexpected overlay fields")
    require(row["schema_version"] == 1, f"{label}: unsupported schema version")
    require(row["status"] == "draft", f"{label}: overlay is not a draft")
    require(
        isinstance(row["question_id"], str) and QUESTION_ID.fullmatch(row["question_id"]),
        f"{label}: invalid question ID",
    )
    require(
        isinstance(row["source_sha256"], str) and SHA256.fullmatch(row["source_sha256"]),
        f"{label}: invalid source hash",
    )
    # The ledger contains older, already corpus-validated repair kinds and
    # evidence shapes. Preserve them byte-for-byte; enforce the stricter
    # source-preserving addendum contract only for newly audited candidates.
    require(isinstance(row["patch"], dict), f"{label}: patch is not an object")
    require(isinstance(row["evidence"], dict), f"{label}: evidence is not an object")


def corrected_evidence(item: dict[str, Any]) -> dict[str, str]:
    issues = "; ".join(validate_text(issue, minimum=8, label="audit issue") for issue in item["issues"])
    option = item["independently_derived_option"]
    return {
        "independent_solve": validate_text(
            item["mathematical_assessment"], minimum=20, label="mathematical assessment"
        ),
        "solution_review": f"The independent content audit rejected the transported addendum: {issues}",
        "adversarial_review": (
            "The source-preserving corrected addendum resolves the audited defect and "
            f"selects option {option}; the source question and media remain unchanged."
        ),
    }


def canonical_candidate(
    transport: dict[str, Any], item: dict[str, Any], *, audit_path: Path, index: int
) -> dict[str, Any] | None:
    label = f"{audit_path}: row {index}"
    verdict = item["verdict"]
    require(verdict in VERDICTS, f"{label}: invalid verdict {verdict!r}")
    require(isinstance(item["issues"], list), f"{label}: issues must be an array")
    for issue in item["issues"]:
        validate_text(issue, minimum=8, label=f"{label}: issue")
    assessment = validate_text(
        item["mathematical_assessment"], minimum=20, label=f"{label}: assessment"
    )
    del assessment
    option = item["independently_derived_option"]
    require(
        option is None or type(option) is int and 1 <= option <= 4,
        f"{label}: invalid independently derived option",
    )
    # Some early audit artifacts used "valid" as a review-state label. The
    # harvested transport remains authoritative for draft/under_review status.
    require(
        item["transport_status"] in {transport["status"], "valid"},
        f"{label}: transport status mismatch",
    )
    if verdict == "keep_under_review":
        require(item["corrected_addendum"] is None, f"{label}: quarantined row has a patch")
        return None
    if verdict == "accept_draft":
        require(transport["status"] == "draft", f"{label}: non-draft transport was accepted")
        require(item["corrected_addendum"] is None, f"{label}: accepted row has correction")
        patch = transport["patch"]
        evidence = transport["evidence"]
    else:
        # A content audit may resolve an under-review transport blocker by
        # supplying a newly derived, source-preserving correction. It never
        # reuses the absent/unsafe transport patch in that case.
        require(option is not None, f"{label}: corrected row has no derived option")
        addendum = validate_text(
            item["corrected_addendum"], minimum=20, label=f"{label}: corrected addendum"
        )
        patch = {
            "target": "solution",
            "kind": "addendum",
            "solution_addendum": addendum,
            "preserve_source": True,
        }
        evidence = corrected_evidence(item)
    return {
        "schema_version": 1,
        "question_id": transport["question_id"],
        "source_sha256": transport["source_sha256"],
        "status": "draft",
        "patch": patch,
        "evidence": evidence,
    }


def audit_candidates(artifact_root: Path, audit_path: Path) -> tuple[list[dict[str, Any]], int]:
    audit = read_json(audit_path)
    require(set(audit) == AUDIT_TOP_FIELDS, f"{audit_path}: unexpected top-level fields")
    require(audit["schemaVersion"] == 1, f"{audit_path}: unsupported schema version")
    require(audit["sourceKeyHidden"] is True, f"{audit_path}: source key was not hidden")
    group = audit["group"]
    require(isinstance(group, str), f"{audit_path}: invalid group")
    match = GROUP.fullmatch(group)
    require(match is not None, f"{audit_path}: invalid group name {group!r}")
    expected: list[dict[str, Any]] = []
    for batch in match.group(1).split("-"):
        source = artifact_root / f"repair-{batch}" / "extracted.jsonl"
        rows = read_jsonl(source)
        for index, row in enumerate(rows, 1):
            validate_transport(row, source=source, index=index)
        validate_blind_remote_input(artifact_root, batch, rows)
        expected.extend(rows)
    items = audit["items"]
    require(isinstance(items, list), f"{audit_path}: items must be an array")
    require(audit["auditedRows"] == len(expected), f"{audit_path}: auditedRows mismatch")
    require(len(items) == len(expected), f"{audit_path}: item count mismatch")
    candidates: list[dict[str, Any]] = []
    quarantined = 0
    for index, (transport, item) in enumerate(zip(expected, items, strict=True), 1):
        require(isinstance(item, dict), f"{audit_path}: row {index} is not an object")
        require(set(item) == AUDIT_ITEM_FIELDS, f"{audit_path}: row {index} fields mismatch")
        require(
            item["question_id"] == transport["question_id"],
            f"{audit_path}: row {index} question order mismatch",
        )
        require(
            item["source_sha256"] == transport["source_sha256"],
            f"{audit_path}: row {index} source hash mismatch",
        )
        candidate = canonical_candidate(transport, item, audit_path=audit_path, index=index)
        if candidate is None:
            quarantined += 1
        else:
            candidates.append(candidate)
    return candidates, quarantined


def write_atomic(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, raw_path = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(contents)
        os.replace(raw_path, path)
    except BaseException:
        Path(raw_path).unlink(missing_ok=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--overlay", required=True, type=Path)
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--audit", required=True, type=Path, action="append")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    existing = read_jsonl(args.overlay) if args.overlay.exists() else []
    by_id: dict[str, dict[str, Any]] = {}
    for index, row in enumerate(existing, 1):
        validate_overlay(row, source=args.overlay, index=index)
        require(row["question_id"] not in by_id, f"{args.overlay}: duplicate question ID")
        by_id[row["question_id"]] = row

    additions: list[dict[str, Any]] = []
    quarantined = 0
    audited_candidates = 0
    for audit_path in args.audit:
        candidates, held = audit_candidates(args.artifact_root, audit_path)
        quarantined += held
        audited_candidates += len(candidates)
        for candidate in candidates:
            question_id = candidate["question_id"]
            prior = by_id.get(question_id)
            if prior is not None:
                require(prior == candidate, f"{audit_path}: {question_id} conflicts with overlay")
                continue
            by_id[question_id] = candidate
            additions.append(candidate)

    rendered = "".join(
        json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n"
        for row in [*existing, *additions]
    ).encode("utf-8")
    result = {
        "valid": True,
        "audits": [str(path) for path in args.audit],
        "existing": len(existing),
        "audited_candidates": audited_candidates,
        "added_drafts": len(additions),
        "skipped_existing": audited_candidates - len(additions),
        "quarantined_not_materialized": quarantined,
        "resulting_overlays": len(existing) + len(additions),
        "result_sha256": hashlib.sha256(rendered).hexdigest(),
        "dry_run": args.dry_run,
    }
    if not args.dry_run:
        write_atomic(args.overlay, rendered)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"content-audit materialization error: {error}", file=sys.stderr)
        raise SystemExit(2)
