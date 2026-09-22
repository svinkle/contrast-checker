# Contrast Checker for Linux

A native Linux utility for measuring color contrast anywhere across your operating system (including native windows, web browsers, and desktop wallpaper).

Packaged as a universal **Flatpak** for seamless installation across all Linux distributions (Ubuntu, Fedora, Arch, Debian, openSUSE, SteamOS, etc.).

---

## Features

- **Floating Card UI**: Compact 340×260px floating card with crisp squared corners, live top Background swatch preview with dynamic Foreground sample text, large contrast ratio readout, and subtle corner close button (`✕`).
- **WCAG 2.1 Conformance**: Precise relative luminance and contrast ratio calculations identical to macOS and Windows versions.
- **System-Wide Screen Color Sampling**: Uses the **XDG Desktop Portal** (`org.freedesktop.portal.Screenshot.PickColor`) over DBus to invoke the system's native magnification loupe on both **Wayland** (GNOME, KDE Plasma, Sway, Hyprland) and **X11**.
- **Accessible Keyboard Navigation**:
  - `Tab` / `Shift+Tab` moves focus across controls.
  - Buttons feature high-contrast visible focus rings strictly when navigating via keyboard (`:focus-visible`).
  - `Enter` and `Space` activate focused buttons.
  - `Esc` or `Ctrl+W` closes/hides the window; `Ctrl+Q` quits the application.
- **Clipboard & Transient Toast**: One-click copying of HEX values and contrast ratio with a floating checkmark toast banner.

---

## Dependencies & Requirements

### Operating System & Environments
- **Linux Distribution**: Any modern Linux distribution (Ubuntu 22.04+, Debian 12+, Fedora 38+, Arch Linux, openSUSE, SteamOS, etc.).
- **Architecture**: `x86_64` (AMD/Intel) and `aarch64` (ARM64, including Linux inside Apple Silicon virtual machines).
- **Display Server**: Native **Wayland** (GNOME Shell, KDE Plasma, Sway, Hyprland) and **X11**.

### System Services & Permissions
- **XDG Desktop Portal (`xdg-desktop-portal`)**: Required for sandboxed, system-wide screen color sampling (`org.freedesktop.portal.Screenshot.PickColor` over DBus).
  - Standard on modern Linux desktop environments.
  - Backends: `xdg-desktop-portal-gnome` (GNOME), `xdg-desktop-portal-kde` (KDE), or `xdg-desktop-portal-wlr` / `xdg-desktop-portal-gtk` (Sway / Hyprland / wlroots).
- **DBus Session Daemon**: Standard user session bus (`dbus-user-session`).

---

### Option A: Flatpak Build Dependencies (Recommended)

Building and packaging the application as a standalone `.flatpak` bundle requires `flatpak`, `flatpak-builder`, and the official GNOME 46 runtime:

#### 1. Install Flatpak Tools

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y flatpak flatpak-builder

# Fedora
sudo dnf install -y flatpak flatpak-builder

# Arch Linux
sudo pacman -S --needed flatpak flatpak-builder

# openSUSE
sudo zypper install flatpak flatpak-builder
```

#### 2. Configure Flathub & Install GNOME 46 Runtimes

```bash
# Add Flathub remote to your user configuration
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user update --appstream

# Install GNOME 46 Platform and SDK
flatpak install -y flathub org.gnome.Platform//46 org.gnome.Sdk//46
```

---

### Option B: Native Host Execution Dependencies (Fast Local Testing)

If you wish to run the app directly on your host machine without compiling a Flatpak container:

- **Python 3.10+**: Standard library only (no external pip dependencies).
- **GTK 4 & PyGObject**:

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y python3 python3-gi python3-gi-cairo gir1.2-gtk-4.0

# Fedora
sudo dnf install -y python3 python3-gobject gtk4

# Arch Linux
sudo pacman -S --needed python python-gobject gtk4

# openSUSE
sudo zypper install python3 python3-gobject gtk4 typelib-1_0-Gtk-4_0
```

---

## Building & Running

### Option 1: Build & Run via Flatpak

```bash
# Build the Flatpak in a local build directory
make flatpak

# Run the built Flatpak
flatpak-builder --run build-dir io.github.svinkle.ContrastChecker.yml contrast-checker

# Or export a standalone single-file .flatpak bundle
make bundle

# Install the .flatpak bundle to your user account
flatpak install --user ContrastChecker.flatpak
```

### Option 2: Run Directly on Host

If you have installed the native GTK 4 & PyGObject dependencies (Option B above):

```bash
make run
```

---

## Running Unit Tests

```bash
make test
```
