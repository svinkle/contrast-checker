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
        self.assertEqual(model.contrast_ratio_string, "21:1")

    def test_identical_colors_should_be_one_to_one(self):
        model = ColorModel(background=(255, 255, 255), foreground=(255, 255, 255))
        self.assertAlmostEqual(model.contrast_ratio, 1.0, places=2)
        self.assertEqual(model.contrast_ratio_string, "1:1")

    def test_reference_pair_should_match(self):
        # Reference #101631 vs #FFFFFF yields 17.77:1 (floored to 2 decimals)
        model = ColorModel()
        model.set_background_hex("#101631")
        model.set_foreground_hex("#FFFFFF")
        self.assertEqual(model.bg_hex, "#101631")
        self.assertEqual(model.fg_hex, "#FFFFFF")
        self.assertAlmostEqual(model.contrast_ratio, 17.77, places=2)
        self.assertEqual(model.contrast_ratio_value_only, "17.77")
        self.assertEqual(model.contrast_ratio_string, "17.77:1")

    def test_d7d7d7_on_ffffff_floors_to_1_43(self):
        # #D7D7D7 on #FFFFFF yields ~1.439258 -> floored to 1.43:1 (cstrobbe/contrast-ratio parity)
        model = ColorModel()
        model.set_background_hex("#FFFFFF")
        model.set_foreground_hex("#D7D7D7")
        self.assertAlmostEqual(model.contrast_ratio, 1.43, places=2)
        self.assertEqual(model.contrast_ratio_value_only, "1.43")
        self.assertEqual(model.contrast_ratio_string, "1.43:1")

    def test_6f1c96_on_ffffff_yields_9_2(self):
        # #6F1C96 on #FFFFFF yields ~9.200822 -> 9.2:1 (cstrobbe/contrast-ratio parity)
        model = ColorModel()
        model.set_background_hex("#FFFFFF")
        model.set_foreground_hex("#6F1C96")
        self.assertAlmostEqual(model.contrast_ratio, 9.2, places=2)
        self.assertEqual(model.contrast_ratio_value_only, "9.2")
        self.assertEqual(model.contrast_ratio_string, "9.2:1")

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

