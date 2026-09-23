"""
X11 Window Icon setter for Linux desktops using X11 (MATE, XFCE, Cinnamon).
Sets the EWMH _NET_WM_ICON property on native X11 window surfaces so that
panel taskbars (such as Marco and MATE Window List via libwnck) display
the proper application icon instead of a generic fallback.
"""

import ctypes
import os
import sys
from typing import Optional

from color_sampler import X11ColorSampler
from icon_data import get_net_wm_icon_data


def set_x11_window_icon(xid: int) -> bool:
    """
    Sets the _NET_WM_ICON property on the specified X11 window ID.
    Returns True if successfully set, False otherwise.
    Never raises an exception or crashes.
    """
    if not xid or xid <= 0:
        return False

    # If running on pure Wayland without an X11 display, return immediately
    if os.environ.get("WAYLAND_DISPLAY") and not os.environ.get("DISPLAY"):
        return False

    x11 = X11ColorSampler.get_libx11()
    if not x11:
        return False

    try:
        x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        x11.XInternAtom.restype = ctypes.c_ulong

        x11.XChangeProperty.argtypes = [
            ctypes.c_void_p,  # display
            ctypes.c_ulong,   # window
            ctypes.c_ulong,   # property
            ctypes.c_ulong,   # type
            ctypes.c_int,     # format
            ctypes.c_int,     # mode
            ctypes.c_void_p,  # data
            ctypes.c_int,     # nelements
        ]
        x11.XChangeProperty.restype = ctypes.c_int

        display = x11.XOpenDisplay(None)
        if not display:
            return False

        try:
            atom_net_wm_icon = x11.XInternAtom(display, b"_NET_WM_ICON", 0)
            atom_cardinal = x11.XInternAtom(display, b"CARDINAL", 0) or 6

            icon_data = get_net_wm_icon_data()
            if not icon_data:
                return False

            data_array = (ctypes.c_ulong * len(icon_data))(*icon_data)

            PropModeReplace = 0
            res = x11.XChangeProperty(
                display,
                xid,
                atom_net_wm_icon,
                atom_cardinal,
                32,
                PropModeReplace,
                ctypes.cast(ctypes.byref(data_array), ctypes.c_void_p),
                len(icon_data),
            )
            x11.XFlush(display)
            return res != 0
        finally:
            x11.XCloseDisplay(display)
    except Exception as e:
        print(f"[x11_icon] Failed to set _NET_WM_ICON: {e}", file=sys.stderr)
        return False


def apply_window_icon(xid: Optional[int] = None) -> bool:
    """Safely applies the icon to the given X11 window ID."""
    if xid and xid > 0:
        return set_x11_window_icon(xid)
    return False
