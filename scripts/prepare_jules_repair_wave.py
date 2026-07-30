"""Prepare deterministic, source-key-blind, text-only Jules repair batches.

The immutable corpus contains source answer keys, but this allocator never
reads, exports, or uses that field. It emits only ticket identity, source hash,
blocking signals, prompt/options/solution text, and a strict output contract.
Generated operations live in an ignored Jules directory; no source JSON or
media is changed.
"""

from __future__ import annotations

import argparse
import json
import os
import tempfile
from pathlib import Path
from typing import Any, Iterable


STRICT_PROMPT = """You are a repair specialist for an immutable math-question corpus. Work source-key-blind: the source answer key is not supplied and you must not request, infer, or use it. Do not edit source JSON, media, manifests, or repository files. For each ticket, re-derive only from the supplied stem/options, audit the supplied solution, and propose a source-preserving solution addendum only when it resolves the blocking issue without changing the question.

Return exactly one JSON object per ticket in original order, inside one ```jsonl fenced block. There must be no prose outside that block. Every object must have exactly these fields: ticket_id, question_id, source_sha256, status, patch, evidence, effective_option, blockers.

Allowed outcomes:
- draft: patch must be exactly {"target":"solution","kind":"addendum","solution_addendum":"<non-empty repair>","preserve_source":true}; evidence must contain non-empty independent_solve, solution_review, and adversarial_review strings; blockers must be [].
- under_review: patch must be {}; evidence must still contain the same three non-empty review strings; effective_option may be null; blockers must be a non-empty unique string array explaining the unresolved contradiction, ambiguity, missing information, or unsafe repair.

Status may only be draft or under_review. effective_option is a 1-based observation (1..4) or null; it is never a source-key correction or certification. Never discard a record, never replace source content, and never claim a question is runtime-ready or mathematically certified.

TICKETS:
"""


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    values: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            raise ValueError(f"{path}: blank line {line_number}")
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError(f"{path}: non-object line {line_number}")
        values.append(value)
    return values


def all_blocks_text(value: Any) -> bool:
    if not isinstance(value, list):
        return False
    for block in value:
        if not isinstance(block, dict) or block.get("type") != "text":
            return False
    return True


def question_map(index_path: Path) -> dict[str, dict[str, Any]]:
    index = read_json(index_path)
    if not isinstance(index, dict) or not isinstance(index.get("topics"), list):
        raise ValueError("question-bank index has no topics")
    result: dict[str, dict[str, Any]] = {}
    asset_root = index_path.parent.parent
    for topic in index["topics"]:
        if not isinstance(topic, dict) or not isinstance(topic.get("file"), str):
            raise ValueError("question-bank topic is invalid")
        rows = read_json(asset_root / topic["file"])
        if not isinstance(rows, list):
            raise ValueError(f"question-bank topic {topic['file']} is not a list")
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("id"), str):
                raise ValueError("question-bank row has no stable id")
            if row["id"] in result:
                raise ValueError(f"duplicate question id {row['id']}")
            result[row["id"]] = row
    return result


def prior_ids(workspace: Path) -> set[str]:
    result: set[str] = set()
    for path in sorted(workspace.glob("repair-*.input.json")):
        rows = read_json(path)
        if not isinstance(rows, list):
            raise ValueError(f"prior input {path} is not an array")
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("question_id"), str):
                raise ValueError(f"prior input {path} lacks a question id")
            result.add(row["question_id"])
    return result


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


