# Contrast Checker for Linux

A native Linux utility for measuring color contrast anywhere across your operating system (including native windows, web browsers, and desktop wallpaper).

Packaged as a universal **Flatpak** for seamless installation across all Linux distributions (Ubuntu, Fedora, Arch, Debian, openSUSE, SteamOS, etc.).

---

## Features

- **macOS Floating Card Parity**: Compact 340×260px floating card with 18px continuous rounded corners, live top Background swatch preview, large contrast ratio readout, and subtle corner close button (`✕`).
- **WCAG 2.1 Conformance**: Precise relative luminance and contrast ratio calculations identical to macOS and Windows versions.
- **System-Wide Screen Color Sampling**: Uses the **XDG Desktop Portal** (`org.freedesktop.portal.Screenshot.PickColor`) over DBus to invoke the system's native magnification loupe on both **Wayland** (GNOME, KDE Plasma, Sway, Hyprland) and **X11**.
- **Accessible Keyboard Navigation**:
  - `Tab` / `Shift+Tab` moves focus across controls.
  - Buttons feature high-contrast visible focus rings strictly when navigating via keyboard (`:focus-visible`).
  - `Enter` and `Space` activate focused buttons.
  - `Esc` or `Ctrl+W` closes/hides the window; `Ctrl+Q` quits the application.
- **Clipboard & Transient Toast**: One-click copying of HEX values and contrast ratio with a floating checkmark toast banner.

---

## Flatpak Building & Packaging

### Prerequisites

Install `flatpak` and `flatpak-builder`:

```bash
# Ubuntu / Debian
sudo apt install flatpak flatpak-builder

# Fedora
sudo dnf install flatpak flatpak-builder

# Arch Linux
sudo pacman -S flatpak flatpak-builder
```

Add the Flathub repository:

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Install the GNOME 46 runtime and SDK:

```bash
flatpak install flathub org.gnome.Platform//46 org.gnome.Sdk//46
```

### Build & Run Locally

```bash
# Build the Flatpak in a local build directory
make flatpak

# Run the built Flatpak
flatpak-builder --run build-dir io.github.svinkle.ContrastChecker.yml contrast-checker

# Or export a standalone single-file .flatpak bundle
make bundle
```

### Install the .flatpak Bundle

```bash
flatpak install --user ContrastChecker.flatpak
```

---

## Running Unit Tests

```bash
make test
```
