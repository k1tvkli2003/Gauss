#!/usr/bin/env python3
"""Crop Jules-reviewed media regions and attach them to v2 content blocks."""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, default=ROOT / "data" / "seed" / "comprehensive" / "nardebam")
    parser.add_argument("--tasks-root", type=Path, default=ROOT / "tmp" / "jules_nardebam")
    parser.add_argument("--assets", type=Path, default=ROOT / "app" / "src" / "main" / "assets" / "question_media")
    parser.add_argument("--contact-sheets", type=Path, default=ROOT / "tmp" / "nardebam_contact_sheets")
    return parser.parse_args()


def region_pixels(region: dict, width: int, height: int) -> tuple[int, int, int, int]:
    values = [float(value) for value in region["box"]]
    if region.get("box_format") == "yxyx":
        top, left, bottom, right = values
    else:
        left, top, right, bottom = values
    maximum = max(abs(value) for value in values)
    if maximum <= 1.01:
        left, right = left * width, right * width
        top, bottom = top * height, bottom * height
    elif maximum <= 1000 and width > 1000:
        left, right = left / 1000 * width, right / 1000 * width
        top, bottom = top / 1000 * height, bottom / 1000 * height
    padding = max(8, round(min(width, height) * 0.008))
    return (
        max(0, math.floor(min(left, right)) - padding),
        max(0, math.floor(min(top, bottom)) - padding),
        min(width, math.ceil(max(left, right)) + padding),
        min(height, math.ceil(max(top, bottom)) + padding),
    )


def task_images(tasks_root: Path, subject: str, topic_order: int) -> Path:
    return tasks_root / "tasks" / f"{subject}-topic-{topic_order:02d}" / "images"


def make_contact_sheet(images: list[tuple[str, Path]], output: Path) -> None:
    if not images:
        return
    thumb_w, thumb_h = 300, 240
    columns = 4
    rows = math.ceil(len(images) / columns)
    sheet = Image.new("RGB", (columns * thumb_w, rows * thumb_h), "#e8ecea")
    draw = ImageDraw.Draw(sheet)
    for index, (label, file) in enumerate(images):
        image = Image.open(file).convert("RGB")
        image.thumbnail((thumb_w - 16, thumb_h - 34))
        x = index % columns * thumb_w + (thumb_w - image.width) // 2
        y = index // columns * thumb_h + 26
        sheet.paste(image, (x, y))
        draw.text((index % columns * thumb_w + 8, index // columns * thumb_h + 6), label, fill="black")
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=90)


def main() -> None:
    args = parse_args()
    manifest = json.loads((ROOT / "data" / "nardebam" / "topic_manifest.json").read_text(encoding="utf-8"))
    topic_order = {
        (subject, topic["key"]): topic["order"]
        for subject, book in manifest["books"].items()
        for topic in book["topics"]
    }
    if args.assets.exists():
        shutil.rmtree(args.assets)
    args.assets.mkdir(parents=True)
    contact: dict[str, list[tuple[str, Path]]] = {}
    errors: list[dict] = []

    for file in args.dataset.rglob("*.json"):
        rows = json.loads(file.read_text(encoding="utf-8"))
        if not isinstance(rows, list):
            continue
        changed = False
        for question in rows:
            generated_prefix = f"question_media/{question['subject']}/{question['id']}/"

            def without_generated(blocks: list[dict]) -> list[dict]:
                return [
                    block
                    for block in blocks
                    if not (
                        block.get("type") == "image"
                        and str(block.get("asset", "")).startswith(generated_prefix)
                    )
                ]

            question["stem"] = without_generated(question.get("stem", []))
            question["solution"] = without_generated(question.get("solution", []))
            question["options"] = [without_generated(option) for option in question.get("options", [])]
            groups = question.get("_media_regions", {})
            entries = [
                *((region, False) for region in (groups.get("question") or [])),
                *((region, True) for region in (groups.get("solution") or [])),
            ]
            if entries:
                changed = True
            for media_index, (region, solution_group) in enumerate(entries, start=1):
                placement = region.get("placement", "stem")
                is_solution = solution_group or placement.startswith("solution")
                page = question["provenance"]["solution_page"] if is_solution else question["provenance"]["question_page"]
                page_file = region.get("page_file")
                if page_file:
                    match = re.search(r"(page_\d+\.(?:jpg|jpeg|png|webp))$", str(page_file), re.IGNORECASE)
                    if match:
                        page_file = match.group(1)
                if not page_file and page:
                    page_file = f"page_{int(page):04d}.jpg"
                task_id = (
                    next((candidate.stem for candidate in args.tasks_root.joinpath("tasks").glob(f"{question['subject']}-solutions-*")
                          if page_file and candidate.joinpath("images", page_file).exists()), None)
                    if is_solution
                    else f"{question['subject']}-topic-{topic_order[(question['subject'], question['topic_key'])]:02d}"
                )
                if not page_file or not task_id:
                    errors.append({"id": question["id"], "issue": "missing_page_reference", "placement": placement})
                    continue
                source = args.tasks_root / "tasks" / str(task_id) / "images" / page_file
                if not source.exists():
                    errors.append({"id": question["id"], "issue": "missing_source_image", "source": str(source)})
                    continue
                image = Image.open(source).convert("RGB")
                box = region_pixels(region, image.width, image.height)
                if box[2] - box[0] < 20 or box[3] - box[1] < 20:
                    errors.append({"id": question["id"], "issue": "tiny_media_box", "box": box})
                    continue
                crop = image.crop(box)
                target_dir = args.assets / question["subject"] / question["id"]
                target_dir.mkdir(parents=True, exist_ok=True)
                target = target_dir / f"{placement}_{media_index}.webp"
                crop.save(target, "WEBP", quality=92, method=6)
                try:
                    asset = target.relative_to(ROOT / "app" / "src" / "main" / "assets").as_posix()
                except ValueError:
                    asset = (Path("question_media") / target.relative_to(args.assets)).as_posix()
                block = {"type": "image", "asset": asset, "alt": region.get("alt", "شکل سؤال"), "aspect_ratio": round(crop.width / crop.height, 4)}
                if placement.startswith("option_"):
                    option = int(placement.split("_")[1]) - 1
                    question["options"][option].append(block)
                elif is_solution:
                    question["solution"].append(block)
                else:
                    question["stem"].append(block)
                contact.setdefault(f"{question['subject']}_{question['topic_key']}", []).append((question["id"], target))
                changed = True
        if changed:
            file.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    for key, images in contact.items():
        make_contact_sheet(images, args.contact_sheets / f"{key}.jpg")
    report = args.contact_sheets / "media_errors.json"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(errors, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Cropped {sum(len(value) for value in contact.values())} media asset(s); {len(errors)} issue(s).")


if __name__ == "__main__":
    main()