def chunks(values: list[dict[str, Any]], size: int) -> Iterable[list[dict[str, Any]]]:
    for index in range(0, len(values), size):
        yield values[index : index + size]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--queue", default="data/certification/v1/repair-queue.jsonl", type=Path)
    parser.add_argument("--overlay", default="data/certification/v1/repair-overlays.jsonl", type=Path)
    parser.add_argument("--index", default="flutter_app/assets/question_bank/index.json", type=Path)
    parser.add_argument("--first", required=True, type=int)
    parser.add_argument("--batches", default=7, type=int)
    parser.add_argument("--batch-size", default=10, type=int)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.first < 1 or args.batches < 1 or args.batch_size < 1:
        raise ValueError("first, batches, and batch-size must be positive")

    batch_ids = [f"repair-{number:03d}" for number in range(args.first, args.first + args.batches)]
    output_paths = [
        path
        for batch_id in batch_ids
        for path in (
            args.workspace / f"{batch_id}.input.json",
            args.workspace / f"{batch_id}.prompt.md",
        )
    ]
    manifest_path = args.workspace / f"repair-wave-{args.first:03d}-{args.first + args.batches - 1:03d}.tasks.json"
    if any(path.exists() for path in [*output_paths, manifest_path]):
        raise ValueError("refusing to overwrite an existing repair wave")

    assigned_before = prior_ids(args.workspace)
    overlay_ids = {row["question_id"] for row in read_jsonl(args.overlay)}
    questions = question_map(args.index)
    candidates: list[dict[str, Any]] = []
    for ticket in read_jsonl(args.queue):
        question_id = ticket.get("question_id")
        state = ticket.get("current_state")
        if (
            ticket.get("repair_kind") != "solution_rederive"
            or not isinstance(question_id, str)
            or question_id in assigned_before
            or question_id in overlay_ids
            or not isinstance(state, dict)
            or state.get("extraction") != "screened_complete"
        ):
            continue
        question = questions.get(question_id)
        if question is None or question.get("subject") != "math":
            continue
        if not (
            all_blocks_text(question.get("stem"))
            and isinstance(question.get("options"), list)
            and all(all_blocks_text(option) for option in question["options"])
            and all_blocks_text(question.get("solution"))
        ):
            continue
        candidates.append(
            {
                "ticket_id": ticket["ticket_id"],
                "question_id": question_id,
                "source_sha256": ticket["source_sha256"],
                "blocking_issues": ticket["blocking_issues"],
                "stem": question["stem"],
                "options": question["options"],
                "solution": question["solution"],
            }
        )
    candidates.sort(key=lambda row: row["question_id"])
    needed = args.batches * args.batch_size
    if len(candidates) < needed:
        raise ValueError(f"only {len(candidates)} eligible source-key-blind tickets; need {needed}")
    selected = candidates[:needed]
    grouped = list(chunks(selected, args.batch_size))
    manifest = {
        "schemaVersion": 1,
        "batchId": f"gauss-repair-wave-{args.first:03d}-{args.first + args.batches - 1:03d}",
        "defaults": {"requirePlanApproval": False, "automationMode": None},
        "tasks": [
            {
                "id": batch_id,
                "title": f"Gauss source-preserving math repair batch {batch_id[-3:]}",
                "promptFile": f"{batch_id}.prompt.md",
                "metadata": {"input": f"{batch_id}.input.json", "output": f"{batch_id}.jsonl"},
            }
            for batch_id in batch_ids
        ],
    }
    report = {
        "valid": True,
        "workspace": str(args.workspace),
        "eligible": len(candidates),
        "selected": len(selected),
        "batches": [
            {"id": batch_id, "question_ids": [row["question_id"] for row in rows]}
            for batch_id, rows in zip(batch_ids, grouped)
        ],
        "dry_run": args.dry_run,
    }
    if not args.dry_run:
        args.workspace.mkdir(parents=True, exist_ok=True)
        for batch_id, rows in zip(batch_ids, grouped):
            payload = json.dumps(rows, ensure_ascii=False, indent=2).encode("utf-8") + b"\n"
            write_atomic(args.workspace / f"{batch_id}.input.json", payload)
            prompt = STRICT_PROMPT + json.dumps(rows, ensure_ascii=False, separators=(",", ":")) + "\n"
            write_atomic(args.workspace / f"{batch_id}.prompt.md", prompt.encode("utf-8"))
        write_atomic(
            manifest_path,
            (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
        )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"wave preparation error: {error}")
        raise SystemExit(2)
