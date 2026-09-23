"""
Screen color sampler for Linux.
Provides hybrid support:
- FreeDesktop XDG Desktop Portal (org.freedesktop.portal.Screenshot.PickColor) for Wayland (GNOME, KDE Plasma).
- Native X11 screen sampling via libX11.so.6 and ctypes for X11 desktops (XFCE, MATE, Cinnamon)
  featuring live hover color preview and dual grab/polling detection.
Zero external pip dependencies required.
"""

import ctypes
import os
import sys
import threading
import time
import uuid
from typing import Callable, Optional, Tuple

try:
    import gi
    gi.require_version("Gio", "2.0")
    gi.require_version("GLib", "2.0")
    from gi.repository import Gio, GLib
    HAS_GI = True
except (ValueError, ImportError):
    HAS_GI = False


class X11ColorSampler:
    """
    Direct screen color sampler for X11 sessions (XFCE, MATE, Cinnamon, etc.).
    Uses libX11.so.6 via ctypes with crosshair cursor, live hover preview,
    and automatic polling fallback if pointer grab is busy.
    """
    _x11 = None
    _x11_checked = False

    @classmethod
    def get_libx11(cls):
        if not cls._x11_checked:
            cls._x11_checked = True
            candidates = [
                "libX11.so.6",
                "libX11.so",
                "/usr/lib/x86_64-linux-gnu/libX11.so.6",
                "/usr/lib/aarch64-linux-gnu/libX11.so.6",
                "/usr/lib64/libX11.so.6",
                "/usr/lib/libX11.so.6",
            ]
            for name in candidates:
                try:
                    cls._x11 = ctypes.cdll.LoadLibrary(name)
                    break
                except Exception:
                    pass
            if cls._x11 is None:
                try:
                    import ctypes.util
                    found = ctypes.util.find_library("X11")
                    if found:
                        cls._x11 = ctypes.cdll.LoadLibrary(found)
                except Exception:
                    pass

            if cls._x11 is not None:
                cls._setup_prototypes(cls._x11)
                try:
                    cls._x11.XInitThreads()
                except Exception:
                    pass

        return cls._x11

    @classmethod
    def _setup_prototypes(cls, x11):
        try:
            x11.XInitThreads.argtypes = []
            x11.XInitThreads.restype = ctypes.c_int

            x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
            x11.XOpenDisplay.restype = ctypes.c_void_p

            x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
            x11.XCloseDisplay.restype = ctypes.c_int

            x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
            x11.XDefaultRootWindow.restype = ctypes.c_ulong

            x11.XCreateFontCursor.argtypes = [ctypes.c_void_p, ctypes.c_uint]
            x11.XCreateFontCursor.restype = ctypes.c_ulong

            x11.XFreeCursor.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
            x11.XFreeCursor.restype = ctypes.c_int

            x11.XGrabPointer.argtypes = [
                ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
                ctypes.c_uint, ctypes.c_int, ctypes.c_int,
                ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong
            ]
            x11.XGrabPointer.restype = ctypes.c_int

            x11.XUngrabPointer.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
            x11.XUngrabPointer.restype = ctypes.c_int

            x11.XGrabKeyboard.argtypes = [
                ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
                ctypes.c_int, ctypes.c_int, ctypes.c_ulong
            ]
            x11.XGrabKeyboard.restype = ctypes.c_int

            x11.XUngrabKeyboard.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
            x11.XUngrabKeyboard.restype = ctypes.c_int

            x11.XQueryPointer.argtypes = [
                ctypes.c_void_p, ctypes.c_ulong,
                ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong),
                ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int),
                ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int),
                ctypes.POINTER(ctypes.c_uint)
            ]
            x11.XQueryPointer.restype = ctypes.c_int

            x11.XGetImage.argtypes = [
                ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_int,
                ctypes.c_uint, ctypes.c_uint, ctypes.c_ulong, ctypes.c_int
            ]
            x11.XGetImage.restype = ctypes.c_void_p

            x11.XGetPixel.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
            x11.XGetPixel.restype = ctypes.c_ulong

            x11.XDestroyImage.argtypes = [ctypes.c_void_p]
            x11.XDestroyImage.restype = ctypes.c_int

            x11.XNextEvent.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
            x11.XNextEvent.restype = ctypes.c_int

            x11.XFlush.argtypes = [ctypes.c_void_p]
            x11.XFlush.restype = ctypes.c_int
        except Exception as e:
            print(f"[X11ColorSampler] Error configuring prototypes: {e}", file=sys.stderr)

    @classmethod
    def is_available(cls) -> bool:
        if os.environ.get("WAYLAND_DISPLAY") and not os.environ.get("DISPLAY"):
            return False
        return cls.get_libx11() is not None

    @classmethod
    def pick_color_async(
        cls,
        on_success: Callable[[int, int, int], None],
        on_cancel: Optional[Callable[[], None]] = None,
        on_preview: Optional[Callable[[int, int, int], None]] = None,
    ) -> bool:
        x11 = cls.get_libx11()
        if not x11:
            return False

        thread = threading.Thread(
            target=cls._worker,
            args=(x11, on_success, on_cancel, on_preview),
            daemon=True
        )
        thread.start()
        return True

    @classmethod
    def _worker(cls, x11, on_success, on_cancel, on_preview):
        # Brief sleep to let GTK release any active button-press pointer grab
        time.sleep(0.15)

        display = x11.XOpenDisplay(None)
        if not display:
            if on_cancel:
                if HAS_GI:
                    GLib.idle_add(on_cancel)
                else:
                    on_cancel()
            return

        root = x11.XDefaultRootWindow(display)
        XC_crosshair = 34
        cursor = x11.XCreateFontCursor(display, XC_crosshair)

        ButtonPressMask = 4
        ButtonReleaseMask = 8
        PointerMotionMask = 64
        event_mask = ButtonPressMask | ButtonReleaseMask | PointerMotionMask
        GrabModeAsync = 1
        CurrentTime = 0

        # Attempt to grab pointer; retry up to 2 seconds if WM/seat is releasing grab
        grab_ok = False
        for _ in range(40):
            res = x11.XGrabPointer(
                display, root, False, event_mask,
                GrabModeAsync, GrabModeAsync, root, cursor, CurrentTime
            )
            if res == 0:
                grab_ok = True
                break
            time.sleep(0.05)

        if grab_ok:
            x11.XGrabKeyboard(display, root, False, GrabModeAsync, GrabModeAsync, CurrentTime)
            x11.XFlush(display)

        class XRawEvent(ctypes.Structure):
            _fields_ = [
                ("type", ctypes.c_int),
                ("pad", ctypes.c_byte * 252),
            ]

        event = XRawEvent()
        picked_color = None
        cancelled = False
        last_coord = (-1, -1)

        root_ret = ctypes.c_ulong()
        child_ret = ctypes.c_ulong()
        rx = ctypes.c_int()
        ry = ctypes.c_int()
        wx = ctypes.c_int()
        wy = ctypes.c_int()
        mask = ctypes.c_uint()
        ZPixmap = 2
        AllPlanes = 0xFFFFFFFF

        def sample_pixel_at(px, py):
            img = x11.XGetImage(display, root, px, py, 1, 1, AllPlanes, ZPixmap)
            if img:
                pixel = x11.XGetPixel(img, 0, 0)
                r = (pixel >> 16) & 0xFF
                g = (pixel >> 8) & 0xFF
                b = pixel & 0xFF
                x11.XDestroyImage(img)
                return (r, g, b)
            return None

        if grab_ok:
            # Mode A: Event-driven via exclusive pointer grab
            while not cancelled and picked_color is None:
                x11.XNextEvent(display, ctypes.byref(event))

                if event.type == 6:  # MotionNotify -> live preview
                    x11.XQueryPointer(
                        display, root,
                        ctypes.byref(root_ret), ctypes.byref(child_ret),
                        ctypes.byref(rx), ctypes.byref(ry),
                        ctypes.byref(wx), ctypes.byref(wy),
                        ctypes.byref(mask)
                    )
                    curr = (rx.value, ry.value)
                    if curr != last_coord:
                        last_coord = curr
                        col = sample_pixel_at(curr[0], curr[1])
                        if col and on_preview:
                            if HAS_GI:
                                GLib.idle_add(on_preview, col[0], col[1], col[2])
                            else:
                                on_preview(col[0], col[1], col[2])

                elif event.type == 4:  # ButtonPress -> lock color
                    button_val = 1
                    try:
                        button_val = ctypes.c_uint.from_buffer_copy(event.pad[80:84]).value
                    except Exception:
                        button_val = 1

                    if button_val == 1 or button_val == 0:
                        x11.XQueryPointer(
                            display, root,
                            ctypes.byref(root_ret), ctypes.byref(child_ret),
                            ctypes.byref(rx), ctypes.byref(ry),
                            ctypes.byref(wx), ctypes.byref(wy),
                            ctypes.byref(mask)
                        )
                        col = sample_pixel_at(rx.value, ry.value)
                        if col:
                            picked_color = col
                        else:
                            cancelled = True
                    else:
                        cancelled = True

                elif event.type == 2:  # KeyPress (Escape)
                    cancelled = True
        else:
            # Mode B: Polling fallback mode if pointer grab was blocked by compositor
            while not cancelled and picked_color is None:
                x11.XQueryPointer(
                    display, root,
                    ctypes.byref(root_ret), ctypes.byref(child_ret),
                    ctypes.byref(rx), ctypes.byref(ry),
                    ctypes.byref(wx), ctypes.byref(wy),
                    ctypes.byref(mask)
                )
                m = mask.value
                curr = (rx.value, ry.value)
                if curr != last_coord:
                    last_coord = curr
                    col = sample_pixel_at(curr[0], curr[1])
                    if col and on_preview:
                        if HAS_GI:
                            GLib.idle_add(on_preview, col[0], col[1], col[2])
                        else:
                            on_preview(col[0], col[1], col[2])

                # Button1Mask = 256, Button3Mask = 1024
                if m & 256:
                    col = sample_pixel_at(curr[0], curr[1])
                    if col:
                        picked_color = col
                    else:
                        cancelled = True
                    break
                elif m & 1024:
                    cancelled = True
                    break

                time.sleep(0.02)

        if grab_ok:
            x11.XUngrabPointer(display, CurrentTime)
            x11.XUngrabKeyboard(display, CurrentTime)
        x11.XFreeCursor(display, cursor)
        x11.XFlush(display)
        x11.XCloseDisplay(display)

        if picked_color is not None:
            r, g, b = picked_color
            if HAS_GI:
                GLib.idle_add(on_success, r, g, b)
            else:
                on_success(r, g, b)
        else:
            if on_cancel:
                if HAS_GI:
                    GLib.idle_add(on_cancel)
                else:
                    on_cancel()


