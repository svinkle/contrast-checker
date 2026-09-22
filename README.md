# Contrast Checker

A minimalist, native utility for measuring color contrast anywhere across your operating system—including native windows, virtual machines, web browsers, and desktop wallpaper.

Built for accessibility testing, design system audits, and fast WCAG 2.1 compliance verification.

---

## Platforms

- **[macOS (`/macos`)](./macos)**: Native Swift, SwiftUI, and AppKit application. Features system-wide eyedropper (`NSColorSampler`), permanent menu bar companion, dynamic Dock icon hiding, and global system shortcuts (`⌃⌥C`, `⌃⌥B`, `⌃⌥F`).
- **[Windows (`/windows`)](./windows)**: Native C#, .NET 8, and WPF application. Features fullscreen magnification loupe eyedropper, permanent system tray companion, standalone single-file `.exe`, WiX `.msi` installer, and global shortcuts (`Ctrl+Alt+C`, `Ctrl+Alt+B`, `Ctrl+Alt+F`).
- **Linux (`/linux`)**: _Planned_ (Flatpak package, X11 / Wayland portal pixel picker).

---

## Quick Start

### macOS
For full documentation, shortcuts, and permissions, see the **[macOS README](./macos/README.md)**.

```bash
# Build the macOS application
make macos

# Run the test suite
make test

# Generate installable DMG
cd macos && make dmg
```

### Windows
For full documentation, shortcuts, and installer details, see the **[Windows README](./windows/README.md)**.

```powershell
# Build self-contained single-file ContrastChecker.exe
powershell -ExecutionPolicy Bypass -File windows/build.ps1

# Build installable ContrastChecker.msi (via WiX)
powershell -ExecutionPolicy Bypass -File windows/build.ps1 -BuildMsi
```
