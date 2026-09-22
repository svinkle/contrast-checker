#!/usr/bin/env python3
"""
Generates multi-resolution Windows icon (app.ico) for Contrast Checker.
The icon features a split squircle (top black, bottom white) with an inverted target reticle.
"""

import os
from PIL import Image, ImageDraw

def create_icon_image(size: int = 1024) -> Image.Image:
    # Render at high resolution for antialiasing
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    s = float(size)
    corner_radius = int(s * 0.2237)
    inset = int(s * 0.04)

    # 1. Mask for rounded squircle
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [inset, inset, size - inset, size - inset],
        radius=corner_radius,
        fill=255
    )

    # 2. Background image: Top black, bottom white
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    mid_y = size // 2
    # Top half (black #0D0D10)
    bg_draw.rectangle([0, 0, size, mid_y], fill=(13, 13, 16, 255))
    # Bottom half (white)
    bg_draw.rectangle([0, mid_y, size, size], fill=(255, 255, 255, 255))

    # Apply squircle mask to background
    squircle_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    squircle_bg.paste(bg, (0, 0), mask=mask)

    # 3. Draw Target Reticle
    # We will draw a white target and a black target, then mask each to their respective halves
    def draw_reticle(color):
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ldraw = ImageDraw.Draw(layer)
        cx = s / 2.0
        cy = s / 2.0
        outer_radius = s * 0.23
        stroke_w = max(2, int(s * 0.032))

        # Outer ring
        ldraw.ellipse(
            [cx - outer_radius, cy - outer_radius, cx + outer_radius, cy + outer_radius],
            outline=color,
            width=stroke_w
        )

        # Crosshair tick arms
        tick_inner = outer_radius * 0.65
        tick_outer = outer_radius * 1.35

        # Top tick
        ldraw.line([(cx, cy - tick_outer), (cx, cy - tick_inner)], fill=color, width=stroke_w)
        # Bottom tick
        ldraw.line([(cx, cy + tick_inner), (cx, cy + tick_outer)], fill=color, width=stroke_w)
        # Left tick
        ldraw.line([(cx - tick_outer, cy), (cx - tick_inner, cy)], fill=color, width=stroke_w)
        # Right tick
        ldraw.line([(cx + tick_inner, cy), (cx + tick_outer, cy)], fill=color, width=stroke_w)

        # Center crosshair
        center_arm = outer_radius * 0.28
        center_w = max(2, int(stroke_w * 0.9))
        ldraw.line([(cx - center_arm, cy), (cx + center_arm, cy)], fill=color, width=center_w)
        ldraw.line([(cx, cy - center_arm), (cx, cy + center_arm)], fill=color, width=center_w)

        return layer

    white_target = draw_reticle((255, 255, 255, 255))
    black_target = draw_reticle((13, 13, 16, 255))

    # Top half mask for white target
    top_mask = Image.new("L", (size, size), 0)
    top_draw = ImageDraw.Draw(top_mask)
    top_draw.rectangle([0, 0, size, mid_y], fill=255)

    # Bottom half mask for black target
    bottom_mask = Image.new("L", (size, size), 0)
    bottom_draw = ImageDraw.Draw(bottom_mask)
    bottom_draw.rectangle([0, mid_y, size, size], fill=255)

    # Composite together
    final_img = squircle_bg.copy()
    final_img.paste(white_target, (0, 0), mask=top_mask)
    final_img.paste(black_target, (0, 0), mask=bottom_mask)

    return final_img

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    res_dir = os.path.join(script_dir, "..", "ContrastChecker", "Resources")
    os.makedirs(res_dir, exist_ok=True)
    ico_path = os.path.join(res_dir, "app.ico")
    png_path = os.path.join(res_dir, "app.png")

    print("Generating high-res master icon...")
    master = create_icon_image(1024)
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
