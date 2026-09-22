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
    from gi.repository import Gtk, Gdk, Gio
    HAS_GTK = True
except (ValueError, ImportError):
    HAS_GTK = False

from color_model import ColorModel
from main_window import MainWindow


class ContrastCheckerApplication(Gtk.Application if HAS_GTK else object):
    APP_ID = "io.github.svinkle.ContrastChecker"

    def __init__(self):
        if not HAS_GTK:
            print("Error: GTK 4 or PyGObject is not available.", file=sys.stderr)
            sys.exit(1)

        super().__init__(
            application_id=self.APP_ID,
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.window = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
        self._load_styles()

    def do_activate(self):
        if not self.window:
            self.window = MainWindow(app=self)
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


def main():
    app = ContrastCheckerApplication()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
