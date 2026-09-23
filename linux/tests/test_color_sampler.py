"""
Unit tests for Linux color sampler (PortalColorSampler and X11ColorSampler).
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from color_sampler import PortalColorSampler, X11ColorSampler


class TestColorSampler(unittest.TestCase):
    def test_sampler_initialization(self):
        sampler = PortalColorSampler()
        self.assertFalse(sampler.is_sampling)
        self.assertEqual(sampler.parent_window_handle, "")

    def test_x11_sampler_availability_check(self):
        # Checks that is_available executes without unhandled exception
        available = X11ColorSampler.is_available()
        self.assertIsInstance(available, bool)

    def test_sampler_state_management(self):
        sampler = PortalColorSampler()
        self.assertFalse(sampler.is_sampling)

        cancelled = []
        # If GI is not present (or in unit test environment without active display),
        # pick_color should gracefully call on_cancel
        sampler.pick_color(
            on_success=lambda r, g, b: None,
            on_cancel=lambda: cancelled.append(True),
        )
        self.assertFalse(sampler.is_sampling)


if __name__ == "__main__":
    unittest.main()
