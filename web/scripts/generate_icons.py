#!/usr/bin/env python3
"""
Generates PWA icons (standard and maskable) and SVG icon for Contrast Checker Web / Chromebook PWA.
Matches the target reticle design (#dfdfdf on #2d2d2d) used across macOS, Windows, and Linux.
"""

import os
from PIL import Image, ImageDraw

BG_COLOR = (45, 45, 45, 255)    # #2d2d2d
FG_COLOR = (223, 223, 223, 255) # #dfdfdf


def create_icon_image(target_size: int = 512, scale: int = 2, maskable: bool = False) -> Image.Image:
    size = target_size * scale
    s = float(size)
    cx = s / 2.0
    cy = s / 2.0

    if maskable:
        # Full-bleed background for maskable PWA icons (safe zone within central 80% circle)
        img = Image.new("RGBA", (size, size), BG_COLOR)
        d = ImageDraw.Draw(img)
        reticle_scale = (target_size / 1024.0) * scale * 0.82
    else:
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        r_bg = 480 * (target_size / 1024.0) * scale
        d.ellipse([cx - r_bg, cy - r_bg, cx + r_bg, cy + r_bg], fill=BG_COLOR)
        reticle_scale = (target_size / 1024.0) * scale

    r_ring = 200 * reticle_scale
    t_in = 110 * reticle_scale
    t_out = 280 * reticle_scale
    st = max(2, int(round(48 * reticle_scale)))
    cap_r = st / 2.0

    # Outer ring at #dfdfdf
    d.ellipse([cx - r_ring, cy - r_ring, cx + r_ring, cy + r_ring], outline=FG_COLOR, width=st)

    # 4 Ticks with rounded end caps
    for (p1, p2) in [
        ((cx, cy - t_out), (cx, cy - t_in)),
        ((cx, cy + t_in), (cx, cy + t_out)),
        ((cx - t_out, cy), (cx - t_in, cy)),
        ((cx + t_in, cy), (cx + t_out, cy)),
    ]:
        d.line([p1, p2], fill=FG_COLOR, width=st)
        d.ellipse([p1[0] - cap_r, p1[1] - cap_r, p1[0] + cap_r, p1[1] + cap_r], fill=FG_COLOR)
        d.ellipse([p2[0] - cap_r, p2[1] - cap_r, p2[0] + cap_r, p2[1] + cap_r], fill=FG_COLOR)

    return img.resize((target_size, target_size), Image.Resampling.LANCZOS)


SVG_ICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="512" height="512">
  <circle cx="512" cy="512" r="480" fill="#2d2d2d" />
  <circle cx="512" cy="512" r="200" fill="none" stroke="#dfdfdf" stroke-width="48" />
  <g stroke="#dfdfdf" stroke-width="48" stroke-linecap="round">
    <line x1="512" y1="232" x2="512" y2="402" />
    <line x1="512" y1="622" x2="512" y2="792" />
    <line x1="232" y1="512" x2="402" y2="512" />
    <line x1="622" y1="512" x2="792" y2="512" />
  </g>
</svg>
"""


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    icons_dir = os.path.abspath(os.path.join(script_dir, "..", "icons"))
    os.makedirs(icons_dir, exist_ok=True)

    standard_sizes = [16, 32, 48, 64, 128, 180, 192, 256, 512]
    for sz in standard_sizes:
        img = create_icon_image(sz, scale=4 if sz <= 128 else 2, maskable=False)
        out_path = os.path.join(icons_dir, f"icon-{sz}.png")
        img.save(out_path, "PNG")
        print(f"Generated {out_path}")

    for sz in [192, 512]:
        img = create_icon_image(sz, scale=2, maskable=True)
        out_path = os.path.join(icons_dir, f"icon-maskable-{sz}.png")
        img.save(out_path, "PNG")
        print(f"Generated {out_path}")

    svg_path = os.path.join(icons_dir, "icon.svg")
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(SVG_ICON)
    print(f"Generated {svg_path}")


if __name__ == "__main__":
    main()
