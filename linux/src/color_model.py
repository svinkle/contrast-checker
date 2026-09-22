"""
ColorModel for Linux Contrast Checker.
Calculates WCAG 2.1 relative luminance and contrast ratios with full parity to macOS and Windows versions.
"""

import math
from typing import Callable, Optional, Tuple


class ColorModel:
    def __init__(
        self,
        background: Tuple[int, int, int] = (0, 0, 0),
        foreground: Tuple[int, int, int] = (255, 255, 255),
    ):
        self._bg_r, self._bg_g, self._bg_b = background
        self._fg_r, self._fg_g, self._fg_b = foreground
        self.copied_message: Optional[str] = None
        self._listeners = []

    def add_listener(self, listener: Callable[[], None]) -> None:
        """Register a callback for model state changes."""
        self._listeners.append(listener)

    def _notify(self) -> None:
        for listener in self._listeners:
            listener()

    # Properties
    @property
    def background_color(self) -> Tuple[int, int, int]:
        return self._bg_r, self._bg_g, self._bg_b

    @property
    def foreground_color(self) -> Tuple[int, int, int]:
        return self._fg_r, self._fg_g, self._fg_b

    @property
    def bg_hex(self) -> str:
        return self.hex_string_from_rgb(self._bg_r, self._bg_g, self._bg_b)

    @property
    def fg_hex(self) -> str:
        return self.hex_string_from_rgb(self._fg_r, self._fg_g, self._fg_b)

    def set_background_color(self, r: int, g: int, b: int) -> None:
        self._bg_r = max(0, min(255, int(r)))
        self._bg_g = max(0, min(255, int(g)))
        self._bg_b = max(0, min(255, int(b)))
        self._notify()

    def set_foreground_color(self, r: int, g: int, b: int) -> None:
        self._fg_r = max(0, min(255, int(r)))
        self._fg_g = max(0, min(255, int(g)))
        self._fg_b = max(0, min(255, int(b)))
        self._notify()

    def set_background_hex(self, hex_code: str) -> bool:
        rgb = self.color_from_hex(hex_code)
        if rgb is not None:
            self.set_background_color(*rgb)
            return True
        return False

    def set_foreground_hex(self, hex_code: str) -> bool:
        rgb = self.color_from_hex(hex_code)
        if rgb is not None:
            self.set_foreground_color(*rgb)
            return True
        return False

    # WCAG 2.1 Contrast Calculation
    @property
    def contrast_ratio(self) -> float:
        lum1 = self.relative_luminance(self._bg_r, self._bg_g, self._bg_b)
        lum2 = self.relative_luminance(self._fg_r, self._fg_g, self._fg_b)
        lighter = max(lum1, lum2)
        darker = min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)

    @property
    def contrast_ratio_string(self) -> str:
        return f"{self.contrast_ratio:.2f}:1"

    @property
    def contrast_ratio_value_only(self) -> str:
        return f"{self.contrast_ratio:.2f}"

    @staticmethod
    def srgb_to_linear(val: float) -> float:
        """Converts an sRGB component (0.0 to 1.0) to linear light."""
        clamped = max(0.0, min(1.0, val))
        if clamped <= 0.04045:
            return clamped / 12.92
        else:
            return math.pow((clamped + 0.055) / 1.055, 2.4)

    @classmethod
    def relative_luminance(cls, r: int, g: int, b: int) -> float:
        """Computes relative luminance L in accordance with WCAG 2.1."""
        r_lin = cls.srgb_to_linear(r / 255.0)
        g_lin = cls.srgb_to_linear(g / 255.0)
        b_lin = cls.srgb_to_linear(b / 255.0)
        return 0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin

    # Hex Helpers
    @staticmethod
    def hex_string_from_rgb(r: int, g: int, b: int) -> str:
        return f"#{int(r):02X}{int(g):02X}{int(b):02X}"

    @staticmethod
    def color_from_hex(hex_str: str) -> Optional[Tuple[int, int, int]]:
        cleaned = hex_str.strip().lstrip("#")
        if len(cleaned) == 3:
            # Expand 3-character hex shorthand (#RGB -> #RRGGBB)
            try:
                r = int(cleaned[0] * 2, 16)
                g = int(cleaned[1] * 2, 16)
                b = int(cleaned[2] * 2, 16)
                return r, g, b
            except ValueError:
                return None
        elif len(cleaned) == 6:
            try:
                r = int(cleaned[0:2], 16)
                g = int(cleaned[2:4], 16)
                b = int(cleaned[4:6], 16)
                return r, g, b
            except ValueError:
                return None
        return None

    def copy_value(self, value: str, label: str) -> None:
        """Sets the transient copied feedback message."""
        self.copied_message = f"Copied {label}"
        self._notify()

    def clear_copied_message(self) -> None:
        if self.copied_message is not None:
            self.copied_message = None
            self._notify()
