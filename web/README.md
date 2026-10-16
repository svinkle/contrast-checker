# 🌐 Contrast Checker for Web & Chromebook (PWA)

An installable **Progressive Web App (PWA)** for measuring WCAG 2.2 color contrast anywhere across your screen—built specifically for **💻 ChromeOS (Chromebook)** and desktop Chromium browsers with zero external dependencies.

Hosted on **GitHub Pages** for instant browser access and one-click installation:

- **Launch / Install Web App**: **[`https://svinkle.github.io/contrast-checker/`](https://svinkle.github.io/contrast-checker/)**

---

## Features

- **System-Wide Screen Color Sampling on ChromeOS**:
  - Uses the native Chromium **[`EyeDropper` API](https://developer.mozilla.org/en-US/docs/Web/API/EyeDropper_API)** (`new EyeDropper().open()`) to invoke the system magnifying loupe.
  - Sample pixels anywhere on your Chromebook screen—outside the browser tab, across other windows, Linux/Android apps, the ChromeOS shelf, and desktop wallpaper.
  - Automatically falls back to the native `<input type="color">` picker on browsers that do not yet implement `EyeDropper` (Firefox, Safari), and clicking either color swatch circle opens the color picker directly.
- **Installable Offline-First PWA**:
  - Includes a complete Web App Manifest ([`manifest.webmanifest`](./manifest.webmanifest)) with standard (`16x16` to `512x512`), maskable (`192x192`, `512x512`), and vector SVG icons, plus shelf right-click shortcuts (*"Pick Background Color"*, *"Pick Foreground Color"*).
  - Pre-caches all application shell assets via a Service Worker ([`sw.js`](./sw.js)) so the app launches instantaneously offline from the ChromeOS Launcher or Shelf.
- **Integrated Native Window UI**:
  - Seamlessly blends into the ChromeOS window without artificial borders, rounded corners, or drop shadows.
  - The dynamic Background color preview spans full-width across the top of the window, with the Contrast Ratio readout anchored in the top-left.
  - Leaves window sizing and visibility control to the native ChromeOS window controls (minimize, maximize, snap, and close).
- **WCAG 2.2 Conformance**:
  - Exact relative luminance and contrast ratio calculations matching the native desktop implementations (`21.00:1` to `1.00:1`).
- **Full Keyboard Navigation & Clipboard Support**:
  - High-contrast dual-layer focus ring (`:focus-visible`) for `Tab` / `Shift + Tab` navigation.
  - One-click copying of Contrast Ratio and HEX values with a floating checkmark toast notification (`✓ Copied #000000`).
  - Paste any 3-digit (`#RGB`) or 6-digit (`#RRGGBB`) HEX string directly into the app (`Ctrl + V` / `⌘V`).

---

## Installing on a Chromebook (ChromeOS)

1. Open **[`https://svinkle.github.io/contrast-checker/`](https://svinkle.github.io/contrast-checker/)** in **Google Chrome** on your Chromebook.
2. Click the **Install Contrast Checker** icon in the right side of the address bar (or click the **Install App** pill).
3. Click **Install** in the prompt.
4. Contrast Checker will open in its own standalone window. Right-click its icon in the ChromeOS Shelf and select **Pin** for one-click access (or press `Alt + [1–9]` to summon it from the shelf at any time).

---

## Keyboard Shortcuts

| Shortcut                            | Action                                                            |
| :---------------------------------- | :---------------------------------------------------------------- |
| **`Alt + B`** / **`Ctrl + Alt + B`** | **Pick Background color** (opens system-wide screen eyedropper)   |
| **`Alt + F`** / **`Ctrl + Alt + F`** | **Pick Foreground color** (opens system-wide screen eyedropper)   |
| **`Tab`** / **`Shift + Tab`**       | Navigate between interactive controls with high-contrast outline  |
| **`Enter`** / **`Space`**           | Activate focused picker or copy focused value to clipboard        |
| **`Ctrl + V`** / **`⌘V`**           | Paste a HEX color code from clipboard                             |
| **`Esc`**                           | Cancel active eyedropper or clear control focus                   |

---

## Local Development & Testing

The Web / PWA implementation uses standard HTML5, CSS3, and vanilla JavaScript with zero npm runtime dependencies.

### Run Local Development Server

```bash
# From the repository root:
make web

# Or from the /web directory:
make serve
# Opens at http://localhost:8000
```

### Run Automated Unit Tests

```bash
# From the repository root:
make test-web

# Or from the /web directory:
make test
```

### Regenerate PWA Icons

```bash
make -C web icons
```

---

## Deploying to GitHub Pages

A GitHub Actions workflow ([`.github/workflows/web.yml`](../.github/workflows/web.yml)) automatically runs unit tests and deploys the `/web` directory to GitHub Pages on pushes to `main`.

To enable GitHub Pages in your repository settings:
1. Go to **Settings > Pages** in the GitHub repository.
2. Under **Build and deployment > Source**, select **GitHub Actions**.

---

## License

This project is licensed under the [MIT License](../LICENSE).
