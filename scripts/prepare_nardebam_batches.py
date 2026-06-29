#!/usr/bin/env python3
"""Render local Nardebam scans into small, isolated Jules task batches."""

from __future__ import annotations

import argparse
import io
import json
import math
import os
import shutil
from pathlib import Path

from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data" / "nardebam" / "topic_manifest.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--math-dir", type=Path)
    parser.add_argument("--physics-dir", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "tmp" / "jules_nardebam")
    parser.add_argument("--answer-chunk-size", type=int, default=20)
    parser.add_argument("--max-image-width", type=int, default=1800)
    parser.add_argument("--jpeg-quality", type=int, default=88)
    parser.add_argument("--tasks", help="Comma-separated task IDs; omit to render every task")
    return parser.parse_args()


def source_dirs(args: argparse.Namespace, manifest: dict) -> dict[str, Path]:
    explicit = {"math": args.math_dir, "physics": args.physics_dir}
    result: dict[str, Path] = {}
    for subject, book in manifest["books"].items():
        candidate = explicit[subject] or (Path(os.environ[book["source_env"]]) if os.environ.get(book["source_env"]) else None)
        if not candidate or not candidate.is_dir():
            raise SystemExit(f"Missing {subject} source directory. Pass --{subject}-dir or set {book['source_env']}.")
        result[subject] = candidate.resolve()
    return result


def largest_page_image(page) -> Image.Image:
    candidates: list[Image.Image] = []
    for embedded in page.images:
        try:
            candidates.append(Image.open(io.BytesIO(embedded.data)).convert("RGB"))
        except Exception:
            continue
    if not candidates:
        raise RuntimeError("PDF page has no extractable raster image")
    return max(candidates, key=lambda image: image.width * image.height)


def render_pages(pdf: Path, first: int, last: int, output: Path, max_width: int, quality: int) -> list[dict]:
    reader = PdfReader(str(pdf), strict=False)
    if first < 1 or last > len(reader.pages) or first > last:
        raise ValueError(f"Invalid page range {first}-{last} for {pdf} ({len(reader.pages)} pages)")
    output.mkdir(parents=True, exist_ok=True)
    pages: list[dict] = []
    for page_number in range(first, last + 1):
        image = largest_page_image(reader.pages[page_number - 1])
        original = [image.width, image.height]
        if image.width > max_width:
            height = round(image.height * max_width / image.width)
            image = image.resize((max_width, height), Image.Resampling.LANCZOS)
        name = f"page_{page_number:04d}.jpg"
        image.save(output / name, "JPEG", quality=quality, optimize=True, progressive=True)
        pages.append({"file": name, "pdf_page": page_number, "original_size": original, "rendered_size": [image.width, image.height]})
    return pages


def question_prompt(task: dict) -> str:
    return f"""# Jules visual extraction task: {task['id']}

Read every ordered JPEG under `jules_input/images/`. These are scans from the {task['subject']} topic
`{task['topic_label']}` (`{task['topic_key']}`). Extract every numbered four-option test. Ignore lesson prose,
worked examples without four choices, headers, footers, branding, and watermarks.

This is visual transcription, not creative generation:
- Preserve the printed question number exactly.
- Transcribe Persian text faithfully and convert mathematical notation to valid LaTeX wrapped in `$...$`.
- Return exactly four options in printed order. Do not solve or guess the answer in this wave.
- When a stem or option contains a meaningful diagram/photo/table, add a media region with the JPEG filename,
  integer pixel box `[left, top, right, bottom]`, placement (`stem` or `option_1`..`option_4`), and concise Persian alt text.
- Exclude page decoration and watermarks from media boxes whenever possible.
- Record the source PDF page from `jules_input/task.json`.
- If any character/formula is genuinely unreadable, preserve the record and add a precise `review_notes` entry.

Create only `jules_output/{task['id']}.json` as a JSON object:
`{{"task_id":"...","subject":"...","topic_key":"...","questions":[...]}}`.
Each question must contain `question_number`, `question_page`, `question_text`, `options` (four strings),
`media_regions` (array), and `review_notes` (array). Use UTF-8 JSON with no Markdown fence.
"""


