#!/usr/bin/env python3
"""Compare rendered Adventure screenshots against the accepted preview oracle."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[1]
MEASUREMENTS_PATH = ROOT / "docs" / "adventure-reference-measurements.json"


def load_oracle() -> dict[str, Any]:
    return json.loads(MEASUREMENTS_PATH.read_text(encoding="utf-8"))


def frame_by_id(oracle: dict[str, Any], screen_id: str) -> dict[str, Any]:
    for frame in oracle["frames"]:
        if frame["id"] == screen_id:
            return frame
    raise KeyError(f"Unknown screen id: {screen_id}")


def load_rgb(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGB")


def abs_error(reference: Image.Image, rendered: Image.Image) -> Image.Image:
    if rendered.size != reference.size:
        rendered = rendered.resize(reference.size, Image.Resampling.LANCZOS)
    return ImageChops.difference(reference, rendered)


def normalized_to_px(region: dict[str, Any], image: Image.Image) -> tuple[int, int, int, int]:
    frame = region["normalizedFrame"]
    left = round(frame["x"] * image.width)
    top = round(frame["y"] * image.height)
    right = round((frame["x"] + frame["width"]) * image.width)
    bottom = round((frame["y"] + frame["height"]) * image.height)
    return (
        max(0, min(image.width - 1, left)),
        max(0, min(image.height - 1, top)),
        max(1, min(image.width, right)),
        max(1, min(image.height, bottom)),
    )


def resized_like(reference: Image.Image, rendered: Image.Image) -> Image.Image:
    if rendered.size == reference.size:
        return rendered
    return rendered.resize(reference.size, Image.Resampling.LANCZOS)


def p95_channel_error(diff: Image.Image) -> int:
    values = []
    for channel in diff.split():
        histogram = channel.histogram()
        total = sum(histogram)
        threshold = total * 0.95
        seen = 0
        for value, count in enumerate(histogram):
            seen += count
            if seen >= threshold:
                values.append(value)
                break
    return max(values) if values else 0


def metrics(reference: Image.Image, rendered: Image.Image) -> dict[str, Any]:
    rendered_for_diff = resized_like(reference, rendered)
    diff = ImageChops.difference(reference, rendered_for_diff)
    stat = ImageStat.Stat(diff)
    per_channel_mae = stat.mean
    per_channel_rms = stat.rms
    mae = sum(per_channel_mae) / len(per_channel_mae)
    rmse = math.sqrt(sum(value * value for value in per_channel_rms) / len(per_channel_rms))
    return {
        "referenceSize": {"width": reference.width, "height": reference.height},
        "renderedInputSize": {"width": rendered.width, "height": rendered.height},
        "meanAbsoluteChannelError": round(mae, 3),
        "rootMeanSquareChannelError": round(rmse, 3),
        "p95ChannelError": p95_channel_error(diff),
    }


def region_metrics(frame: dict[str, Any], reference: Image.Image, rendered: Image.Image) -> list[dict[str, Any]]:
    normalized_rendered = resized_like(reference, rendered)
    rows: list[dict[str, Any]] = []
    for region in frame.get("regions", []):
        box = normalized_to_px(region, reference)
        reference_crop = reference.crop(box)
        rendered_crop = normalized_rendered.crop(box)
        rows.append(
            {
                "id": region["id"],
                "role": region["role"],
                "boxPx": {"x": box[0], "y": box[1], "width": box[2] - box[0], "height": box[3] - box[1]},
                **metrics(reference_crop, rendered_crop),
            }
        )
    return rows


def compare_screen(screen_id: str, rendered_path: Path) -> dict[str, Any]:
    oracle = load_oracle()
    frame = frame_by_id(oracle, screen_id)
    reference_path = ROOT / frame["cropPath"]
    reference = load_rgb(reference_path)
    rendered = load_rgb(rendered_path)
    return {
        "screen": screen_id,
        "reference": str(reference_path.relative_to(ROOT)).replace("\\", "/"),
        "rendered": str(rendered_path),
        **metrics(reference, rendered),
        "regions": region_metrics(frame, reference, rendered),
    }


def self_test() -> None:
    oracle = load_oracle()
    failures: list[str] = []
    for frame in oracle["frames"]:
        reference = ROOT / frame["cropPath"]
        result = compare_screen(frame["id"], reference)
        if result["meanAbsoluteChannelError"] != 0:
            failures.append(f"{frame['id']} self compare expected MAE 0, got {result['meanAbsoluteChannelError']}")
        bad_regions = [region for region in result["regions"] if region["meanAbsoluteChannelError"] != 0]
        if bad_regions:
            failures.append(f"{frame['id']} region self compare expected MAE 0, got {bad_regions}")

    map_reference = load_rgb(ROOT / frame_by_id(oracle, "map")["cropPath"])
    arena_reference = load_rgb(ROOT / frame_by_id(oracle, "arena")["cropPath"])
    cross = metrics(map_reference, arena_reference)
    if cross["meanAbsoluteChannelError"] < 8:
        failures.append("Cross-screen sanity check was unexpectedly similar.")

    if failures:
        raise AssertionError("\n".join(failures))
    print("Adventure visual oracle comparison self-test passed.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="verify the comparer using reference crops")
    parser.add_argument("--screen", choices=["map", "arena", "reward", "profile"], help="screen id to compare")
    parser.add_argument("--rendered", type=Path, help="rendered screenshot path")
    parser.add_argument("--threshold-mae", type=float, default=None, help="optional failing threshold for mean absolute channel error")
    parser.add_argument("--json", action="store_true", help="print machine-readable JSON")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    if not args.screen or not args.rendered:
        parser.error("--screen and --rendered are required unless --self-test is used")

    result = compare_screen(args.screen, args.rendered)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(
            f"{result['screen']}: MAE={result['meanAbsoluteChannelError']} "
            f"RMSE={result['rootMeanSquareChannelError']} "
            f"p95={result['p95ChannelError']}"
        )

    if args.threshold_mae is not None and result["meanAbsoluteChannelError"] > args.threshold_mae:
        raise SystemExit(f"MAE {result['meanAbsoluteChannelError']} exceeds threshold {args.threshold_mae}")


if __name__ == "__main__":
    main()
