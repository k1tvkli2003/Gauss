#!/usr/bin/env python3
"""Build source-bound Jules recovery/rewrite batches without mutating the corpus.

Each batch binds immutable runtime rows to the exact printed question page,
printed explanatory-solution page, and printed answer-key page. The generated
workspace is intentionally ignored by Git. Jules outputs remain untrusted
drafts until a separate validator and certification pipeline accept them.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import shutil
import tempfile
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = ROOT / "flutter_app" / "assets" / "question_bank" / "index.json"
MANIFEST_PATH = ROOT / "data" / "nardebam" / "topic_manifest.json"
CERTIFICATION_PATH = ROOT / "data" / "certification" / "v1" / "manifest.jsonl"
DEFAULT_OUTPUT = ROOT / ".jules" / "source-rewrite"
MAX_JULES_UPLOAD_BYTES = 5_000_000
DEFAULT_QUESTIONS_PER_LANE = 24


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--math-dir", type=Path)
    parser.add_argument("--physics-dir", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--question-index", type=Path, required=True)
    parser.add_argument("--question-index-receipt", type=Path, required=True)
    parser.add_argument("--answer-index", type=Path, required=True)
    parser.add_argument("--answer-index-receipt", type=Path, required=True)
    parser.add_argument("--wave", type=int, required=True)
    parser.add_argument("--lanes", type=int, default=15)
    parser.add_argument("--subject", choices=("math", "physics", "any"), default="any")
    parser.add_argument("--topic")
    parser.add_argument(
        "--batch-size",
        type=int,
        default=DEFAULT_QUESTIONS_PER_LANE,
        help=(
            "Maximum contiguous questions per Jules lane. The source-indexed "
            "page deduplication keeps broad lanes upload-efficient."
        ),
    )
    parser.add_argument("--limit", type=int)
    parser.add_argument("--include-usable", action="store_true")
    parser.add_argument(
        "--retry-untrusted-prior",
        action="store_true",
        help="Requeue IDs from superseded local draft waves; never changes certification state.",
    )
    parser.add_argument("--max-image-width", type=int, default=1280)
    parser.add_argument("--jpeg-quality", type=int, default=70)
    parser.add_argument("--max-upload-bytes", type=int, default=MAX_JULES_UPLOAD_BYTES)
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            raise ValueError(f"{path}: blank line {line_number}")
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError(f"{path}: non-object line {line_number}")
        rows.append(value)
    return rows


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


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_certified_index(
    index_path: Path,
    receipt_path: Path,
    expected_kind: str,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    receipt = read_json(receipt_path)
    if receipt.get("index_kind") != expected_kind:
        raise ValueError(
            f"{receipt_path}: index_kind {receipt.get('index_kind')!r} != {expected_kind!r}"
        )
    if receipt.get("exact_global_coverage") is not True:
        raise ValueError(f"{receipt_path}: exact global coverage not proven")
    if receipt.get("unresolved_notes") != 0:
        raise ValueError(f"{receipt_path}: unresolved source-index notes remain")
    if receipt.get("index_sha256") != sha256_file(index_path):
        raise ValueError(f"{index_path}: hash does not match receipt")
    rows = read_jsonl(index_path)
    if len(rows) != receipt.get("page_count"):
        raise ValueError(f"{index_path}: page count does not match receipt")
    return rows, receipt


def unique_number_map(
    rows: list[dict[str, Any]],
    *,
    numbers_field: str,
    role: str | None = None,
) -> dict[tuple[str, int], dict[str, Any]]:
    result: dict[tuple[str, int], dict[str, Any]] = {}
    for row in rows:
        if role is not None and row.get("role") != role:
            continue
        for number in row[numbers_field]:
            key = (row["subject"], int(number))
            if key in result:
                raise ValueError(f"duplicate source page mapping for {key}")
            result[key] = row
    return result


def continuation_pages(
    start: dict[str, Any],
    page_rows: dict[tuple[str, str, int], dict[str, Any]],
    *,
    pdf_field: str,
) -> list[dict[str, Any]]:
    pages = [start]
    current = start
    while current.get("continues_to_next") is True:
        key = (
            current["subject"],
            current[pdf_field],
            int(current["pdf_page"]) + 1,
        )
        following = page_rows.get(key)
        if following is None:
            raise ValueError(f"continuation page missing for {key}")
        if following.get("continues_from_previous") is not True:
            raise ValueError(f"continuation handshake missing for {key}")
        pages.append(following)
        current = following
        if len(pages) > 4:
            raise ValueError(f"implausibly long source continuation at {key}")
    return pages


def source_dirs(args: argparse.Namespace, manifest: dict[str, Any]) -> dict[str, Path]:
    explicit = {"math": args.math_dir, "physics": args.physics_dir}
    result: dict[str, Path] = {}
    for subject, book in manifest["books"].items():
        environment = os.environ.get(book["source_env"])
        candidate = explicit[subject] or (Path(environment) if environment else None)
        if not candidate or not candidate.is_dir():
            raise ValueError(
                f"missing {subject} source directory; pass --{subject}-dir "
                f"or set {book['source_env']}"
            )
        result[subject] = candidate.resolve()
    return result


def question_rows() -> list[dict[str, Any]]:
    index = read_json(INDEX_PATH)
    asset_root = INDEX_PATH.parent.parent
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for topic in index["topics"]:
        values = read_json(asset_root / topic["file"])
        for row in values:
            question_id = row.get("id")
            if not isinstance(question_id, str) or question_id in seen:
                raise ValueError(f"invalid or duplicate question id {question_id!r}")
            seen.add(question_id)
            rows.append(row)
    if len(rows) != index["total"]:
        raise ValueError(f"index total {index['total']} != loaded rows {len(rows)}")
    return rows


def certification_by_id() -> dict[str, dict[str, Any]]:
    return {row["question_id"]: row for row in read_jsonl(CERTIFICATION_PATH)}


def largest_page_image(page: Any) -> Image.Image:
    candidates: list[Image.Image] = []
    for embedded in page.images:
        try:
            candidates.append(Image.open(io.BytesIO(embedded.data)).convert("RGB"))
        except Exception:
            continue
    if not candidates:
        raise ValueError("PDF page has no extractable raster image")
    return max(candidates, key=lambda image: image.width * image.height)


class PageRenderer:
    def __init__(self, max_width: int, quality: int) -> None:
        self.max_width = max_width
        self.quality = quality
        self._readers: dict[Path, PdfReader] = {}
        self._cache: dict[tuple[Path, int], tuple[bytes, tuple[int, int], tuple[int, int]]] = {}

    def reader(self, pdf: Path) -> PdfReader:
        if pdf not in self._readers:
            self._readers[pdf] = PdfReader(str(pdf), strict=False)
        return self._readers[pdf]

    def render(self, pdf: Path, page_number: int) -> tuple[bytes, tuple[int, int], tuple[int, int]]:
        key = (pdf, page_number)
        if key in self._cache:
            return self._cache[key]
        reader = self.reader(pdf)
        if page_number < 1 or page_number > len(reader.pages):
            raise ValueError(f"invalid page {page_number} for {pdf} ({len(reader.pages)} pages)")
        image = largest_page_image(reader.pages[page_number - 1])
        original = image.size
        if image.width > self.max_width:
            height = round(image.height * self.max_width / image.width)
            image = image.resize((self.max_width, height), Image.Resampling.LANCZOS)
        rendered = image.size
        output = io.BytesIO()
        image.save(output, "JPEG", quality=self.quality, optimize=True, progressive=True)
        value = (output.getvalue(), original, rendered)
        self._cache[key] = value
        return value


def chunks(values: list[dict[str, Any]], size: int) -> Iterable[list[dict[str, Any]]]:
    for index in range(0, len(values), size):
        yield values[index : index + size]


def compact_blocks(value: Any) -> Any:
    if not isinstance(value, list):
        return value
    return [block for block in value if isinstance(block, dict)]


def batch_prompt(batch_id: str, rows: list[dict[str, Any]]) -> str:
    ticket_payload = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    return f"""# Gauss source-first recovery and Persian rewrite — {batch_id}

