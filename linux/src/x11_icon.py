"""
X11 Window Icon setter for Linux desktops using X11 (MATE, XFCE, Cinnamon).
Sets the EWMH _NET_WM_ICON property on native X11 window surfaces so that
panel taskbars (such as Marco and MATE Window List via libwnck) display
the proper application icon instead of a generic fallback.
"""

import ctypes
import os
import sys
from typing import Optional, List

from color_sampler import X11ColorSampler
from icon_data import get_net_wm_icon_data


def set_x11_window_icon(xid: int) -> bool:
    """
    Sets the _NET_WM_ICON property on the specified X11 window ID.
    Returns True if successfully set, False otherwise.
    """
    if not xid:
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


def find_windows_by_pid(pid: int) -> List[int]:
    """Finds top-level X11 windows belonging to the given process ID."""
    x11 = X11ColorSampler.get_libx11()
    if not x11 or not pid:
        return []

    try:
        x11.XQueryTree.argtypes = [
            ctypes.c_void_p, ctypes.c_ulong,
            ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong),
            ctypes.POINTER(ctypes.POINTER(ctypes.c_ulong)), ctypes.POINTER(ctypes.c_uint)
        ]
        x11.XQueryTree.restype = ctypes.c_int

        x11.XGetWindowProperty.argtypes = [
            ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong,
            ctypes.c_long, ctypes.c_long, ctypes.c_int, ctypes.c_ulong,
            ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int),
            ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong),
            ctypes.POINTER(ctypes.c_void_p)
        ]
        x11.XGetWindowProperty.restype = ctypes.c_int

        x11.XFree.argtypes = [ctypes.c_void_p]
        x11.XFree.restype = ctypes.c_int

        display = x11.XOpenDisplay(None)
        if not display:
            return []

        matched_windows = []
        try:
            root = x11.XDefaultRootWindow(display)
            atom_net_wm_pid = x11.XInternAtom(display, b"_NET_WM_PID", 0)
            atom_cardinal = x11.XInternAtom(display, b"CARDINAL", 0) or 6

            root_ret = ctypes.c_ulong()
            parent_ret = ctypes.c_ulong()
            children = ctypes.POINTER(ctypes.c_ulong)()
            nchildren = ctypes.c_uint()

            if x11.XQueryTree(display, root, ctypes.byref(root_ret), ctypes.byref(parent_ret), ctypes.byref(children), ctypes.byref(nchildren)) != 0:
                if children:
                    for i in range(nchildren.value):
                        win = children[i]
                        actual_type = ctypes.c_ulong()
                        actual_format = ctypes.c_int()
                        nitems = ctypes.c_ulong()
                        bytes_after = ctypes.c_ulong()
                        prop = ctypes.c_void_p()

                        ret = x11.XGetWindowProperty(
                            display, win, atom_net_wm_pid, 0, 1, False,
                            atom_cardinal, ctypes.byref(actual_type),
                            ctypes.byref(actual_format), ctypes.byref(nitems),
                            ctypes.byref(bytes_after), ctypes.byref(prop)
                        )
                        if ret == 0 and prop.value:
                            win_pid = ctypes.cast(prop, ctypes.POINTER(ctypes.c_ulong)).contents.value
                            x11.XFree(prop)
                            if win_pid == pid:
                                matched_windows.append(win)

                    x11.XFree(children)
        finally:
            x11.XCloseDisplay(display)

        return matched_windows
    except Exception:
        return []


def apply_window_icon(xid: Optional[int] = None) -> bool:
    """
    Applies the icon to the given X11 window ID or discovers windows by current process PID.
    """
    if xid:
        return set_x11_window_icon(xid)

    # Fallback: discover windows by current process ID
    windows = find_windows_by_pid(os.getpid())
    if windows:
        success = False
        for win in windows:
            if set_x11_window_icon(win):
                success = True
        if success:
            return True

    return False
