#!/usr/bin/env python3
"""Prepare hash-bound Jules lanes that index every numbered source-question page.

The existing corpus is intentionally excluded.  The resulting inventory binds
the immutable source PDFs to rendered evidence and records which global printed
question numbers begin on each PDF page.  It is a discovery artifact only; it
does not certify or mutate any question record.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data" / "nardebam" / "topic_manifest.json"
DEFAULT_OUTPUT = ROOT / ".jules" / "source-inventory"
MAX_UPLOAD_BYTES = 5_000_000


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--math-dir", type=Path)
    parser.add_argument("--physics-dir", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--wave", type=int, required=True)
    parser.add_argument("--lanes", type=int, default=15)
    parser.add_argument("--segment-pages", type=int, default=12)
    parser.add_argument("--max-image-width", type=int, default=900)
    parser.add_argument("--jpeg-quality", type=int, default=55)
    parser.add_argument("--max-upload-bytes", type=int, default=MAX_UPLOAD_BYTES)
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


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


@dataclass(frozen=True)
class RenderedPage:
    subject: str
    topic_key: str
    topic_order: int
    question_pdf: str
    pdf_page: int
    source_pdf_sha256: str
    filename: str
    data: bytes
    page_sha256: str
    original_size: tuple[int, int]
    rendered_size: tuple[int, int]

    @property
    def byte_count(self) -> int:
        return len(self.data)

    @property
    def ticket_id(self) -> str:
        return (
            f"source-page:{self.subject}:{self.topic_key}:"
            f"{Path(self.question_pdf).stem}:p{self.pdf_page:04d}:"
            f"{self.page_sha256[:12]}"
        )


def render_page(
    *,
    subject: str,
    topic: dict[str, Any],
    pdf: Path,
    pdf_hash: str,
    page_number: int,
    page: Any,
    max_width: int,
    quality: int,
) -> RenderedPage:
    image = largest_page_image(page)
    original = image.size
    if image.width > max_width:
        height = round(image.height * max_width / image.width)
        image = image.resize((max_width, height), Image.Resampling.LANCZOS)
    rendered = image.size
    output = io.BytesIO()
    image.save(output, "JPEG", quality=quality, optimize=True, progressive=True)
    data = output.getvalue()
    filename = (
        f"QUESTION_{subject}_{topic['order']:02d}_{topic['key']}_"
        f"{Path(topic['question_pdf']).stem}_p{page_number:04d}.jpg"
    )
    return RenderedPage(
        subject=subject,
        topic_key=str(topic["key"]),
        topic_order=int(topic["order"]),
        question_pdf=str(topic["question_pdf"]),
        pdf_page=page_number,
        source_pdf_sha256=pdf_hash,
        filename=filename,
        data=data,
        page_sha256=sha256_bytes(data),
        original_size=original,
        rendered_size=rendered,
    )


def segment_pages(pages: list[RenderedPage], segment_size: int) -> list[list[RenderedPage]]:
    segments: list[list[RenderedPage]] = []
    grouped: dict[tuple[str, int], list[RenderedPage]] = {}
    for page in pages:
        grouped.setdefault((page.subject, page.topic_order), []).append(page)
    for key in sorted(grouped, key=lambda item: (item[0], item[1])):
        ordered = sorted(grouped[key], key=lambda item: item.pdf_page)
        for index in range(0, len(ordered), segment_size):
            segments.append(ordered[index : index + segment_size])
    return segments


def assign_lanes(
    segments: list[list[RenderedPage]], lane_count: int, max_upload_bytes: int
) -> list[list[RenderedPage]]:
    if lane_count < 1:
        raise ValueError("lanes must be positive")
    lanes: list[list[RenderedPage]] = [[] for _ in range(lane_count)]
    totals = [0] * lane_count
    for segment in sorted(segments, key=lambda value: sum(p.byte_count for p in value), reverse=True):
        target = min(range(lane_count), key=lambda index: totals[index])
        segment_bytes = sum(page.byte_count for page in segment)
        if totals[target] + segment_bytes > max_upload_bytes:
            alternatives = [
                index
                for index in range(lane_count)
                if totals[index] + segment_bytes <= max_upload_bytes
            ]
            if not alternatives:
                raise ValueError(
                    "cannot assign source pages below upload limit; reduce image width/quality "
                    "or segment-pages"
                )
            target = min(alternatives, key=lambda index: totals[index])
        lanes[target].extend(segment)
        totals[target] += segment_bytes
    return [
        sorted(lane, key=lambda page: (page.subject, page.topic_order, page.pdf_page))
        for lane in lanes
        if lane
    ]


def lane_prompt(batch_id: str, tickets: list[dict[str, Any]]) -> str:
    payload = json.dumps(tickets, ensure_ascii=False, separators=(",", ":"))
    return f"""# Gauss immutable source-page inventory — {batch_id}

Inspect every attached QUESTION image at full resolution. This is a blind source-indexing lane: no current Gauss question text, solution, or key is provided or authoritative.

For every ticket, in the exact ticket order, identify only the globally numbered four-option bank questions printed on that PDF page. Do not count unnumbered lesson examples or boxes merely labelled «تست». The real bank begins under a four-option-questions heading and prints a global integer before each question. A page can contain lesson material, bank questions, both, or no usable content.

Create `source_inventory.jsonl` and also return its exact contents in one fenced `jsonl` block with no prose outside it. Write exactly one compact JSON object per ticket with these exact fields:

