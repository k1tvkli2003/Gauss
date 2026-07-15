#!/usr/bin/env python3
"""Generate an original Adventure map background asset for the Android app.

The output is procedural artwork inspired by the accepted preview composition.
It is not derived from, pasted from, or cropped out of the reference image.
"""

from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "app" / "src" / "main" / "res" / "drawable-nodpi" / "adventure_map_background.png"
SOURCE_ART = ROOT / "docs" / "adventure-generated-assets" / "map-island-art-2026-07-05-source.png"
W, H = 720, 1040


def write_generated_fullscreen_map() -> bool:
    if not SOURCE_ART.exists():
        return False

    image = Image.open(SOURCE_ART).convert("RGB")
    target_w, target_h = 720, 1560
    crop_w = round(image.height * (target_w / target_h))
    x0 = max(0, round((image.width - crop_w) / 2))
    crop = image.crop((x0, 0, x0 + crop_w, image.height))
    crop = crop.resize((target_w, target_h), Image.Resampling.LANCZOS)
    crop = ImageEnhance.Color(crop).enhance(1.04)
    crop = ImageEnhance.Contrast(crop).enhance(1.02)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    crop.save(OUT, optimize=True)
    print(f"Wrote {OUT} from {SOURCE_ART}")
    return True


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient(size: tuple[int, int], stops: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    image = Image.new("RGB", size)
    draw = ImageDraw.Draw(image)
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        left = stops[0]
        right = stops[-1]
        for idx in range(len(stops) - 1):
            if stops[idx][0] <= t <= stops[idx + 1][0]:
                left = stops[idx]
                right = stops[idx + 1]
                break
        local = 0 if right[0] == left[0] else (t - left[0]) / (right[0] - left[0])
        color = tuple(lerp(left[1][channel], right[1][channel], local) for channel in range(3))
        draw.line((0, y, size[0], y), fill=color)
    return image


def ellipse(draw: ImageDraw.ImageDraw, cx: float, cy: float, rx: float, ry: float, fill: tuple[int, int, int, int]) -> None:
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=fill)


def round_rect(draw: ImageDraw.ImageDraw, box: tuple[float, float, float, float], radius: float, fill: tuple[int, int, int, int]) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def draw_cloud(layer: Image.Image, cx: float, cy: float, scale: float, alpha: int = 120) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    color = (234, 247, 249, alpha)
    ellipse(draw, cx - 70 * scale, cy + 4 * scale, 74 * scale, 28 * scale, color)
    ellipse(draw, cx - 15 * scale, cy - 16 * scale, 62 * scale, 36 * scale, color)
    ellipse(draw, cx + 55 * scale, cy + 1 * scale, 76 * scale, 30 * scale, color)
    ellipse(draw, cx + 6 * scale, cy + 18 * scale, 104 * scale, 24 * scale, (195, 228, 233, alpha // 2))


def draw_island(layer: Image.Image, cx: float, cy: float, rx: float, ry: float, top: tuple[int, int, int], side: tuple[int, int, int]) -> None:
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow, "RGBA")
    ellipse(shadow_draw, cx, cy + ry * .72, rx * 1.12, ry * .32, (0, 0, 0, 92))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))

    draw = ImageDraw.Draw(layer, "RGBA")
    base = [
        (cx - rx * .82, cy + ry * .05),
        (cx - rx * .45, cy + ry * .74),
        (cx, cy + ry * 1.10),
        (cx + rx * .45, cy + ry * .74),
        (cx + rx * .82, cy + ry * .05),
    ]
    draw.polygon(base, fill=(*side, 230))
    ellipse(draw, cx, cy - ry * .08, rx, ry * .52, (*top, 238))
    ellipse(draw, cx - rx * .22, cy - ry * .22, rx * .48, ry * .18, (240, 255, 226, 52))
    draw.arc((cx - rx * .78, cy - ry * .43, cx + rx * .78, cy + ry * .40), 200, 340, fill=(255, 246, 188, 70), width=3)


