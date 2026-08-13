#!/usr/bin/env python3
"""Prepare hash-bound Jules lanes for solution-page and printed-key indexing."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Any

from pypdf import PdfReader

from prepare_jules_source_inventory import (
    DEFAULT_OUTPUT as QUESTION_DEFAULT_OUTPUT,
    MAX_UPLOAD_BYTES,
    RenderedPage,
    assign_lanes,
    read_json,
    render_page,
    segment_pages,
    sha256_bytes,
    sha256_file,
    source_dirs,
    write_atomic,
)


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data" / "nardebam" / "topic_manifest.json"
DEFAULT_OUTPUT = QUESTION_DEFAULT_OUTPUT.parent / "answer-inventory"


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


def answer_prompt(batch_id: str, tickets: list[dict[str, Any]]) -> str:
    payload = json.dumps(tickets, ensure_ascii=False, separators=(",", ":"))
    return f"""# Gauss immutable solution/key page inventory — {batch_id}

Inspect every attached image at full resolution. This is a blind evidence-indexing lane: no current Gauss question text, answer, or solution is provided or authoritative.

For every ticket, in exact ticket order:

- When `role` is `solution`, identify every globally numbered explanatory-solution block whose heading begins on that PDF page. Do not count an unnumbered continuation from the previous page as a new item.
- When `role` is `key`, identify every global question number with a visible printed answer cell on that page. Read the table bounds visually; do not fill a gap from sequence alone when the table is cropped or unreadable.

Create `answer_inventory.jsonl` and also return its exact contents in one fenced `jsonl` block with no prose outside it. Write exactly one compact JSON object per ticket with these exact fields:

- `ticket_id`, `subject`, `role`, `answer_pdf`, `pdf_page`, `page_file`, `source_pdf_sha256`, `page_sha256`: copy exactly from the ticket.
- `page_kind`: one of `solution`, `key`, `mixed`, `blank`.
- `printed_page_label`: visible printed page label with ASCII digits, or `null`.
- `numbered_items`: sorted unique array of global question numbers evidenced on that page. For `solution`, include blocks that begin there; for `key`, include every visible answer cell.
- `first_global_question` and `last_global_question`: first/last `numbered_items` value, otherwise `null`.
- `continues_from_previous`, `continues_to_next`: booleans for a solution block cut across the page edge; use `false` for ordinary key-table continuation between complete rows.
- `notes`: unique precise strings for crop, unreadable number/cell, duplicate heading, missing explanation, or other ambiguity; otherwise `[]`.

Fail closed. Never infer an answer option, never solve, never use neighboring pages to invent missing evidence, and never transcribe the solution in this indexing wave. Use ASCII JSON integers only.

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
    rendered: list[RenderedPage] = []
    page_roles: dict[tuple[str, int], str] = {}
    source_pdfs: list[dict[str, Any]] = []

    for subject, book in manifest["books"].items():
        pdf = sources[subject] / book["answer_pdf"]
        if not pdf.is_file():
            raise ValueError(f"missing answer PDF {pdf}")
        pdf_hash = sha256_file(pdf)
        reader = PdfReader(str(pdf), strict=False)
        solution_start, solution_end = book["solution_pages"]
        key_start, key_end = book["key_pages"]
        ranges = (("solution", solution_start, solution_end), ("key", key_start, key_end))
        source_pdfs.append(
            {
                "subject": subject,
                "answer_pdf": book["answer_pdf"],
                "source_pdf_sha256": pdf_hash,
                "pdf_page_count": len(reader.pages),
                "solution_pages": [solution_start, solution_end],
                "key_pages": [key_start, key_end],
            }
        )
        for role, first, last in ranges:
            if first < 1 or last > len(reader.pages) or first > last:
                raise ValueError(f"invalid {subject} {role} range {first}..{last}")
            topic = {
                "order": 1 if role == "solution" else 2,
                "key": role,
                "question_pdf": book["answer_pdf"],
            }
            for page_number in range(first, last + 1):
                page_roles[(subject, page_number)] = role
                item = render_page(
                    subject=subject,
                    topic=topic,
                    pdf=pdf,
                    pdf_hash=pdf_hash,
                    page_number=page_number,
                    page=reader.pages[page_number - 1],
                    max_width=args.max_image_width,
                    quality=args.jpeg_quality,
                )
                filename = (
                    f"{role.upper()}_{subject}_{Path(book['answer_pdf']).stem}_"
                    f"p{page_number:04d}.jpg"
                )
                rendered.append(
                    RenderedPage(
                        subject=item.subject,
                        topic_key=role,
                        topic_order=item.topic_order,
                        question_pdf=item.question_pdf,
                        pdf_page=item.pdf_page,
                        source_pdf_sha256=item.source_pdf_sha256,
                        filename=filename,
                        data=item.data,
                        page_sha256=item.page_sha256,
                        original_size=item.original_size,
                        rendered_size=item.rendered_size,
                    )
                )

    lanes = assign_lanes(
        segment_pages(rendered, args.segment_pages), args.lanes, args.max_upload_bytes
    )
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
        batch_id = f"answer-inventory-{args.wave:04d}-{lane_number:02d}"
        batch_dir = wave_dir / "batches" / batch_id
        image_dir = batch_dir / "images"
        image_dir.mkdir(parents=True)
        tickets: list[dict[str, Any]] = []
        attachments: list[dict[str, Any]] = []
        for page in pages:
            role = page_roles[(page.subject, page.pdf_page)]
            write_atomic(image_dir / page.filename, page.data)
            ticket = {
                "ticket_id": (
                    f"answer-page:{page.subject}:{role}:"
                    f"{Path(page.question_pdf).stem}:p{page.pdf_page:04d}:"
                    f"{page.page_sha256[:12]}"
                ),
                "subject": page.subject,
                "role": role,
                "answer_pdf": page.question_pdf,
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
        prompt = answer_prompt(batch_id, tickets)
        write_atomic(batch_dir / "prompt.md", prompt.encode("utf-8"))
        batch = {
            "schema_version": 1,
            "prompt_contract": "gauss-answer-inventory-v1",
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
        "prompt_contract": "gauss-answer-inventory-v1",
        "wave": args.wave,
        "lane_count": len(batches),
        "source_page_count": len(rendered),
        "source_pdfs": source_pdfs,
        "batches": batches,
        "immutable_sources_edited": False,
        "output_trust": "untrusted_answer_index_draft_until_local_validation",
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
                "source_pages": len(rendered),
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
        print(f"answer inventory preparation error: {error}")
        raise SystemExit(2)
