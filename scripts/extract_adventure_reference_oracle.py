#!/usr/bin/env python3
"""Build and verify the Adventure preview reference oracle.

The oracle is documentation/test evidence only. It intentionally writes under
docs/ so the Android APK never depends on the accepted preview image.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "adventure-reference-manifest.json"
MEASUREMENTS_PATH = ROOT / "docs" / "adventure-reference-measurements.json"
CROP_DIR = ROOT / "docs" / "adventure-reference-crops"

REGIONS: dict[str, list[dict[str, Any]]] = {
    "map": [
        {"id": "status_bar", "role": "safe-area/time/system", "x": 0.00, "y": 0.00, "w": 1.00, "h": 0.055},
        {"id": "level_hud", "role": "level/xp/focus header", "x": 0.03, "y": 0.055, "w": 0.94, "h": 0.085},
        {"id": "metrics_row", "role": "focus and streak metrics", "x": 0.03, "y": 0.145, "w": 0.94, "h": 0.070},
        {"id": "map_stage", "role": "floating-island progression map", "x": 0.03, "y": 0.220, "w": 0.94, "h": 0.620},
        {"id": "primary_cta", "role": "current mission start button", "x": 0.38, "y": 0.560, "w": 0.31, "h": 0.070},
        {"id": "daily_quest", "role": "daily quest dock", "x": 0.03, "y": 0.855, "w": 0.94, "h": 0.070},
        {"id": "bottom_nav", "role": "four-tab bottom navigation", "x": 0.00, "y": 0.925, "w": 1.00, "h": 0.075},
    ],
    "arena": [
        {"id": "status_bar", "role": "safe-area/time/system", "x": 0.00, "y": 0.00, "w": 1.00, "h": 0.055},
        {"id": "title_header", "role": "back/title/settings", "x": 0.03, "y": 0.055, "w": 0.94, "h": 0.070},
        {"id": "progress_focus", "role": "question progress/focus/timer", "x": 0.03, "y": 0.125, "w": 0.94, "h": 0.065},
        {"id": "combo_coach", "role": "combo ribbon and mascot coach", "x": 0.06, "y": 0.190, "w": 0.88, "h": 0.120},
        {"id": "question_card", "role": "RTL question content card", "x": 0.03, "y": 0.285, "w": 0.94, "h": 0.215},
        {"id": "trap_hint", "role": "trap hint/info rail", "x": 0.03, "y": 0.520, "w": 0.94, "h": 0.055},
        {"id": "answer_grid", "role": "2x2 answer options", "x": 0.03, "y": 0.595, "w": 0.94, "h": 0.255},
        {"id": "action_row", "role": "scratchpad and check answer", "x": 0.03, "y": 0.875, "w": 0.94, "h": 0.075},
    ],
    "reward": [
        {"id": "status_bar", "role": "safe-area/time/system", "x": 0.00, "y": 0.00, "w": 1.00, "h": 0.055},
        {"id": "vault_hero", "role": "mission complete mascot/vault hero", "x": 0.03, "y": 0.060, "w": 0.94, "h": 0.325},
        {"id": "xp_panel", "role": "XP earned and stat trio", "x": 0.03, "y": 0.395, "w": 0.94, "h": 0.175},
        {"id": "daily_quest", "role": "completed daily quest row", "x": 0.03, "y": 0.585, "w": 0.94, "h": 0.080},
        {"id": "found_panel", "role": "coins gems gear rewards", "x": 0.03, "y": 0.675, "w": 0.94, "h": 0.155},
        {"id": "claim_cta", "role": "claim rewards primary action", "x": 0.03, "y": 0.845, "w": 0.94, "h": 0.060},
        {"id": "back_cta", "role": "back to map secondary action", "x": 0.03, "y": 0.920, "w": 0.94, "h": 0.060},
    ],
    "profile": [
        {"id": "status_bar", "role": "safe-area/time/system", "x": 0.00, "y": 0.00, "w": 1.00, "h": 0.055},
        {"id": "title_header", "role": "profile title/settings", "x": 0.03, "y": 0.055, "w": 0.94, "h": 0.055},
        {"id": "profile_header", "role": "mascot/level/league header", "x": 0.03, "y": 0.105, "w": 0.94, "h": 0.130},
        {"id": "tabs", "role": "mastery/stats/badges/league tabs", "x": 0.03, "y": 0.245, "w": 0.94, "h": 0.045},
        {"id": "brain_map", "role": "brain mastery panel", "x": 0.03, "y": 0.300, "w": 0.94, "h": 0.210},
        {"id": "weak_revenge", "role": "weak topics and revenge queue", "x": 0.03, "y": 0.520, "w": 0.94, "h": 0.170},
        {"id": "badges_shop", "role": "badge wall and cosmetics shop", "x": 0.03, "y": 0.700, "w": 0.94, "h": 0.170},
        {"id": "offline_nav", "role": "offline panel and bottom navigation", "x": 0.00, "y": 0.875, "w": 1.00, "h": 0.125},
    ],
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def load_manifest() -> dict[str, Any]:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def dominant_palette(image: Image.Image, color_count: int = 8) -> list[str]:
    tiny = image.convert("RGB").resize((96, 96))
    quantized = tiny.quantize(colors=color_count, method=Image.Quantize.MEDIANCUT)
    palette = quantized.getpalette() or []
    if hasattr(quantized, "get_flattened_data"):
        pixels = quantized.get_flattened_data()
    else:
        pixels = quantized.getdata()
    counts = Counter(pixels)
    colors: list[str] = []
    for index, _count in counts.most_common(color_count):
        offset = index * 3
        rgb = tuple(palette[offset : offset + 3])
        colors.append("#%02X%02X%02X" % rgb)
    return colors


def average_hex(image: Image.Image) -> str:
    stat = ImageStat.Stat(image.convert("RGB"))
    channels = [int(round(value)) for value in stat.mean]
    return "#%02X%02X%02X" % tuple(channels)


def crop_box(frame: dict[str, int], region: dict[str, Any] | None = None) -> tuple[int, int, int, int]:
    if region is None:
        return (
            frame["x"],
            frame["y"],
            frame["x"] + frame["width"],
            frame["y"] + frame["height"],
        )
    x = frame["x"] + round(frame["width"] * region["x"])
    y = frame["y"] + round(frame["height"] * region["y"])
    width = round(frame["width"] * region["w"])
    height = round(frame["height"] * region["h"])
    return (x, y, x + width, y + height)


def build_oracle(write: bool) -> dict[str, Any]:
    manifest = load_manifest()
    reference = manifest["reference"]
    reference_path = Path(reference["path"])
    if not reference_path.exists():
        raise FileNotFoundError(f"Reference image not found: {reference_path}")

    actual_hash = sha256(reference_path)
    if actual_hash != reference["sha256"]:
        raise ValueError(f"Reference hash mismatch: expected {reference['sha256']}, got {actual_hash}")

    source_image = Image.open(reference_path).convert("RGB")
    if source_image.size != (reference["widthPx"], reference["heightPx"]):
        raise ValueError(f"Reference size mismatch: expected {(reference['widthPx'], reference['heightPx'])}, got {source_image.size}")

    if write:
        CROP_DIR.mkdir(parents=True, exist_ok=True)

    frames: list[dict[str, Any]] = []
    for item in manifest["phoneFrames"]:
        frame = item["pixelFrame"]
        screen_id = item["id"]
        crop = source_image.crop(crop_box(frame))
        crop_name = f"adventure-reference-{screen_id}.png"
        crop_path = CROP_DIR / crop_name
        if write:
            crop.save(crop_path, optimize=True)

        regions: list[dict[str, Any]] = []
        for region in REGIONS[screen_id]:
            box = crop_box(frame, region)
            region_crop = source_image.crop(box)
            regions.append(
                {
                    "id": region["id"],
                    "role": region["role"],
                    "normalizedFrame": {
                        "x": region["x"],
                        "y": region["y"],
                        "width": region["w"],
                        "height": region["h"],
                    },
                    "sourceFramePx": {
                        "x": box[0],
                        "y": box[1],
                        "width": box[2] - box[0],
                        "height": box[3] - box[1],
                    },
                    "meanColor": average_hex(region_crop),
                    "palette": dominant_palette(region_crop, color_count=5),
                }
            )

        frames.append(
            {
                "id": screen_id,
                "title": item["title"],
                "canonicalScreen": item["canonicalScreen"],
                "route": item["route"],
                "sourceFramePx": frame,
                "cropPath": str(crop_path.relative_to(ROOT)).replace("\\", "/"),
                "cropSha256": sha256(crop_path) if crop_path.exists() else None,
                "meanColor": average_hex(crop),
                "palette": dominant_palette(crop),
                "regions": regions,
            }
        )

    oracle = {
        "version": 1,
        "generatedBy": "scripts/extract_adventure_reference_oracle.py",
        "sourceManifest": str(MANIFEST_PATH.relative_to(ROOT)).replace("\\", "/"),
        "sourceImage": {
            "path": reference["path"],
            "sha256": actual_hash,
            "widthPx": source_image.width,
            "heightPx": source_image.height,
        },
        "notes": [
            "Reference crops are documentation/test oracles only, not production Android resources.",
            "Region boxes are approximate acceptance anchors for hierarchy, color, and layout matching.",
            "Use rendered screenshots for final visual parity; this oracle only defines the target evidence.",
        ],
        "frames": frames,
    }

    if write:
        MEASUREMENTS_PATH.write_text(json.dumps(oracle, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return oracle


def check_oracle() -> None:
    expected = build_oracle(write=False)
    if not MEASUREMENTS_PATH.exists():
        raise FileNotFoundError(f"Missing measurements file: {MEASUREMENTS_PATH}")

    existing = json.loads(MEASUREMENTS_PATH.read_text(encoding="utf-8"))
    if existing["sourceImage"] != expected["sourceImage"]:
        raise ValueError("Measurements source image metadata is stale.")
    if len(existing.get("frames", [])) != 4:
        raise ValueError("Measurements must contain four phone frames.")

    for expected_frame in expected["frames"]:
        crop_path = ROOT / expected_frame["cropPath"]
        if not crop_path.exists():
            raise FileNotFoundError(f"Missing reference crop: {crop_path}")
        actual = Image.open(crop_path)
        frame = expected_frame["sourceFramePx"]
        if actual.size != (frame["width"], frame["height"]):
            raise ValueError(f"Crop size mismatch for {expected_frame['id']}: {actual.size}")
        if expected_frame["cropSha256"] and sha256(crop_path) != expected_frame["cropSha256"]:
            raise ValueError(f"Crop hash mismatch for {expected_frame['id']}.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="write crops and measurements")
    parser.add_argument("--check", action="store_true", help="verify generated crops and measurements")
    args = parser.parse_args()

    if args.write == args.check:
        parser.error("choose exactly one of --write or --check")
    if args.write:
        oracle = build_oracle(write=True)
        print(f"Wrote {len(oracle['frames'])} reference crops to {CROP_DIR.relative_to(ROOT)}")
        print(f"Wrote measurements to {MEASUREMENTS_PATH.relative_to(ROOT)}")
    else:
        check_oracle()
        print("Adventure reference oracle passed.")


if __name__ == "__main__":
    main()
