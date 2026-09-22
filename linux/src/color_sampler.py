"""
Screen color sampler for Linux using the XDG Desktop Portal.
Interacts with org.freedesktop.portal.Screenshot.PickColor over DBus.
Works across Wayland (GNOME, KDE Plasma, Sway, Hyprland) and X11, including inside Flatpak sandboxes.
"""

import sys
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


class PortalColorSampler:
    """Invokes the FreeDesktop XDG Desktop Portal to sample any screen pixel."""

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
    ) -> None:
        """Requests a color pick from the desktop portal."""
        if not HAS_GI:
            if on_cancel:
                on_cancel()
            return

        if self._is_sampling:
            return

        self._is_sampling = True

        try:
            connection = Gio.bus_get_sync(Gio.BusType.SESSION, None)
            token = f"cc_{uuid.uuid4().hex[:8]}"

            # Listen for portal Response signal on the request object path
            sender_name = connection.get_unique_name().lstrip(":").replace(".", "_")
            request_path = f"/org/freedesktop/portal/desktop/request/{sender_name}/{token}"

            subscription_id = [None]

            def on_signal(conn, sender, path, iface, signal, params):
                if signal != "Response" or path != request_path:
                    return

                # Clean up signal subscription
                if subscription_id[0] is not None:
                    conn.signal_unsubscribe(subscription_id[0])
                    subscription_id[0] = None

                self._is_sampling = False
                response_code, results = params.unpack()

                if response_code == 0 and "color" in results:
                    # 'color' is a tuple of 3 doubles (r, g, b) in range 0.0 - 1.0
                    r_d, g_d, b_d = results["color"]
                    r = max(0, min(255, int(round(r_d * 255.0))))
                    g = max(0, min(255, int(round(g_d * 255.0))))
                    b = max(0, min(255, int(round(b_d * 255.0))))
                    GLib.idle_add(on_success, r, g, b)
                else:
                    if on_cancel:
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

            # Build options dictionary
            options = {
                "handle_token": GLib.Variant("s", token),
            }

            # Invoke PickColor method
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
                None,
            )

        except Exception as e:
            self._is_sampling = False
            print(f"[ColorSampler] Portal PickColor call error: {e}", file=sys.stderr)
            if on_cancel:
                on_cancel()

    def _on_call_finished(self, connection, res, user_data):
        try:
            connection.call_finish(res)
        except Exception as e:
            self._is_sampling = False
            print(f"[ColorSampler] PickColor finish error: {e}", file=sys.stderr)
