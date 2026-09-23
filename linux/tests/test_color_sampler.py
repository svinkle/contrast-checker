"""
Unit tests for Linux color sampler (PortalColorSampler and X11ColorSampler).
"""

import os
import sys
import time
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from color_sampler import PortalColorSampler, X11ColorSampler


class TestColorSampler(unittest.TestCase):
    def test_sampler_initialization(self):
        sampler = PortalColorSampler()
        self.assertFalse(sampler.is_sampling)
        self.assertEqual(sampler.parent_window_handle, "")

    def test_x11_sampler_availability_check(self):
        available = X11ColorSampler.is_available()
        self.assertIsInstance(available, bool)

    def test_sampler_state_management(self):
        sampler = PortalColorSampler()
        self.assertFalse(sampler.is_sampling)

        cancelled = []
        sampler.pick_color(
            on_success=lambda r, g, b: None,
            on_cancel=lambda: cancelled.append(True),
        )
        # When sampling begins, is_sampling is active
        self.assertTrue(sampler.is_sampling)

        # Wait for thread to attempt grab and cancel due to no active X display in headless test
        for _ in range(30):
            if not sampler.is_sampling:
                break
            time.sleep(0.05)

        self.assertFalse(sampler.is_sampling)


if __name__ == "__main__":
    unittest.main()
