# Contrast Checker for Windows

A native Windows utility built with **C#**, **.NET 8**, and **WPF** for measuring color contrast anywhere across the operating system—including native windows, web browsers, and desktop wallpaper.

Built for accessibility testing, design system audits, and fast WCAG 2.1 compliance verification.

---

## Features

- **System-Wide Screen Color Sampling**: High-fidelity fullscreen overlay with a precision magnification loupe (zooming the pixel grid under the cursor with reticle crosshairs and live HEX/RGB readout).
- **Accurate WCAG 2.1 Contrast Calculation**: Computes sRGB relative luminance and contrast ratio ($1.00:1$ to $21.00:1$).
- **Minimalist Floating Card UI**: Compact 340px card with top background color preview, large contrast ratio sample text, and separate Background and Foreground pickers.
- **Global Shortcuts (Ctrl + Alt)**:
  - **`Ctrl + Alt + C`**: Toggle show/hide the Contrast Checker window from anywhere.
  - **`Ctrl + Alt + B`**: Immediately activate the Background color eyedropper loupe.
  - **`Ctrl + Alt + F`**: Immediately activate the Foreground color eyedropper loupe.
- **Permanent System Tray Companion**: Runs in the Windows Notification Area (System Tray) with right-click menu and single-click toggle. Hiding the window cleanly removes it from the taskbar while keeping it ready in the tray.
- **Single-File Self-Contained Executable**: Builds to a single portable `ContrastChecker.exe` with zero runtime dependencies.
- **MSI Installer**: Authoring via WiX Toolset v4/v5 (`ContrastChecker.msi`) with Start Menu and Desktop shortcuts.

---

## Quick Start (Building on Windows)

### Prerequisites

- Windows 10 (version 1809+) or Windows 11
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)

### 1. Build Standalone `.exe`

```powershell
# Build self-contained single-file executable to windows\build\ContrastChecker.exe
powershell -ExecutionPolicy Bypass -File build.ps1
```

Or using batch:

```cmd
build.bat
```

### 2. Build `.msi` Installer

```powershell
# Publishes executable and packages ContrastChecker.msi via WiX Toolset
powershell -ExecutionPolicy Bypass -File build.ps1 -BuildMsi
```

### 3. Run Unit Tests

```bash
dotnet test ContrastChecker.Tests/ContrastChecker.Tests.csproj
```

---

## Eyedropper Screen Sampling

When the eyedropper is activated (via button or shortcut):

- **Move Cursor**: The cursor becomes a precision crosshair across the entire OS. As you move your mouse over any app, website, or desktop wallpaper, the Contrast Checker swatch and HEX code update in real-time.
- **Left-Click**: Confirms and selects the color directly under the cursor.
- **Right-Click** or **Esc**: Cancels and restores previous color.

---

## Project Structure

```
windows/
├── ContrastChecker.sln                  # Visual Studio / dotnet Solution
├── README.md                            # Documentation
├── Makefile                             # Make wrapper
├── build.ps1                            # PowerShell build script
├── build.bat                            # Batch build launcher
├── ContrastChecker/                     # Main Application (WPF / .NET 8)
│   ├── ContrastChecker.csproj
│   ├── App.xaml / App.xaml.cs
│   ├── MainWindow.xaml / MainWindow.xaml.cs
│   ├── Models/
│   │   └── ColorModel.cs                # WCAG 2.1 math & clipboard
│   ├── Services/
│   │   ├── HotKeyManager.cs             # Global Win32 shortcuts
│   │   ├── ScreenColorSampler.cs        # Global mouse hook & pixel sampling
│   │   └── TrayIconManager.cs           # System tray NotifyIcon & menu
│   ├── Views/
│   │   └── AboutWindow.xaml             # About dialog & shortcuts
│   └── Resources/
│       ├── app.ico                      # Multi-size Windows icon
│       └── app.png                      # High-res master icon
├── ContrastChecker.Installer/           # WiX Toolset MSI Project
│   ├── Package.wxs                      # Installer definition
│   └── ContrastChecker.Installer.wixproj
├── ContrastChecker.Tests/               # Unit Tests (xUnit)
│   ├── ContrastChecker.Tests.csproj
│   └── ColorModelTests.cs
└── scripts/
    └── generate_ico.py                  # Icon generator (Python Pillow)
```