class PortalColorSampler:
    """
    Invokes FreeDesktop XDG Desktop Portal on Wayland (GNOME, KDE),
    with automatic native X11 fallback for X11 desktops (XFCE, MATE, Cinnamon).
    """

    PORTAL_BUS = "org.freedesktop.portal.Desktop"
    PORTAL_PATH = "/org/freedesktop/portal/desktop"
    PORTAL_INTERFACE = "org.freedesktop.portal.Screenshot"

    def __init__(self, parent_window_handle: str = ""):
        self.parent_window_handle = parent_window_handle
        self._is_sampling = False

    @property
    def is_sampling(self) -> bool:
        return self._is_sampling

    def pick_color(
        self,
        on_success: Callable[[int, int, int], None],
        on_cancel: Optional[Callable[[], None]] = None,
        on_preview: Optional[Callable[[int, int, int], None]] = None,
    ) -> None:
        """Requests a color pick using direct X11 on X11 or Desktop Portal on Wayland."""
        if self._is_sampling:
            return

        def wrapped_success(r, g, b):
            self._is_sampling = False
            on_success(r, g, b)

        def wrapped_cancel():
            self._is_sampling = False
            if on_cancel:
                on_cancel()

        self._is_sampling = True

        is_wayland = bool(os.environ.get("WAYLAND_DISPLAY")) or os.environ.get("XDG_SESSION_TYPE") == "wayland"

        if not is_wayland and X11ColorSampler.is_available():
            if X11ColorSampler.pick_color_async(wrapped_success, wrapped_cancel, on_preview):
                return

        # Fallback to Desktop Portal (for Wayland sessions or when X11 is not available)
        self._pick_color_portal(wrapped_success, wrapped_cancel, on_preview)

    def _pick_color_portal(
        self,
        on_success: Callable[[int, int, int], None],
        on_cancel: Callable[[], None],
        on_preview: Optional[Callable[[int, int, int], None]] = None,
    ) -> None:
        if not HAS_GI:
            on_cancel()
            return

        try:
            connection = Gio.bus_get_sync(Gio.BusType.SESSION, None)
            token = f"cc_{uuid.uuid4().hex[:8]}"

            sender_name = connection.get_unique_name().lstrip(":").replace(".", "_")
            request_path = f"/org/freedesktop/portal/desktop/request/{sender_name}/{token}"

            subscription_id = [None]

            def on_signal(conn, sender, path, iface, signal, params):
                if signal != "Response" or path != request_path:
                    return

                if subscription_id[0] is not None:
                    conn.signal_unsubscribe(subscription_id[0])
                    subscription_id[0] = None

                response_code, results = params.unpack()

                if response_code == 0 and "color" in results:
                    r_d, g_d, b_d = results["color"]
                    r = max(0, min(255, int(round(r_d * 255.0))))
                    g = max(0, min(255, int(round(g_d * 255.0))))
                    b = max(0, min(255, int(round(b_d * 255.0))))
                    GLib.idle_add(on_success, r, g, b)
                else:
                    GLib.idle_add(on_cancel)

            subscription_id[0] = connection.signal_subscribe(
                self.PORTAL_BUS,
                "org.freedesktop.portal.Request",
                "Response",
                request_path,
                None,
                Gio.DBusSignalFlags.NONE,
                on_signal,
            )

            options = {
                "handle_token": GLib.Variant("s", token),
            }

            user_data = {
                "on_success": on_success,
                "on_cancel": on_cancel,
                "on_preview": on_preview,
            }

            connection.call(
                self.PORTAL_BUS,
                self.PORTAL_PATH,
                self.PORTAL_INTERFACE,
                "PickColor",
                GLib.Variant("(sa{sv})", (self.parent_window_handle, options)),
                None,
                Gio.DBusCallFlags.NONE,
                -1,
                None,
                self._on_call_finished,
                user_data,
            )

        except Exception as e:
            print(f"[ColorSampler] Portal PickColor call failed ({e}), attempting X11 fallback...", file=sys.stderr)
            if X11ColorSampler.is_available() and X11ColorSampler.pick_color_async(on_success, on_cancel, on_preview):
                return
            on_cancel()

    def _on_call_finished(self, connection, res, user_data):
        try:
            connection.call_finish(res)
        except Exception as e:
            print(f"[ColorSampler] Portal PickColor unavailable ({e}), trying X11 fallback...", file=sys.stderr)
            if X11ColorSampler.is_available():
                if X11ColorSampler.pick_color_async(user_data["on_success"], user_data["on_cancel"], user_data.get("on_preview")):
                    return
            user_data["on_cancel"]()
