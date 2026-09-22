# Contrast Checker

A minimalist, native utility for measuring color contrast anywhere across your operating system—including native windows, virtual machines, web browsers, and desktop wallpaper.

Built for accessibility testing, design system audits, and fast WCAG 2.1 compliance verification.

---

## Platforms

- **[macOS (`/macos`)](./macos)**: Native Swift, SwiftUI, and AppKit application. Features system-wide eyedropper (`NSColorSampler`), permanent menu bar companion, dynamic Dock icon hiding, and global system shortcuts (`⌃⌥C`, `⌃⌥B`, `⌃⌥F`).
- **Windows (`/windows`)**: _Planned_ (WinUI 3 / WPF with low-level mouse hook and `GetPixel` screen sampling).
- **Linux (`/linux`)**: _Planned_ (X11 / Wayland portal pixel picker).

---

## Quick Start (macOS)

For full documentation, shortcuts, and permissions, see the **[macOS README](./macos/README.md)**.

```bash
# Build the macOS application
make macos

# Run the test suite
make test

# Generate installable DMG
cd macos && make dmg
```
