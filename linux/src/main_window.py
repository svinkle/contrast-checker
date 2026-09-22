"""
Main application window for Linux Contrast Checker using GTK 4.
Replicates the macOS floating card design and keyboard accessibility.
"""

from typing import Optional

try:
    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    from gi.repository import Gtk, Gdk, GLib, Pango
    HAS_GTK = True
except (ValueError, ImportError):
    HAS_GTK = False

from color_model import ColorModel
from color_sampler import PortalColorSampler


class MainWindow(Gtk.Window if HAS_GTK else object):
    def __init__(self, app: Optional["Gtk.Application"] = None, model: Optional[ColorModel] = None):
        if not HAS_GTK:
            self.model = model or ColorModel()
            return

        super().__init__(application=app, title="Contrast Checker")

        self.model = model or ColorModel()
        self.sampler = PortalColorSampler()
        self.toast_timer_id: Optional[int] = None

        # Window presentation
        self.set_default_size(340, 260)
        self.set_resizable(False)
        self.set_decorated(False)
        self.add_css_class("contrast-card")

        # Dynamic CSS Provider for live swatch colors
        self.dynamic_css = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            self.dynamic_css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1,
        )

        self._build_ui()
        self._setup_key_controller()

        # Connect model listener
        self.model.add_listener(self._on_model_changed)
        self._update_display()

    def _build_ui(self) -> None:
        # Window handle makes the entire card draggable
        handle = Gtk.WindowHandle()
        self.set_child(handle)

        # Root Overlay for floating toast notification
        self.overlay = Gtk.Overlay()
        handle.set_child(self.overlay)

        # Card Container Box
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        card_box.add_css_class("card-container")
        self.overlay.set_child(card_box)

        # =========================================================================
        # TOP REGION: Live Background Color Preview & Contrast Ratio
        # =========================================================================
        self.top_region = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.top_region.add_css_class("top-region")
        self.top_region.add_css_class("dynamic-top")
        card_box.append(self.top_region)

        # Top Header Bar (Close button in top-right)
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header_spacer = Gtk.Box()
        header_spacer.set_hexpand(True)
        header_box.append(header_spacer)

        self.close_btn = Gtk.Button()
        self.close_btn.add_css_class("close-button")
        self.close_btn.add_css_class("circle-focus")
        self.close_btn.set_tooltip_text("Close window (Esc / Ctrl+W)")
        self.close_btn.connect("clicked", lambda b: self.close())
        self.close_label = Gtk.Label(label="✕")
        self.close_btn.set_child(self.close_label)
        header_box.append(self.close_btn)
        self.top_region.append(header_box)

        # Top Center Box (Spacer before text)
        top_spacer1 = Gtk.Box()
        top_spacer1.set_vexpand(True)
        self.top_region.append(top_spacer1)

        # Contrast Ratio Clickable Button
        self.ratio_btn = Gtk.Button()
        self.ratio_btn.add_css_class("contrast-ratio-btn")
        self.ratio_btn.add_css_class("rect-focus")
        self.ratio_btn.set_tooltip_text("Click to copy contrast ratio")
        self.ratio_btn.connect("clicked", self._on_copy_ratio_clicked)

        self.ratio_label = Gtk.Label(label="21.00:1")
        self.ratio_label.add_css_class("contrast-ratio-text")
        self.ratio_label.set_halign(Gtk.Align.START)
        self.ratio_btn.set_child(self.ratio_label)
        self.top_region.append(self.ratio_btn)

        # Subtitle
        self.subtitle_label = Gtk.Label(label="Contrast Ratio")
        self.subtitle_label.add_css_class("contrast-ratio-subtitle")
        self.subtitle_label.set_halign(Gtk.Align.START)
        self.top_region.append(self.subtitle_label)

        top_spacer2 = Gtk.Box()
        top_spacer2.set_vexpand(True)
        self.top_region.append(top_spacer2)

        # =========================================================================
        # BOTTOM REGION: Pickers, Swatches, and Hex Readouts
        # =========================================================================
        self.bottom_region = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.bottom_region.add_css_class("bottom-region")
        card_box.append(self.bottom_region)

        # 1. Background Color Row
        bg_row = self._create_color_row(
            title="Background",
            is_background=True,
            on_pick=self._on_pick_background,
            on_copy=self._on_copy_bg_hex,
        )
        self.bottom_region.append(bg_row)

        # Subtle Divider Line
        divider = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        divider.add_css_class("row-divider")
        self.bottom_region.append(divider)

        # 2. Foreground Color Row
        fg_row = self._create_color_row(
            title="Foreground",
            is_background=False,
            on_pick=self._on_pick_foreground,
            on_copy=self._on_copy_fg_hex,
        )
        self.bottom_region.append(fg_row)

        # =========================================================================
        # TOAST NOTIFICATION OVERLAY
        # =========================================================================
        self.toast_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.toast_box.add_css_class("toast-overlay")
        self.toast_box.set_halign(Gtk.Align.CENTER)
        self.toast_box.set_valign(Gtk.Align.START)
        self.toast_box.set_margin_top(14)
        self.toast_box.set_visible(False)

        toast_check = Gtk.Label(label="✓")
        toast_check.add_css_class("toast-check")
        self.toast_box.append(toast_check)

        self.toast_label = Gtk.Label(label="Copied to clipboard")
        self.toast_label.add_css_class("toast-text")
        self.toast_box.append(self.toast_label)

        self.overlay.add_overlay(self.toast_box)

    def _create_color_row(
        self,
        title: str,
        is_background: bool,
        on_pick,
        on_copy,
    ) -> Gtk.Box:
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        # Eyedropper Button (Reticle Scope Icon)
        scope_btn = Gtk.Button()
        scope_btn.add_css_class("scope-button")
        scope_btn.add_css_class("circle-focus")
        scope_btn.set_tooltip_text(f"Pick {title.lower()} color from anywhere on screen")
        scope_btn.connect("clicked", lambda b: on_pick())

        # Scope Symbol
        scope_label = Gtk.Label(label="⌖")
        scope_label.set_valign(Gtk.Align.CENTER)
        scope_label.set_halign(Gtk.Align.CENTER)
        scope_btn.set_child(scope_label)
        row.append(scope_btn)

        # Color Swatch Circle
        swatch = Gtk.Box()
        swatch.add_css_class("color-swatch")
        if is_background:
            swatch.add_css_class("dynamic-bg-swatch")
            self.bg_swatch = swatch
        else:
            swatch.add_css_class("dynamic-fg-swatch")
            self.fg_swatch = swatch
        row.append(swatch)

        # Clickable HEX Code Button
        hex_btn = Gtk.Button()
        hex_btn.add_css_class("hex-button")
        hex_btn.add_css_class("rect-focus")
        hex_btn.set_tooltip_text(f"Click to copy {title.lower()} HEX")
        hex_btn.connect("clicked", lambda b: on_copy())

        hex_label = Gtk.Label(label="#000000" if is_background else "#FFFFFF")
        hex_label.add_css_class("hex-text")
        hex_btn.set_child(hex_label)
        if is_background:
            self.bg_hex_label = hex_label
        else:
            self.fg_hex_label = hex_label
        row.append(hex_btn)

        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        row.append(spacer)

        # Row Label
        name_label = Gtk.Label(label=title)
        name_label.add_css_class("row-label")
        row.append(name_label)

        return row

    def _setup_key_controller(self) -> None:
        controller = Gtk.EventControllerKey()
        controller.connect("key-pressed", self._on_key_pressed)
        self.add_controller(controller)

    def _on_key_pressed(self, controller, keyval, keycode, state) -> bool:
        ctrl = bool(state & Gdk.ModifierType.CONTROL_MASK)

        if keyval == Gdk.KEY_Escape or (ctrl and keyval in (Gdk.KEY_w, Gdk.KEY_W)):
            self.close()
            return True
        elif ctrl and keyval in (Gdk.KEY_q, Gdk.KEY_Q):
            app = self.get_application()
            if app:
                app.quit()
            else:
                self.close()
            return True
        return False

    def _on_model_changed(self) -> None:
        GLib.idle_add(self._update_display)

    def _update_display(self) -> None:
        if not HAS_GTK:
            return

        ratio_str = self.model.contrast_ratio_string
        bg_hex = self.model.bg_hex
        fg_hex = self.model.fg_hex

        # Update text labels with foreground color preview via Pango markup
        escaped_ratio = GLib.markup_escape_text(ratio_str)
        self.ratio_label.set_markup(f'<span foreground="{fg_hex}">{escaped_ratio}</span>')
        self.subtitle_label.set_markup(f'<span foreground="{fg_hex}">Contrast Ratio</span>')
        self.subtitle_label.set_opacity(0.75)
        self.close_label.set_markup(f'<span foreground="{fg_hex}">✕</span>')
        self.close_label.set_opacity(0.7)

        self.bg_hex_label.set_text(bg_hex)
        self.fg_hex_label.set_text(fg_hex)

        # Update dynamic styles
        css = f"""
        .dynamic-top {{
            background-color: {bg_hex};
        }}
        .contrast-ratio-btn,
        .contrast-ratio-btn:hover,
        .contrast-ratio-btn:active,
        .contrast-ratio-btn:focus,
        .contrast-ratio-btn label,
        .contrast-ratio-text {{
            color: {fg_hex};
        }}
        .contrast-ratio-subtitle {{
            color: {fg_hex};
        }}
        .close-button,
        .close-button:hover,
        .close-button label {{
            color: {fg_hex};
        }}
        .dynamic-bg-swatch {{
            background-color: {bg_hex};
        }}
        .dynamic-fg-swatch {{
            background-color: {fg_hex};
        }}
        """
        self.dynamic_css.load_from_data(css.encode("utf-8"))

        # Update toast feedback
        if self.model.copied_message:
            self.toast_label.set_text(self.model.copied_message)
            self.toast_box.set_visible(True)

            if self.toast_timer_id is not None:
                GLib.source_remove(self.toast_timer_id)

            self.toast_timer_id = GLib.timeout_add(1500, self._dismiss_toast)
        else:
            self.toast_box.set_visible(False)

    def _dismiss_toast(self) -> bool:
        self.toast_box.set_visible(False)
        self.toast_timer_id = None
        self.model.copied_message = None
        return False

    # Button Actions
    def _on_copy_ratio_clicked(self, button) -> None:
        self._copy_to_clipboard(self.model.contrast_ratio_string)
        self.model.copy_value(self.model.contrast_ratio_string, self.model.contrast_ratio_string)

    def _on_copy_bg_hex(self) -> None:
        self._copy_to_clipboard(self.model.bg_hex)
        self.model.copy_value(self.model.bg_hex, self.model.bg_hex)

    def _on_copy_fg_hex(self) -> None:
        self._copy_to_clipboard(self.model.fg_hex)
        self.model.copy_value(self.model.fg_hex, self.model.fg_hex)

    def _copy_to_clipboard(self, text: str) -> None:
        if not HAS_GTK:
            return
        display = Gdk.Display.get_default()
        if display:
            clipboard = display.get_clipboard()
            clipboard.set(text)

    def _on_pick_background(self) -> None:
        self.sampler.pick_color(
            on_success=lambda r, g, b: self._apply_bg_color(r, g, b),
        )

    def _on_pick_foreground(self) -> None:
        self.sampler.pick_color(
            on_success=lambda r, g, b: self._apply_fg_color(r, g, b),
        )

    def _apply_bg_color(self, r: int, g: int, b: int) -> None:
        self.model.set_background_color(r, g, b)
        self._copy_to_clipboard(self.model.bg_hex)
        self.model.copy_value(self.model.bg_hex, self.model.bg_hex)

    def _apply_fg_color(self, r: int, g: int, b: int) -> None:
        self.model.set_foreground_color(r, g, b)
        self._copy_to_clipboard(self.model.fg_hex)
        self.model.copy_value(self.model.fg_hex, self.model.fg_hex)