def draw_castle(layer: Image.Image, cx: float, cy: float, scale: float) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    body = (95, 61, 164, 238)
    shade = (48, 32, 86, 242)
    for dx, h in [(-42, 78), (0, 96), (42, 78)]:
        round_rect(draw, (cx + dx - 18 * scale, cy - h * scale, cx + dx + 18 * scale, cy + 10 * scale), 8 * scale, body)
        draw.polygon(
            [
                (cx + dx - 24 * scale, cy - h * scale),
                (cx + dx, cy - (h + 32) * scale),
                (cx + dx + 24 * scale, cy - h * scale),
            ],
            fill=(164, 110, 240, 245),
        )
    round_rect(draw, (cx - 56 * scale, cy - 40 * scale, cx + 56 * scale, cy + 22 * scale), 12 * scale, body)
    round_rect(draw, (cx - 16 * scale, cy - 8 * scale, cx + 16 * scale, cy + 22 * scale), 11 * scale, shade)
    ellipse(draw, cx, cy + 28 * scale, 72 * scale, 12 * scale, (23, 18, 44, 130))


def draw_chest(layer: Image.Image, cx: float, cy: float, scale: float) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    round_rect(draw, (cx - 48 * scale, cy - 24 * scale, cx + 48 * scale, cy + 36 * scale), 12 * scale, (112, 64, 23, 240))
    round_rect(draw, (cx - 48 * scale, cy - 32 * scale, cx + 48 * scale, cy + 4 * scale), 12 * scale, (236, 162, 33, 245))
    draw.rectangle((cx - 7 * scale, cy - 28 * scale, cx + 7 * scale, cy + 34 * scale), fill=(255, 224, 112, 245))
    draw.rectangle((cx - 48 * scale, cy + 1 * scale, cx + 48 * scale, cy + 7 * scale), fill=(70, 39, 18, 230))
    round_rect(draw, (cx - 12 * scale, cy - 2 * scale, cx + 12 * scale, cy + 20 * scale), 5 * scale, (252, 234, 158, 245))


def draw_crystals(layer: Image.Image, cx: float, cy: float, scale: float) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    colors = [(174, 88, 238, 238), (111, 72, 205, 238), (212, 126, 255, 238)]
    for idx, dx in enumerate([-46, -16, 20, 52]):
        height = [78, 112, 96, 72][idx] * scale
        width = [24, 34, 30, 22][idx] * scale
        draw.polygon(
            [
                (cx + dx * scale, cy - height),
                (cx + dx * scale - width, cy + 12 * scale),
                (cx + dx * scale + width, cy + 16 * scale),
            ],
            fill=colors[idx % len(colors)],
        )
        draw.line((cx + dx * scale, cy - height, cx + dx * scale, cy + 12 * scale), fill=(255, 231, 255, 90), width=max(2, round(3 * scale)))


def draw_workshop(layer: Image.Image, cx: float, cy: float, scale: float) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    round_rect(draw, (cx - 50 * scale, cy - 28 * scale, cx + 50 * scale, cy + 36 * scale), 10 * scale, (49, 99, 123, 242))
    draw.polygon(
        [(cx - 58 * scale, cy - 28 * scale), (cx, cy - 64 * scale), (cx + 58 * scale, cy - 28 * scale)],
        fill=(76, 137, 168, 242),
    )
    for dx in [-24, 20]:
        round_rect(draw, (cx + dx * scale - 12 * scale, cy - 8 * scale, cx + dx * scale + 12 * scale, cy + 16 * scale), 5 * scale, (161, 222, 238, 214))


def draw_lock(layer: Image.Image, cx: float, cy: float, scale: float) -> None:
    draw = ImageDraw.Draw(layer, "RGBA")
    round_rect(draw, (cx - 42 * scale, cy - 4 * scale, cx + 42 * scale, cy + 56 * scale), 18 * scale, (55, 65, 72, 232))
    draw.arc((cx - 28 * scale, cy - 48 * scale, cx + 28 * scale, cy + 16 * scale), 190, 350, fill=(160, 175, 180, 220), width=max(5, round(8 * scale)))
    ellipse(draw, cx, cy + 24 * scale, 9 * scale, 9 * scale, (225, 236, 238, 230))