You are repairing immutable Persian math/physics learning records from printed evidence. Inspect every attached image before writing any row. Image filenames identify QUESTION, SOLUTION, or KEY evidence and their PDF/page. These pages were selected by independently validated, exact-coverage source indexes. The current corpus is not included because it may be badly shifted or corrupted; the printed pages are authoritative.

For every ticket, in the original order:
1. Locate the exact printed question number across all declared QUESTION pages. Recover the complete stem, exactly four options in printed order, units, conditions, diagrams/tables, and every mathematical symbol.
2. Locate the matching printed explanatory answer across all declared SOLUTION pages. Recover its complete reasoning and any meaningful figure. If those indexed pages do not contain that numbered solution, set `status` to `needs_source_followup`; never borrow a neighboring solution.
3. Read the printed option from the KEY page only when its cell is unambiguous. Also solve independently. Report any disagreement among key, printed explanation, and independent derivation.
4. Produce a self-contained, complete, scientifically correct solution. Preserve the intended mathematical/physical proposition and option order. Correct source typos or scientific mistakes only through explicit `corrections`; never silently change meaning.
5. Rewrite every Persian prose sentence in stem, prose options, and solution into friendly, natural, conversational Persian. Preserve every condition, logical quantifier, negation, value, formula, unit, symbol, and fact. Do not leak the answer into the stem. Use at most one purposeful emoji per prose paragraph and never place emoji inside math, numbers, units, or formula-only options.
6. Use ASCII digits `0-9` everywhere. Put mathematical notation in valid `$...$` LaTeX. Do not use Persian/Arabic digits.
7. Describe each necessary question/solution image as a precise source crop request; do not redraw or hallucinate it. Every included media item must have a tight non-null pixel crop. Omit decorative page furniture and omit `media` entirely when no diagram/table is required.