def answer_prompt(task: dict) -> str:
    return f"""# Jules visual solution extraction task: {task['id']}

Read every ordered JPEG under `jules_input/images/`. They are consecutive pages from the {task['subject']}
Nardebam explanatory answer section. Extract every solution block visible in this range.

- Preserve each printed source question number exactly.
- Transcribe the complete Persian solution and mathematical notation; use `$...$` LaTeX.
- Extract an explicitly stated correct option only when visible; otherwise use null and never infer it.
- For meaningful solution figures, return pixel regions with page filename, box, Persian alt text, and placement `solution`.
- Ignore branding, headers, footers, watermarks, and advertisements.
- Add `review_notes` for cut-off blocks that continue outside this chunk.

Create only `jules_output/{task['id']}.json` containing `task_id`, `subject`, and `solutions`.
Each solution contains `question_number`, `solution_page`, `solution_text`, `stated_correct_option`,
`media_regions`, and `review_notes`. UTF-8 JSON only, no Markdown fence.
"""


def key_prompt(task: dict) -> str:
    return f"""# Jules authoritative answer-key extraction task: {task['id']}

Read all ordered JPEGs under `jules_input/images/`. They are the printed final answer-key tables for the
{task['subject']} book. Extract every mapping from question number to option 1..4.

- Read Persian digits carefully and preserve a continuous integer question number.
- Never infer a missing cell. Put uncertain cells in `review_notes` and omit them from `answers`.
- Check for duplicate numbers inside your own output.

Create only `jules_output/{task['id']}.json` with `task_id`, `subject`, `answers` as an object whose keys are
ASCII question-number strings and values are integers 1..4, plus `review_notes`. UTF-8 JSON only.
"""


def task_defs(manifest: dict, chunk_size: int) -> list[dict]:
    tasks: list[dict] = []
    for subject, book in manifest["books"].items():
        for topic in book["topics"]:
            tasks.append({
                "id": f"{subject}-topic-{topic['order']:02d}",
                "kind": "questions",
                "subject": subject,
                "topic_key": topic["key"],
                "topic_label": topic["label"],
                "pdf": topic["question_pdf"],
                "first_page": topic["first_content_page"],
            })
        start, end = book["solution_pages"]
        chunk_count = math.ceil((end - start + 1) / chunk_size)
        for index in range(chunk_count):
            first = start + index * chunk_size
            last = min(end, first + chunk_size - 1)
            tasks.append({
                "id": f"{subject}-solutions-{index + 1:02d}",
                "kind": "solutions",
                "subject": subject,
                "pdf": book["answer_pdf"],
                "first_page": first,
                "last_page": last,
            })
        key_first, key_last = book["key_pages"]
        tasks.append({
            "id": f"{subject}-answer-key",
            "kind": "answer_key",
            "subject": subject,
            "pdf": book["answer_pdf"],
            "first_page": key_first,
            "last_page": key_last,
        })
    return tasks


def main() -> None:
    args = parse_args()
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    sources = source_dirs(args, manifest)
    selected = set(args.tasks.split(",")) if args.tasks else None
    tasks = task_defs(manifest, args.answer_chunk_size)
    args.output.mkdir(parents=True, exist_ok=True)
    rendered_tasks: list[dict] = []

    for task in tasks:
        if selected is not None and task["id"] not in selected:
            continue
        task_dir = args.output / "tasks" / task["id"]
        if task_dir.exists():
            shutil.rmtree(task_dir)
        pdf = sources[task["subject"]] / task["pdf"]
        reader = PdfReader(str(pdf), strict=False)
        last_page = task.get("last_page", len(reader.pages))
        pages = render_pages(pdf, task["first_page"], last_page, task_dir / "images", args.max_image_width, args.jpeg_quality)
        resolved = {
            **task,
            "source_pdf": task["pdf"],
            "pages": pages,
            "branch": f"codex/nardebam-{task['id']}",
            "expected_output": f"jules_output/{task['id']}.json",
        }
        (task_dir / "task.json").write_text(json.dumps(resolved, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        prompt = question_prompt(resolved) if task["kind"] == "questions" else answer_prompt(resolved) if task["kind"] == "solutions" else key_prompt(resolved)
        (task_dir / "TASK.md").write_text(prompt, encoding="utf-8")
        rendered_tasks.append(resolved)
        print(f"prepared {task['id']}: {len(pages)} pages")

    manifest_out = {
        "schema_version": 1,
        "task_count": len(rendered_tasks),
        "tasks": rendered_tasks,
    }
    (args.output / "tasks.json").write_text(json.dumps(manifest_out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {args.output / 'tasks.json'}")


if __name__ == "__main__":
    main()
