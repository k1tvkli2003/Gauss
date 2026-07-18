"""Render the approved Theorem Star icon into Android and web PNG variants.

The SVG masters are the source of truth. This utility needs a Chromium-based
browser plus Pillow, both already available on the Windows development setup.
"""

from __future__ import annotations

import argparse
import subprocess
import tempfile
from html import escape
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
MASTER_SIZE = 1024
BROWSER_CANDIDATES = (
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
)


def _browser() -> Path:
    for candidate in BROWSER_CANDIDATES:
        if candidate.exists():
            return candidate
    raise RuntimeError("Chrome or Microsoft Edge is required to rasterize the SVG masters.")


def _render_svg(svg: Path, destination: Path) -> Image.Image:
    # Chromium preserves an SVG's intrinsic 108px dimensions when navigating
    # directly to the file. Render it through a zero-margin HTML canvas so the
    # source artwork fills the intended raster size before downsampling.
    canvas = destination.with_suffix(".html")
    canvas.write_text(
        "<!doctype html><html><head><style>"
        "html,body,img{width:100%;height:100%;margin:0;overflow:hidden;}"
        "img{display:block;}"
        "</style></head><body>"
        f'<img src="{escape(svg.resolve().as_uri(), quote=True)}" alt="">'
        "</body></html>",
        encoding="utf-8",
    )
    command = [
        str(_browser()),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={MASTER_SIZE},{MASTER_SIZE}",
        f"--screenshot={destination}",
        canvas.resolve().as_uri(),
    ]
    try:
        subprocess.run(
            command,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    finally:
        canvas.unlink(missing_ok=True)
    image = Image.open(destination).convert("RGBA")
    if image.size != (MASTER_SIZE, MASTER_SIZE):
        raise RuntimeError(
            f"Unexpected SVG raster size {image.size}; expected {(MASTER_SIZE, MASTER_SIZE)}."
        )
    return image


def _save(image: Image.Image, destination: Path, size: int, *, circular: bool = False) -> None:
    output = image.resize((size, size), Image.Resampling.LANCZOS)
    if circular:
        alpha = Image.new("L", (size, size), 0)
        ImageDraw.Draw(alpha).ellipse((0, 0, size - 1, size - 1), fill=255)
        output.putalpha(alpha)
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, format="PNG", optimize=True)


def build() -> None:
    assets = ROOT / "assets" / "visual" / "brand"
    with tempfile.TemporaryDirectory(prefix="gauss-brand-icon-") as temp_dir:
        temp = Path(temp_dir)
        any_icon = _render_svg(assets / "theorem_star_app_icon.svg", temp / "any.png")
        maskable_icon = _render_svg(
            assets / "theorem_star_app_icon_maskable.svg", temp / "maskable.png"
        )

        web = ROOT / "web"
        _save(any_icon, web / "favicon.png", 96)
        for size in (192, 432, 512):
            _save(any_icon, web / "icons" / f"Icon-{size}.png", size)
        for size in (192, 512):
            _save(maskable_icon, web / "icons" / f"Icon-maskable-{size}.png", size)

        android = ROOT / "android" / "app" / "src" / "main" / "res"
        for density, size in {
            "mipmap-mdpi": 48,
            "mipmap-hdpi": 72,
            "mipmap-xhdpi": 96,
            "mipmap-xxhdpi": 144,
            "mipmap-xxxhdpi": 192,
        }.items():
            _save(any_icon, android / density / "ic_launcher.png", size)
            _save(any_icon, android / density / "ic_launcher_round.png", size, circular=True)
        _save(maskable_icon, android / "drawable-nodpi" / "ic_launcher_foreground.png", 432)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    build()