Return exactly one compact JSON object per ticket, original order, inside one ```jsonl fenced block and no prose outside it. Exact fields per row:
`ticket_id`, `question_id`, `source_sha256`, `status`, `recovered`, `friendly`, `answer`, `media`, `corrections`, `evidence`, `blockers`.

Contracts:
- `status`: `draft` or `needs_source_followup`.
- `recovered`: `{{"stem":"...","options":["...","...","...","..."],"solution":"..."}}` faithful to print.
- `friendly`: same exact shape, conversational Persian with semantic equivalence and ASCII digits.
- `answer`: `{{"printed_key_option":1..4|null,"independent_option":1..4|null,"final_option":1..4|null,"agreement":true|false|null}}`.
- `media`: array of `{{"source":"question"|"solution","page_file":"...","placement":"stem"|"option_1"|"option_2"|"option_3"|"option_4"|"solution","crop_box":[left,top,right,bottom],"alt_fa":"..."}}`. Pixel boxes use the attached JPEG coordinates and must tightly contain only the necessary diagram/table. Never use `null` or a whole-page crop.
- `corrections`: array of explicit `{{"field":"stem"|"option_1"|"option_2"|"option_3"|"option_4"|"solution"|"answer","printed":"...","corrected":"...","reason":"..."}}`.
- `evidence`: `{{"question_pages":["..."],"solution_pages":["..."],"key_page":"...","source_recovery":"...","independent_derivation":"...","scientific_review":"...","rewrite_fidelity_review":"..."}}`; copy the exact ordered indexed page lists, name the exact KEY file containing the cell, and keep every review string non-empty.
- `blockers`: unique string array. Any unreadable/cropped/missing/mismatched/ambiguous evidence requires `needs_source_followup` with precise blockers.
- Never claim certification or runtime usability. Never omit a ticket. Never output Markdown inside JSON strings.

TICKETS:
{ticket_payload}
"""


def main() -> int:
    args = parse_args()
    if args.wave < 1 or args.lanes < 1 or args.batch_size < 1:
        raise ValueError("wave, lanes, and batch-size must be positive")
    if args.max_upload_bytes <= 0 or args.max_upload_bytes > MAX_JULES_UPLOAD_BYTES:
        raise ValueError(f"max-upload-bytes must be in 1..{MAX_JULES_UPLOAD_BYTES}")

    manifest = read_json(MANIFEST_PATH)
    sources = source_dirs(args, manifest)
    question_index_rows, question_index_receipt = load_certified_index(
        args.question_index.resolve(),
        args.question_index_receipt.resolve(),
        "question",
    )
    answer_index_rows, answer_index_receipt = load_certified_index(
        args.answer_index.resolve(),
        args.answer_index_receipt.resolve(),
        "answer",
    )
    question_number_map = unique_number_map(
        question_index_rows, numbers_field="numbered_questions"
    )
    solution_number_map = unique_number_map(
        answer_index_rows, numbers_field="numbered_items", role="solution"
    )
    key_number_map = unique_number_map(
        answer_index_rows, numbers_field="numbered_items", role="key"
    )
    expected_total = sum(manifest["expected_question_counts"].values())
    for label, mapping in (
        ("question", question_number_map),
        ("solution", solution_number_map),
        ("key", key_number_map),
    ):
        if len(mapping) != expected_total:
            raise ValueError(
                f"certified {label} index maps {len(mapping)} questions, expected {expected_total}"
            )
    question_page_rows = {
        (row["subject"], row["question_pdf"], int(row["pdf_page"])): row
        for row in question_index_rows
    }
    answer_page_rows = {
        (row["subject"], row["answer_pdf"], int(row["pdf_page"])): row
        for row in answer_index_rows
    }
    index_binding = {
        "question_index_file": args.question_index.name,
        "question_index_sha256": sha256_file(args.question_index),
        "question_index_receipt_file": args.question_index_receipt.name,
        "question_index_receipt_sha256": sha256_file(args.question_index_receipt),
        "answer_index_file": args.answer_index.name,
        "answer_index_sha256": sha256_file(args.answer_index),
        "answer_index_receipt_file": args.answer_index_receipt.name,
        "answer_index_receipt_sha256": sha256_file(args.answer_index_receipt),
        "exact_question_coverage": question_index_receipt["exact_global_coverage"],
        "exact_answer_coverage": answer_index_receipt["exact_global_coverage"],
    }
    certification = certification_by_id()
    rows = question_rows()
    numbered_rows: dict[tuple[str, int], dict[str, Any]] = {}
    for row in rows:
        provenance = row.get("provenance") or {}
        key = (row["subject"], int(provenance["question_number"]))
        if key in numbered_rows:
            raise ValueError(f"duplicate runtime question number {key}")
        numbered_rows[key] = row
    if len(numbered_rows) != expected_total:
        raise ValueError(
            f"runtime corpus maps {len(numbered_rows)} source numbers, expected {expected_total}"
        )
    runtime_keys = set(numbered_rows)
    for label, mapping in (
        ("question", question_number_map),
        ("solution", solution_number_map),
        ("key", key_number_map),
    ):
        if set(mapping) != runtime_keys:
            missing = sorted(runtime_keys - set(mapping))[:20]
            extra = sorted(set(mapping) - runtime_keys)[:20]
            raise ValueError(
                f"{label} index keys do not equal runtime source numbers; "
                f"missing={missing}, extra={extra}"
            )
    rows.sort(
        key=lambda row: (
            0 if row["subject"] == "math" else 1,
            int(row["provenance"]["question_number"]),
        )
    )
    prior: set[str] = set()
    current_wave_manifest = args.output / f"wave-{args.wave:04d}" / "wave.json"
    for path in sorted(args.output.glob("wave-*/wave.json")):
        if path == current_wave_manifest:
            continue
        wave = read_json(path)
        prior.update(wave.get("question_ids", []))

    selected: list[dict[str, Any]] = []
    for row in rows:
        record = certification.get(row["id"])
        if record is None:
            raise ValueError(f"missing certification row for {row['id']}")
        if not args.retry_untrusted_prior and row["id"] in prior:
            continue
        if args.subject != "any" and row.get("subject") != args.subject:
            continue
        if args.topic and row.get("topic_key") != args.topic:
            continue
        if not args.include_usable and record.get("certification", {}).get("usable") is True:
            continue
        selected.append(row)
        if args.limit and len(selected) >= args.limit:
            break

    maximum = args.lanes * args.batch_size
    selected = selected[:maximum]
    if not selected:
        raise ValueError("no eligible questions remain")

    wave_dir = args.output / f"wave-{args.wave:04d}"
    if wave_dir.exists():
        if not args.force:
            raise ValueError(f"refusing to overwrite {wave_dir}; pass --force")
        shutil.rmtree(wave_dir)
    wave_dir.mkdir(parents=True)

    renderer = PageRenderer(args.max_image_width, args.jpeg_quality)
    resolved_batches: list[dict[str, Any]] = []
    lane_batches: list[list[dict[str, Any]]] = []
    if len(selected) >= args.lanes:
        base, remainder = divmod(len(selected), args.lanes)
        cursor = 0
        for lane_index in range(args.lanes):
            size = base + (1 if lane_index < remainder else 0)
            lane_batches.append(selected[cursor : cursor + size])
            cursor += size
    else:
        lane_batches = list(chunks(selected, args.batch_size))

    for batch_index, batch_rows in enumerate(lane_batches, 1):
        batch_id = f"source-rewrite-{args.wave:04d}-{batch_index:02d}"
        batch_dir = wave_dir / "batches" / batch_id
        image_dir = batch_dir / "images"
        image_dir.mkdir(parents=True)
        attachments: dict[tuple[str, str, str, int], dict[str, Any]] = {}
        tickets: list[dict[str, Any]] = []
        source_pdf_hashes: dict[Path, str] = {}

        def attach(
            subject: str,
            role: str,
            page_row: dict[str, Any],
            *,
            pdf_field: str,
        ) -> str:
            pdf_name = str(page_row[pdf_field])
            page = int(page_row["pdf_page"])
            key = (subject, role, pdf_name, page)
            if key in attachments:
                return attachments[key]["file"]
            pdf = sources[subject] / pdf_name
            expected_pdf_hash = str(page_row["source_pdf_sha256"])
            actual_pdf_hash = source_pdf_hashes.get(pdf)
            if actual_pdf_hash is None:
                actual_pdf_hash = sha256_file(pdf)
                source_pdf_hashes[pdf] = actual_pdf_hash
            if actual_pdf_hash != expected_pdf_hash:
                raise ValueError(
                    f"{subject} {pdf_name}: source PDF hash changed since source indexing"
                )
            data, original, rendered = renderer.render(pdf, page)
            filename = f"{role.upper()}_{subject}_{Path(pdf_name).stem}_p{page:04d}.jpg"
            path = image_dir / filename
            write_atomic(path, data)
            attachments[key] = {
                "role": role,
                "subject": subject,
                "file": filename,
                "source_pdf": pdf_name,
                "source_pdf_sha256": actual_pdf_hash,
                "indexed_page_sha256": page_row["page_sha256"],
                "pdf_page": page,
                "original_size": list(original),
                "rendered_size": list(rendered),
                "sha256": sha256_bytes(data),
                "bytes": len(data),
            }
            return filename

        for row in batch_rows:
            subject = row["subject"]
            provenance = row.get("provenance") or {}
            question_number = int(provenance["question_number"])
            lookup = (subject, question_number)
            question_start = question_number_map.get(lookup)
            solution_start = solution_number_map.get(lookup)
            key_row = key_number_map.get(lookup)
            if question_start is None or solution_start is None or key_row is None:
                raise ValueError(f"certified source mapping missing for {lookup}")
            question_pages = continuation_pages(
                question_start,
                question_page_rows,
                pdf_field="question_pdf",
            )
            solution_pages = continuation_pages(
                solution_start,
                answer_page_rows,
                pdf_field="answer_pdf",
            )
            question_files = [
                attach(subject, "question", page_row, pdf_field="question_pdf")
                for page_row in question_pages
            ]
            solution_files = [
                attach(subject, "solution", page_row, pdf_field="answer_pdf")
                for page_row in solution_pages
            ]
            key_file = attach(subject, "key", key_row, pdf_field="answer_pdf")
            record = certification[row["id"]]
            tickets.append(
                {
                    "ticket_id": f"source-rewrite:{row['id']}:{record['source_sha256'][:12]}",
                    "question_id": row["id"],
                    "source_sha256": record["source_sha256"],
                    "subject": subject,
                    "topic_key": row["topic_key"],
                    "source_topic_key": question_start["topic_key"],
                    "question_number": question_number,
                    "source_files": {
                        "question_pages": question_files,
                        "solution_pages": solution_files,
                        "key_page": key_file,
                    },
                    "recorded_provenance": provenance,
                    "blocking_issues": record.get("screening", {}).get("issues", []),
                }
            )

        ordered_attachments = sorted(
            attachments.values(),
            key=lambda item: (
                item["subject"],
                item["role"],
                item["source_pdf"],
                item["pdf_page"],
            ),
        )
        attachment_bytes = sum(item["bytes"] for item in ordered_attachments)
        if attachment_bytes > args.max_upload_bytes:
            raise ValueError(
                f"{batch_id}: attachments {attachment_bytes} exceed limit {args.max_upload_bytes}; "
                "lower batch-size/width/quality"
            )
        prompt = batch_prompt(batch_id, tickets)
        write_atomic(batch_dir / "prompt.md", prompt.encode("utf-8"))
        batch_manifest = {
            "schema_version": 2,
            "prompt_contract": "gauss-source-rewrite-v2",
            "batch_id": batch_id,
            "lane": batch_index,
            "question_ids": [row["id"] for row in batch_rows],
            "item_count": len(batch_rows),
            "tickets": tickets,
            "attachments": ordered_attachments,
            "attachment_bytes": attachment_bytes,
            "max_upload_bytes": args.max_upload_bytes,
            "prompt_sha256": sha256_bytes(prompt.encode("utf-8")),
            "expected_output": f"{batch_id}.output.jsonl",
            "source_index_binding": index_binding,
        }
        write_atomic(
            batch_dir / "batch.json",
            (json.dumps(batch_manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
        )
        resolved_batches.append(batch_manifest)

    wave_manifest = {
        "schema_version": 2,
        "prompt_contract": "gauss-source-rewrite-v2",
        "wave": args.wave,
        "lane_count": len(resolved_batches),
        "question_count": len(selected),
        "question_ids": [row["id"] for row in selected],
        "batches": resolved_batches,
        "immutable_sources_edited": False,
        "output_trust": "untrusted_draft_until_independent_validation",
        "retry_untrusted_prior": args.retry_untrusted_prior,
        "source_index_binding": index_binding,
    }
    write_atomic(
        wave_dir / "wave.json",
        (json.dumps(wave_manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )
    print(json.dumps(wave_manifest, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"source rewrite preparation error: {error}")
        raise SystemExit(2)
