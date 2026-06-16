"""Generate Random Decision square app logo (1024x1024, sharp corners)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "assets" / "logo.png"

PURPLE = (91, 33, 255)
VIOLET = (124, 58, 237)
CORAL = (255, 107, 107)
GOLD = (255, 217, 61)
WHITE = (255, 255, 255)
DEEP = (35, 18, 90)

WHEEL_COLORS = [
    (91, 133, 255),
    (255, 107, 107),
    (0, 184, 148),
    (255, 142, 83),
    (116, 185, 255),
    (255, 176, 32),
    (225, 112, 85),
    (129, 236, 236),
]


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def square_gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            tx = x / size
            ty = y / size
            t = tx * 0.45 + ty * 0.55
            r = lerp(DEEP[0], PURPLE[0], t * 0.7)
            g = lerp(DEEP[1], VIOLET[1], t * 0.55)
            b = lerp(DEEP[2], CORAL[2], t * 0.35)
            px[x, y] = (r, g, b)
    return img


def draw_wheel(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    count = len(WHEEL_COLORS)
    for i, color in enumerate(WHEEL_COLORS):
        start = i * 360 / count - 90
        end = start + 360 / count
        draw.pieslice(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            start=start,
            end=end,
            fill=color + (255,),
        )

    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        outline=WHITE + (220,),
        width=10,
    )
    draw.ellipse((cx - 78, cy - 78, cx + 78, cy + 78), fill=WHITE)
    draw.ellipse((cx - 78, cy - 78, cx + 78, cy + 78), outline=GOLD + (255,), width=6)


def draw_pointer(draw: ImageDraw.ImageDraw, cx: int, top: int) -> None:
    points = [(cx, top + 70), (cx - 42, top), (cx + 42, top)]
    draw.polygon(points, fill=GOLD)
    draw.polygon(points, outline=WHITE, width=4)


def draw_sparkle(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    points: list[tuple[float, float]] = []
    for i in range(10):
        angle = math.radians(-90 + i * 36)
        radius = r if i % 2 == 0 else r * 0.42
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(points, fill=WHITE + (210,))


def main() -> None:
    base = square_gradient(SIZE).convert("RGBA")
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    cx, cy = SIZE // 2, SIZE // 2 + 30
    draw_wheel(draw, cx, cy, 300)
    draw_pointer(draw, cx, cy - 300)

    draw_sparkle(draw, cx - 340, cy - 260, 34)
    draw_sparkle(draw, cx + 330, cy - 220, 28)
    draw_sparkle(draw, cx + 300, cy + 280, 24)

    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((cx - 260, cy - 260, cx + 260, cy + 260), fill=(255, 255, 255, 40))
    glow = glow.filter(ImageFilter.GaussianBlur(45))

    composed = Image.alpha_composite(base, glow)
    composed = Image.alpha_composite(composed, overlay)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    composed.convert("RGB").save(OUT, format="PNG", optimize=True)
    print(f"Saved Random Decision logo: {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
