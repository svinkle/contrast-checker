# macOS Contrast Checker

A native macOS utility for measuring color contrast anywhere across your operating system—in native windows, virtual machines, browsers, and the desktop.

Designed to be lightweight, unobtrusive, and simple:

- **System-Wide Eyedropper**: Uses Apple's official `NSColorSampler` loupe to sample any pixel across your entire screen.
- **Global `Ctrl + Opt` Shortcuts**: Trigger the eyedropper for background or foreground colors, or toggle the app window from anywhere across macOS with zero browser conflicts.
- **Permanent Menu Bar Companion**: Lives in the menu bar with a target crosshair icon (`⌖`). Left-click to instantly toggle; right-click for quick actions.
- **Dynamic Dock Icon**: Appears in the Dock and `⌘Tab` app switcher when the window is visible, and completely disappears from the Dock when closed, running silently in the background.
- **Floating Utility Window**: Stays floating above all native windows and virtual machines while testing colors.
- **Instant WCAG 2.1 Calculation**: Computes exact contrast ratios from standardized sRGB relative luminance.
- **Contrast Ratio as Live Preview**: The contrast ratio text itself renders using the foreground color on the background color, providing an immediate real-world readability test.
- **One-Click Clipboard Copy**: Click the contrast ratio or either HEX code to copy the value directly to your clipboard, accompanied by an animated visual toast.
- **Installable DMG**: Pre-configured build script and Makefile to generate a compressed `.dmg` disk image with drag-and-drop `/Applications` installation.

---

## Interface Overview

```
+------------------------------------+
|                                [✕] |  <- Subtle close button (hides to menu bar)
|   21.00:1                          |  <- Live Contrast Ratio (Foreground on Background)
|   Contrast Ratio                   |     Click to copy ratio to clipboard
|                                    |
+------------------------------------+
|  ⌖  (●)  #000000       Background  |  <- Eyedropper, swatch circle, clickable HEX
| ---------------------------------- |
|  ⌖  (○)  #FFFFFF       Foreground  |  <- Eyedropper, swatch circle, clickable HEX
+------------------------------------+
```

- **Top Card Area**: Rendered in your selected Background Color (defaults to `#000000`). The Contrast Ratio is displayed prominently in your selected Foreground Color (defaults to `#FFFFFF`) and acts as the live sample text. Clicking the ratio copies it to the clipboard.
- **Background Row**:
  - `⌖` Eyedropper button: Activates the macOS magnifying loupe to sample any background pixel on your screen.
  - Circle swatch: Displays the current background color.
  - `#000000`: Click to copy the background HEX code.
- **Foreground Row**:
  - `⌖` Eyedropper button: Activates the macOS magnifying loupe to sample any foreground/text pixel on your screen.
  - Circle swatch: Displays the current foreground color.
  - `#FFFFFF`: Click to copy the foreground HEX code.
- **Menu Bar Status Item**: The target icon (`⌖`) remains in the macOS menu bar at all times:
  - **Left Click**: Toggles the window visibility (shows if hidden, hides if visible).
  - **Right Click** (or Control-click): Opens the context menu with quick actions, About dialog, and Quit.
- **Dynamic Dock Icon**: When the window is visible, the icon appears in the Dock and `⌘Tab` app switcher. When closed (`⌘W` or clicking `✕`), it completely disappears from the Dock while staying active in the menu bar.

---

## Keyboard Shortcuts

| Shortcut                   | Scope      | Action                                                                |
| :------------------------- | :--------- | :-------------------------------------------------------------------- |
| **`⌃⌥C` (Ctrl + Opt + C)** | **Global** | **Toggle show/hide Contrast Checker from anywhere**                   |
| **`⌃⌥B` (Ctrl + Opt + B)** | **Global** | **Pick Background color** (opens app if closed & triggers eyedropper) |
| **`⌃⌥F` (Ctrl + Opt + F)** | **Global** | **Pick Foreground color** (opens app if closed & triggers eyedropper) |
| `⌘W`                       | In-app     | Close window (hides to menu bar & removes Dock icon)                  |
| `⌘Q`                       | In-app     | Quit Contrast Checker completely                                      |

> [!TIP]
> **Click to Copy**: Click directly on the Contrast Ratio or either HEX code inside the app to copy the value to your clipboard with animated visual feedback.

---

## Building & Running

### Requirements

- macOS 13.0 or later
- Swift 5.9+ / Apple Command Line Tools

### Commands

```bash
# Build the application bundle (build/ContrastChecker.app)
make build

# Build the installable DMG disk image (build/ContrastChecker.dmg)
make dmg

# Run automated contrast & hex tests
make test

# Launch the app
make run

# Install directly to /Applications
make install
```

---

## macOS Screen Recording Permission

Because `ContrastChecker` uses Apple's native `NSColorSampler` to sample pixel colors from other applications and virtual machines, macOS may ask for Screen Recording permission on initial launch:

1. When prompted by macOS, click **Open System Settings**.
2. Alternatively, go to **System Settings > Privacy & Security > Screen & System Audio Recording** (or **Screen Recording** on earlier versions).
3. Enable the toggle next to **Contrast Checker**.
4. Relaunch the app.