- `ticket_id`, `subject`, `topic_key`, `question_pdf`, `pdf_page`, `page_file`, `source_pdf_sha256`, `page_sha256`: copy exactly from the ticket.
- `page_kind`: one of `lesson`, `question`, `mixed`, `blank`.
- `printed_page_label`: the visible printed page label using ASCII digits, or `null` if absent/unreadable.
- `numbered_questions`: sorted unique array of every global bank question number whose stem begins on this page. Use ASCII JSON integers, never Persian digits.
- `first_global_question` and `last_global_question`: first/last value in `numbered_questions`, otherwise `null`.
- `continues_from_previous` and `continues_to_next`: booleans for a numbered bank question cut across a page edge.
- `notes`: unique short strings for ambiguity, crop, missing option, unreadable number, or any risk. Use `[]` only when the page mapping is unambiguous.

Fail closed: never infer a number from a neighboring ticket, never renumber a local lesson example, and never fill a gap by sequence alone. Preserve uncertain evidence in `notes`; do not guess. Do not transcribe stems/options in this indexing wave.

TICKETS:
{payload}
"""


def main() -> int:
    args = parse_args()
    if args.wave < 1 or args.lanes < 1 or args.segment_pages < 1:
        raise ValueError("wave, lanes, and segment-pages must be positive")
    if args.max_upload_bytes < 1 or args.max_upload_bytes > MAX_UPLOAD_BYTES:
        raise ValueError(f"max-upload-bytes must be in 1..{MAX_UPLOAD_BYTES}")

    manifest = read_json(MANIFEST_PATH)
    sources = source_dirs(args, manifest)
    rendered_pages: list[RenderedPage] = []
    source_pdfs: dict[str, dict[str, Any]] = {}

    for subject, book in manifest["books"].items():
        for topic in book["topics"]:
            pdf = sources[subject] / topic["question_pdf"]
            if not pdf.is_file():
                raise ValueError(f"missing source PDF {pdf}")
            pdf_hash = sha256_file(pdf)
            reader = PdfReader(str(pdf), strict=False)
            source_pdfs[f"{subject}:{topic['key']}"] = {
                "subject": subject,
                "topic_key": topic["key"],
                "topic_order": topic["order"],
                "question_pdf": topic["question_pdf"],
                "source_pdf_sha256": pdf_hash,
                "page_count": len(reader.pages),
            }
            for page_number, page in enumerate(reader.pages, 1):
                rendered_pages.append(
                    render_page(
                        subject=subject,
                        topic=topic,
                        pdf=pdf,
                        pdf_hash=pdf_hash,
                        page_number=page_number,
                        page=page,
                        max_width=args.max_image_width,
                        quality=args.jpeg_quality,
                    )
                )

    segments = segment_pages(rendered_pages, args.segment_pages)
    lanes = assign_lanes(segments, args.lanes, args.max_upload_bytes)
    if len(lanes) != args.lanes:
        raise ValueError(f"expected {args.lanes} non-empty lanes, built {len(lanes)}")

    wave_dir = args.output / f"wave-{args.wave:04d}"
    if wave_dir.exists():
        if not args.force:
            raise ValueError(f"refusing to overwrite {wave_dir}; pass --force")
        shutil.rmtree(wave_dir)
    wave_dir.mkdir(parents=True)

    batches: list[dict[str, Any]] = []
    for lane_number, pages in enumerate(lanes, 1):
        batch_id = f"source-inventory-{args.wave:04d}-{lane_number:02d}"
        batch_dir = wave_dir / "batches" / batch_id
        image_dir = batch_dir / "images"
        image_dir.mkdir(parents=True)
        tickets: list[dict[str, Any]] = []
        attachments: list[dict[str, Any]] = []
        for page in pages:
            write_atomic(image_dir / page.filename, page.data)
            ticket = {
                "ticket_id": page.ticket_id,
                "subject": page.subject,
                "topic_key": page.topic_key,
                "question_pdf": page.question_pdf,
                "pdf_page": page.pdf_page,
                "page_file": page.filename,
                "source_pdf_sha256": page.source_pdf_sha256,
                "page_sha256": page.page_sha256,
            }
            tickets.append(ticket)
            attachments.append(
                {
                    **ticket,
                    "original_size": list(page.original_size),
                    "rendered_size": list(page.rendered_size),
                    "bytes": page.byte_count,
                }
            )
        prompt = lane_prompt(batch_id, tickets)
        write_atomic(batch_dir / "prompt.md", prompt.encode("utf-8"))
        batch = {
            "schema_version": 1,
            "prompt_contract": "gauss-source-inventory-v1",
            "batch_id": batch_id,
            "lane": lane_number,
            "item_count": len(tickets),
            "tickets": tickets,
            "attachments": attachments,
            "attachment_bytes": sum(item["bytes"] for item in attachments),
            "max_upload_bytes": args.max_upload_bytes,
            "prompt_sha256": sha256_bytes(prompt.encode("utf-8")),
            "expected_output": f"{batch_id}.output.jsonl",
        }
        write_atomic(
            batch_dir / "batch.json",
            (json.dumps(batch, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
        )
        batches.append(batch)

    wave = {
        "schema_version": 1,
        "prompt_contract": "gauss-source-inventory-v1",
        "wave": args.wave,
        "lane_count": len(batches),
        "source_pdf_count": len(source_pdfs),
        "source_page_count": len(rendered_pages),
        "source_pdfs": list(source_pdfs.values()),
        "batches": batches,
        "immutable_sources_edited": False,
        "output_trust": "untrusted_source_index_draft_until_local_validation",
    }
    write_atomic(
        wave_dir / "wave.json",
        (json.dumps(wave, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )
    print(
        json.dumps(
            {
                "wave": args.wave,
                "lanes": len(batches),
                "source_pdfs": len(source_pdfs),
                "source_pages": len(rendered_pages),
                "lane_pages": [batch["item_count"] for batch in batches],
                "lane_bytes": [batch["attachment_bytes"] for batch in batches],
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"source inventory preparation error: {error}")
        raise SystemExit(2)
