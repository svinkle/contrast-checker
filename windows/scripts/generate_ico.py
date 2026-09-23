#!/usr/bin/env python3
"""
Generates multi-resolution Windows icon (app.ico) and assets for Contrast Checker.
Features a high-contrast target reticle with a black border around the top-half white portion
and a white border around the bottom-half black portion.
"""

import os
from PIL import Image, ImageDraw, ImageFilter

def create_icon_image(target_size: int = 1024, scale: int = 2) -> Image.Image:
    # Render with 2x supersampling for crisp antialiasing
    size = target_size * scale
    s = float(size)
    cx = s / 2.0
    cy = s / 2.0
    outer_radius = s * 0.23
    tick_inner = outer_radius * 0.65
    tick_outer = outer_radius * 1.35
    center_arm = outer_radius * 0.28

    stroke = int(38 * scale)
    c_stroke = int(34 * scale)
    border_radius = int(8 * scale)

    def draw_target(color):
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        # Outer ring
        d.ellipse([cx - outer_radius, cy - outer_radius, cx + outer_radius, cy + outer_radius], outline=color, width=stroke)
        # Ticks
        d.line([(cx, cy - tick_outer), (cx, cy - tick_inner)], fill=color, width=stroke)
        d.line([(cx, cy + tick_inner), (cx, cy + tick_outer)], fill=color, width=stroke)
        d.line([(cx - tick_outer, cy), (cx - tick_inner, cy)], fill=color, width=stroke)
        d.line([(cx + tick_inner, cy), (cx + tick_outer, cy)], fill=color, width=stroke)
        # Center crosshair
        d.line([(cx - center_arm, cy), (cx + center_arm, cy)], fill=color, width=c_stroke)
        d.line([(cx, cy - center_arm), (cx, cy + center_arm)], fill=color, width=c_stroke)
        
        # Rounded caps for all stroke ends
        r = stroke / 2.0
        c_r = c_stroke / 2.0
        d.ellipse([cx - r, cy - tick_outer - r, cx + r, cy - tick_outer + r], fill=color)
        d.ellipse([cx - r, cy + tick_outer - r, cx + r, cy + tick_outer + r], fill=color)
        d.ellipse([cx - tick_outer - r, cy - r, cx - tick_outer + r, cy + r], fill=color)
        d.ellipse([cx + tick_outer - r, cy - r, cx + tick_outer + r, cy + r], fill=color)
        d.ellipse([cx - r, cy - tick_inner - r, cx + r, cy - tick_inner + r], fill=color)
        d.ellipse([cx - r, cy + tick_inner - r, cx + r, cy + tick_inner + r], fill=color)
        d.ellipse([cx - tick_inner - r, cy - r, cx - tick_inner + r, cy + r], fill=color)
        d.ellipse([cx + tick_inner - r, cy - r, cx + tick_inner + r, cy + r], fill=color)
        d.ellipse([cx - center_arm - c_r, cy - c_r, cx - center_arm + c_r, cy + c_r], fill=color)
        d.ellipse([cx + center_arm - c_r, cy - c_r, cx + center_arm + c_r, cy + c_r], fill=color)
        d.ellipse([cx - c_r, cy - center_arm - c_r, cx + c_r, cy - center_arm + c_r], fill=color)
        d.ellipse([cx - c_r, cy + center_arm - c_r, cx + c_r, cy + center_arm + c_r], fill=color)
        return layer

    base = draw_target((255, 255, 255, 255))
    top_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(top_mask).rectangle([0, 0, size, int(cy)], fill=255)
    bot_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(bot_mask).rectangle([0, int(cy), size, size], fill=255)

    top_white = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    top_white.paste(base, (0, 0), mask=top_mask)

    bot_black = Image.new("RGBA", (size, size), (13, 13, 16, 255))
    bot_black.putalpha(base.split()[3])
    bot_black_split = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bot_black_split.paste(bot_black, (0, 0), mask=bot_mask)

    top_alpha = top_white.split()[3]
    bot_alpha = bot_black_split.split()[3]

    top_dilated = top_alpha.filter(ImageFilter.MaxFilter(2 * border_radius + 1))
    bot_dilated = bot_alpha.filter(ImageFilter.MaxFilter(2 * border_radius + 1))

    top_comp = Image.new("RGBA", (size, size), (13, 13, 16, 255))
    top_comp.putalpha(top_dilated)
    top_comp.paste(top_white, (0, 0), mask=top_alpha)

    bot_comp = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    bot_comp.putalpha(bot_dilated)
    bot_comp.paste(bot_black_split, (0, 0), mask=bot_alpha)

    final = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final.paste(bot_comp, (0, 0), mask=bot_comp.split()[3])
    final.paste(top_comp, (0, 0), mask=top_comp.split()[3])

    return final.resize((target_size, target_size), Image.Resampling.LANCZOS)

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
