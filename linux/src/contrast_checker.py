#!/usr/bin/env python3
"""
Contrast Checker for Linux.
Entry point and application lifecycle manager using GTK 4.
"""

import os
import sys

try:
    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    from gi.repository import Gtk, Gdk, Gio, GLib
    HAS_GTK = True
except (ValueError, ImportError):
    HAS_GTK = False

from color_model import ColorModel
from main_window import MainWindow

APP_ID = "io.github.svinkle.ContrastChecker"

if HAS_GTK:
    # Set prgname and application name so GNOME Shell / Ubuntu dock accurately
    # matches the window to io.github.svinkle.ContrastChecker.desktop and its icon.
    GLib.set_prgname(APP_ID)
    GLib.set_application_name("Contrast Checker")


class ContrastCheckerApplication(Gtk.Application if HAS_GTK else object):
    def __init__(self):
        if not HAS_GTK:
            print("Error: GTK 4 or PyGObject is not available.", file=sys.stderr)
            sys.exit(1)

        super().__init__(
            application_id=APP_ID,
            flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
        )
        self.window = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
        self._load_styles()
        self._setup_icons()
        self._ensure_user_desktop_integration()

    def do_activate(self):
        if not self.window:
            self.window = MainWindow(app=self)
        self.window.present()

    def do_command_line(self, command_line):
        args = command_line.get_arguments()
        self.activate()

        if "--pick-bg" in args:
            GLib.idle_add(self._trigger_pick_bg)
        elif "--pick-fg" in args:
            GLib.idle_add(self._trigger_pick_fg)
        elif "--toggle" in args:
            GLib.idle_add(self._toggle_window)

        return 0

    def _trigger_pick_bg(self):
        if self.window:
            self.window.present()
            self.window._on_pick_background()

    def _trigger_pick_fg(self):
        if self.window:
            self.window.present()
            self.window._on_pick_foreground()

    def _toggle_window(self):
        if self.window:
            if self.window.is_visible():
                self.window.set_visible(False)
            else:
                self.window.present()

    def _load_styles(self):
        css_provider = Gtk.CssProvider()
        css_path = os.path.join(os.path.dirname(__file__), "style.css")

        if os.path.exists(css_path):
            css_provider.load_from_path(css_path)
            display = Gdk.Display.get_default()
            if display:
                Gtk.StyleContext.add_provider_for_display(
                    display,
                    css_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
                )

    def _setup_icons(self):
        display = Gdk.Display.get_default()
        if not display:
            return
        icon_theme = Gtk.IconTheme.get_for_display(display)
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        icons_dir = os.path.join(base_dir, "icons")
        if os.path.exists(icons_dir):
            icon_theme.add_search_path(icons_dir)
            for res in ["128x128", "256x256", "512x512"]:
                res_path = os.path.join(icons_dir, res, "apps")
                if os.path.exists(res_path):
                    icon_theme.add_search_path(res_path)

    def _ensure_user_desktop_integration(self):
        """Copies desktop launcher and icons to ~/.local/share on native host runs so the Ubuntu dock displays the icon."""
        if os.path.exists("/.flatpak-info"):
            return

        try:
            import shutil
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            home = os.path.expanduser("~")
            apps_dir = os.path.join(home, ".local", "share", "applications")
            os.makedirs(apps_dir, exist_ok=True)
            desktop_src = os.path.join(base_dir, "io.github.svinkle.ContrastChecker.desktop")
            desktop_dst = os.path.join(apps_dir, "io.github.svinkle.ContrastChecker.desktop")

            if os.path.exists(desktop_src) and not os.path.exists(desktop_dst):
                with open(desktop_src, "r") as f:
                    content = f.read()
                launcher_script = os.path.join(base_dir, "src", "contrast_checker.py")
                content = content.replace("Exec=contrast-checker", f"Exec={launcher_script}")
                with open(desktop_dst, "w") as f:
                    f.write(content)

            # Copy multi-resolution icons to user icons folder
            for res in ["128x128", "256x256", "512x512"]:
                icon_src = os.path.join(base_dir, "icons", res, "apps", f"{APP_ID}.png")
                icon_dst_dir = os.path.join(home, ".local", "share", "icons", "hicolor", res, "apps")
                icon_dst = os.path.join(icon_dst_dir, f"{APP_ID}.png")
                if os.path.exists(icon_src) and not os.path.exists(icon_dst):
                    os.makedirs(icon_dst_dir, exist_ok=True)
                    shutil.copy2(icon_src, icon_dst)
        except Exception:
            pass


def main():
    app = ContrastCheckerApplication()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
