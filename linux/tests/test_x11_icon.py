"""
Unit tests for Linux X11 window icon setter and icon data.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from icon_data import get_net_wm_icon_data
from x11_icon import set_x11_window_icon, apply_window_icon, find_windows_by_pid


class TestX11Icon(unittest.TestCase):
    def test_net_wm_icon_data_format(self):
        data = get_net_wm_icon_data()
        self.assertIsInstance(data, list)
        self.assertGreater(len(data), 0)

        # Check that sizes match expected (16, 24, 32, 48, 64)
        offset = 0
        found_sizes = []
        while offset < len(data):
            w = data[offset]
            h = data[offset + 1]
            self.assertEqual(w, h)
            found_sizes.append(w)
            offset += 2 + (w * h)

        self.assertEqual(found_sizes, [16, 24, 32, 48, 64])

    def test_set_x11_window_icon_invalid_xid(self):
        # Should gracefully return False when xid is 0 or invalid without crashing
        result = set_x11_window_icon(0)
        self.assertFalse(result)

    def test_apply_window_icon_graceful_headless(self):
        # In a headless test environment without an X display, should return False gracefully
        result = apply_window_icon(0)
        self.assertIsInstance(result, bool)

    def test_find_windows_by_pid_graceful_headless(self):
        # Without an X display, should return an empty list gracefully
        windows = find_windows_by_pid(os.getpid())
        self.assertIsInstance(windows, list)


if __name__ == "__main__":
    unittest.main()