def draw_path(layer: Image.Image, points: list[tuple[float, float]]) -> None:
    route = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(route, "RGBA")
    for start, end in zip(points, points[1:]):
        draw.line((*start, *end), fill=(103, 75, 17, 140), width=22)
        draw.line((*start, *end), fill=(250, 236, 185, 220), width=9)
        steps = 11
        for step in range(1, steps):
            t = step / steps
            x = start[0] + (end[0] - start[0]) * t
            y = start[1] + (end[1] - start[1]) * t
            ellipse(draw, x, y, 9, 9, (255, 193, 56, 245))
            ellipse(draw, x - 2, y - 2, 3, 3, (255, 248, 204, 245))
    layer.alpha_composite(route.filter(ImageFilter.GaussianBlur(.35)))


def draw_sparkles(layer: Image.Image) -> None:
    rnd = Random(18)
    draw = ImageDraw.Draw(layer, "RGBA")
    for _ in range(95):
        x = rnd.randrange(14, W - 14)
        y = rnd.randrange(18, H - 16)
        r = rnd.choice([2, 2, 3, 4])
        color = rnd.choice([(255, 206, 65, 118), (119, 214, 234, 112), (154, 105, 240, 115), (255, 255, 255, 78)])
        if rnd.random() < .18:
            draw.line((x - r * 2, y, x + r * 2, y), fill=color, width=max(1, r // 2))
            draw.line((x, y - r * 2, x, y + r * 2), fill=color, width=max(1, r // 2))
        else:
            ellipse(draw, x, y, r, r, color)


def main() -> None:
    if write_generated_fullscreen_map():
        return

    bg = gradient(
        (W, H),
        [
            (0.0, (7, 29, 48)),
            (0.18, (13, 68, 89)),
            (0.50, (19, 112, 119)),
            (0.75, (12, 74, 81)),
            (1.0, (4, 31, 46)),
        ],
    ).convert("RGBA")
    soft = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_cloud(soft, 8, 196, 1.24, 158)
    draw_cloud(soft, 690, 214, .74, 92)
    draw_cloud(soft, 86, 585, .62, 64)
    bg.alpha_composite(soft.filter(ImageFilter.GaussianBlur(1.5)))

    islands = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_island(islands, 198, 270, 132, 92, (102, 80, 139), (53, 44, 86))
    draw_island(islands, 560, 312, 130, 82, (111, 151, 74), (43, 74, 49))
    draw_island(islands, 144, 528, 116, 78, (113, 74, 158), (55, 46, 94))
    draw_island(islands, 354, 744, 126, 82, (102, 172, 88), (48, 91, 56))
    draw_island(islands, 132, 842, 114, 72, (157, 140, 85), (89, 74, 48))
    draw_island(islands, 594, 836, 122, 76, (62, 74, 78), (34, 43, 48))
    bg.alpha_composite(islands)

    path = [
        (132, 842),
        (354, 744),
        (144, 528),
        (560, 312),
        (198, 270),
    ]
    draw_path(bg, path)

    details = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_castle(details, 198, 238, .86)
    draw_chest(details, 560, 268, .86)
    draw_crystals(details, 144, 492, .72)
    draw_workshop(details, 594, 784, .72)
    draw_chest(details, 132, 807, .70)
    draw_lock(details, 594, 806, .70)
    draw_sparkles(details)

    water = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    water_draw = ImageDraw.Draw(water, "RGBA")
    water_draw.line((594, 334, 588, 410, 572, 478), fill=(111, 216, 232, 112), width=22)
    water_draw.line((598, 338, 592, 412, 576, 476), fill=(222, 255, 255, 92), width=7)
    bg.alpha_composite(water.filter(ImageFilter.GaussianBlur(1.2)))
    bg.alpha_composite(details)

    vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette, "RGBA")
    for step in range(18):
        alpha = int((step / 18) ** 2 * 34)
        vignette_draw.rectangle((step, step, W - step, H - step), outline=(0, 13, 22, alpha), width=1)
    bg.alpha_composite(vignette)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(OUT, optimize=True)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
