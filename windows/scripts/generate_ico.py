#!/usr/bin/env python3
"""
Generates multi-resolution Windows icon (app.ico) and assets for Contrast Checker.
The icon matches the color picker button: a target style reticle in #dfdfdf
on a round background at #2d2d2d.
"""

import os
from PIL import Image, ImageDraw

BG_COLOR = (45, 45, 45, 255)    # #2d2d2d
FG_COLOR = (223, 223, 223, 255) # #dfdfdf

def create_icon_image(target_size: int = 1024, scale: int = 2) -> Image.Image:
    size = target_size * scale
    s = float(size)
    cx = s / 2.0
    cy = s / 2.0

    r_bg = 480 * scale
    r_ring = 200 * scale
    t_in = 110 * scale
    t_out = 280 * scale
    st = 48 * scale
    cap_r = st / 2.0

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # 1. Round background at #2d2d2d
    d.ellipse([cx - r_bg, cy - r_bg, cx + r_bg, cy + r_bg], fill=BG_COLOR)

    # 2. Outer ring at #dfdfdf
    d.ellipse([cx - r_ring, cy - r_ring, cx + r_ring, cy + r_ring], outline=FG_COLOR, width=st)

    # 3. 4 Ticks with rounded end caps
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

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    res_dir = os.path.join(script_dir, "..", "ContrastChecker", "Resources")
    os.makedirs(res_dir, exist_ok=True)
    ico_path = os.path.join(res_dir, "app.ico")
    png_path = os.path.join(res_dir, "app.png")

    print("Generating high-res master icon...")
    master = create_icon_image(1024, scale=2)
    master.save(png_path, "PNG")
    print(f"Saved master PNG to {png_path}")

    sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

    # Save multi-resolution ICO
    master.save(
        ico_path,
        format="ICO",
        sizes=sizes
    )
    print(f"Generated multi-resolution ICO at {ico_path} with sizes: {sizes}")

if __name__ == "__main__":
    main()
