# Contrast Checker for Linux

A native Linux utility for measuring color contrast anywhere across your operating system (including native windows, web browsers, and desktop wallpaper).

Packaged as a universal **Flatpak** for seamless installation across all Linux distributions (Ubuntu, Fedora, Arch, Debian, openSUSE, SteamOS, etc.).

Pre-compiled Flatpak bundles are automatically built and published on the **[GitHub Releases](https://github.com/svinkle/contrast-checker/releases)** page for both architectures:
- **`ContrastChecker-x86_64.flatpak`**: For 64-bit Intel and AMD systems.
- **`ContrastChecker-aarch64.flatpak`**: For 64-bit ARM systems (including Linux inside Apple Silicon virtual machines).

```bash
# Install x86_64:
flatpak install --user ContrastChecker-x86_64.flatpak

# Install ARM64 (Apple Silicon VM):
flatpak install --user ContrastChecker-aarch64.flatpak
```

---

## Features

- **Floating Card UI**: Compact 340×260px floating card with crisp squared corners, live top Background swatch preview with dynamic Foreground sample text, large contrast ratio readout, and subtle corner close button (`✕`).
- **WCAG 2.2 Conformance**: Precise relative luminance and contrast ratio calculations identical to macOS and Windows versions.
- **Universal Multi-Desktop Color Sampling**:
  - **Wayland (GNOME, KDE Plasma)**: Uses the FreeDesktop XDG Desktop Portal (`org.freedesktop.portal.Screenshot.PickColor`) to invoke the compositor's native loupe eyedropper.
  - **X11 (XFCE, MATE, Cinnamon)**: Direct native screen sampling with crosshair cursor via `libX11.so.6` (standard library `ctypes`, zero external pip dependencies).
- **Full Keyboard Navigation**:
  - `Ctrl + Alt + B` (or `Alt + B` / `Ctrl + B`): Pick Background color.
  - `Ctrl + Alt + F` (or `Alt + F` / `Ctrl + F`): Pick Foreground color.
  - `Ctrl + W` / `Esc`: Close and exit application cleanly.
  - `Ctrl + Q`: Quit application completely.
  - `Tab` / `Shift + Tab`: Accessible dual-layer focus outline.
- **Universal Window Dragging**: Draggable across both modern Wayland compositors and traditional X11 window managers (XFWM4, Marco, Muffin, KWin).
- **Desktop & Dock Integration**: FreeDesktop desktop launcher, high-resolution app icons across all standard sizes (`16x16` up to `512x512`), and dock right-click context menu actions ("Pick Background Color", "Pick Foreground Color").
- **Clipboard & Transient Toast**: One-click copying of HEX values and contrast ratio with a floating checkmark toast banner.

---

## Keyboard Shortcuts

| Shortcut                            | Scope             | Action                                                 |
| :---------------------------------- | :---------------- | :----------------------------------------------------- |
| **`Ctrl + Alt + B`** (or `Alt + B`) | In-app / Global\* | **Pick Background color** (triggers screen eyedropper) |
| **`Ctrl + Alt + F`** (or `Alt + F`) | In-app / Global\* | **Pick Foreground color** (triggers screen eyedropper) |
| **`Ctrl + W`** / **`Esc`**          | In-app            | Close / hide window                                    |
| **`Ctrl + Q`**                      | In-app            | Quit Contrast Checker completely                       |

> [!TIP]
> **System-Wide Global Shortcuts**:
> The Linux application supports DBus command-line actions (`--pick-bg`, `--pick-fg`). To trigger color picking from anywhere across your system even when the window is hidden, add custom shortcuts in **Ubuntu Settings > Keyboard > Keyboard Shortcuts > View and Customize Shortcuts > Custom Shortcuts**:
>
> - `Ctrl + Alt + B`: `contrast-checker --pick-bg` (or `flatpak run io.github.svinkle.ContrastChecker --pick-bg`)
> - `Ctrl + Alt + F`: `contrast-checker --pick-fg` (or `flatpak run io.github.svinkle.ContrastChecker --pick-fg`)

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
# Run application directly from source
make run

# Optional: Register desktop menu launcher and icons in ~/.local/share
make install-user

# Cleanly remove local user desktop launcher and icons
make uninstall-user
```

> [!TIP]
> **Switching from Source Development to Flatpak**:  
> If you previously ran from source or ran `make install-user`, your user directory may contain a local desktop launcher in `~/.local/share/applications/`. To ensure your desktop environment (XFCE, GNOME, KDE) launches the official Flatpak rather than the development source path, run:
> ```bash
> rm -f ~/.local/share/applications/io.github.svinkle.ContrastChecker.desktop
> update-desktop-database ~/.local/share/applications
> ```

---

## Running Unit Tests

```bash
make test
```

---

## License

This project is licensed under the [MIT License](../LICENSE).

