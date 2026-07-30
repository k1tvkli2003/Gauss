"""Fail-closed materializer for structurally validated Jules repair drafts.

The Jules repair lane emits transport rows with ticket identifiers and optional
effective-option observations. This utility deliberately retains only canonical
source-preserving *solution addendum* drafts for the derived overlay ledger.
It cannot alter source JSON/media, certify an answer, or promote a runtime
question. Rows marked ``under_review`` are counted and left out of the ledger.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any


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
QUESTION_ID = re.compile(r"^[a-z0-9_-]+$")
SHA256 = re.compile(r"^[a-f0-9]{64}$")


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            raise ValueError(f"{path}: line {line_number} is blank")
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError(f"{path}: line {line_number} is not an object")
        rows.append(value)
    return rows


def canonical(row: dict[str, Any], *, source: Path, index: int) -> dict[str, Any] | None:
    prefix = f"{source}: row {index}"
    if set(row) != TRANSPORT_FIELDS:
        raise ValueError(f"{prefix} has unexpected transport fields")
    if row["status"] == "under_review":
        blockers = row["blockers"]
        if (
            row["patch"] != {}
            or not isinstance(blockers, list)
            or not blockers
            or any(not isinstance(blocker, str) or not blocker.strip() for blocker in blockers)
        ):
            raise ValueError(f"{prefix} has an invalid under-review shape")
        return None
    if row["status"] != "draft":
        raise ValueError(f"{prefix} has unsupported status {row['status']!r}")
    if not isinstance(row["blockers"], list) or row["blockers"] != []:
        raise ValueError(f"{prefix} draft retains blockers")
    option = row["effective_option"]
    if option is not None and (type(option) is not int or not 1 <= option <= 4):
        raise ValueError(f"{prefix} has an invalid effective option")
    if not isinstance(row["patch"], dict) or set(row["patch"]) != PATCH_FIELDS:
        raise ValueError(f"{prefix} has an invalid draft patch")
    patch = row["patch"]
    if (
        patch["target"] != "solution"
        or patch["kind"] != "addendum"
        or patch["preserve_source"] is not True
        or not isinstance(patch["solution_addendum"], str)
        or len(patch["solution_addendum"].strip()) < 8
    ):
        raise ValueError(f"{prefix} is not a canonical source-preserving addendum")
    if not isinstance(row["evidence"], dict) or set(row["evidence"]) != EVIDENCE_FIELDS:
        raise ValueError(f"{prefix} has incomplete review evidence")
    if any(
        not isinstance(row["evidence"][key], str)
        or len(row["evidence"][key].strip()) < 8
        for key in EVIDENCE_FIELDS
    ):
        raise ValueError(f"{prefix} contains an empty review observation")
    if not isinstance(row["question_id"], str) or not QUESTION_ID.fullmatch(row["question_id"]):
        raise ValueError(f"{prefix} has an invalid question id")
    if not isinstance(row["source_sha256"], str) or not SHA256.fullmatch(row["source_sha256"]):
        raise ValueError(f"{prefix} has an invalid source hash")
    return {
        "schema_version": 1,
        "question_id": row["question_id"],
        "source_sha256": row["source_sha256"],
        "status": "draft",
        "patch": patch,
        "evidence": row["evidence"],
    }


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
    parser.add_argument("--input", required=True, type=Path, action="append")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    existing = read_jsonl(args.overlay) if args.overlay.exists() else []
    by_id = {row.get("question_id"): row for row in existing}
    if len(by_id) != len(existing):
        raise ValueError("canonical overlay has duplicate question ids")
    additions: list[dict[str, Any]] = []
    under_review = 0
    skipped_existing = 0
    for source in args.input:
        for index, row in enumerate(read_jsonl(source), 1):
            candidate = canonical(row, source=source, index=index)
            if candidate is None:
                under_review += 1
                continue
            prior = by_id.get(candidate["question_id"])
            if prior is not None:
                if prior != candidate:
                    raise ValueError(
                        f"{source}: {candidate['question_id']} conflicts with canonical overlay"
                    )
                skipped_existing += 1
                continue
            by_id[candidate["question_id"]] = candidate
            additions.append(candidate)

    rendered = "".join(
        json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n"
        for row in [*existing, *additions]
    ).encode("utf-8")
    result = {
        "valid": True,
        "inputs": [str(path) for path in args.input],
        "existing": len(existing),
        "added_drafts": len(additions),
        "skipped_existing": skipped_existing,
        "under_review_not_materialized": under_review,
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
        print(f"materialization error: {error}", file=sys.stderr)
        raise SystemExit(2)
