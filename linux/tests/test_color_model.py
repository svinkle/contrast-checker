"""
Unit tests for Linux ColorModel.
"""

import os
import sys
import unittest

# Ensure linux/src is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from color_model import ColorModel


class TestColorModel(unittest.TestCase):
    def test_default_initialization_black_vs_white(self):
        model = ColorModel()
        self.assertEqual(model.bg_hex, "#000000")
        self.assertEqual(model.fg_hex, "#FFFFFF")
        self.assertAlmostEqual(model.contrast_ratio, 21.0, places=2)
        self.assertEqual(model.contrast_ratio_string, "21.00:1")

    def test_identical_colors_should_be_one_to_one(self):
        model = ColorModel(background=(255, 255, 255), foreground=(255, 255, 255))
        self.assertAlmostEqual(model.contrast_ratio, 1.0, places=2)
        self.assertEqual(model.contrast_ratio_string, "1.00:1")

    def test_reference_pair_should_match(self):
        # Reference #101631 vs #FFFFFF yields ~17.78:1
        model = ColorModel()
        model.set_background_hex("#101631")
        model.set_foreground_hex("#FFFFFF")
        self.assertEqual(model.bg_hex, "#101631")
        self.assertEqual(model.fg_hex, "#FFFFFF")
        self.assertAlmostEqual(model.contrast_ratio, 17.78, delta=0.01)
        self.assertEqual(model.contrast_ratio_value_only, "17.78")
        self.assertEqual(model.contrast_ratio_string, "17.78:1")

    def test_symmetry_inverted_order_yields_identical_ratio(self):
        model1 = ColorModel(background=(16, 22, 49), foreground=(255, 255, 255))
        model2 = ColorModel(background=(255, 255, 255), foreground=(16, 22, 49))
        self.assertAlmostEqual(model1.contrast_ratio, model2.contrast_ratio, places=2)

    def test_hex_parsing_and_formatting(self):
        # 6-char hex
        self.assertEqual(ColorModel.color_from_hex("#FFFFFF"), (255, 255, 255))
        self.assertEqual(ColorModel.color_from_hex("#000000"), (0, 0, 0))
        self.assertEqual(ColorModel.color_from_hex("#101631"), (16, 22, 49))
        self.assertEqual(ColorModel.color_from_hex("101631"), (16, 22, 49))

        # 3-char shorthand (#FFF -> #FFFFFF)
        self.assertEqual(ColorModel.color_from_hex("#FFF"), (255, 255, 255))
        self.assertEqual(ColorModel.color_from_hex("000"), (0, 0, 0))

        # Invalid hex
        self.assertIsNone(ColorModel.color_from_hex("invalid"))
        self.assertIsNone(ColorModel.color_from_hex("#12"))
        self.assertIsNone(ColorModel.color_from_hex("#12345"))

    def test_copy_value_message(self):
        model = ColorModel()
        model.copy_value(model.bg_hex, model.bg_hex)
        self.assertEqual(model.copied_message, "Copied #000000")
        model.clear_copied_message()
        self.assertIsNone(model.copied_message)


if __name__ == "__main__":
    unittest.main()
