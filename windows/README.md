# Contrast Checker for Windows

A native Windows utility built with **C#**, **.NET 8**, and **WPF** for measuring color contrast anywhere across the operating system—including native windows, web browsers, and desktop wallpaper.

Built for accessibility testing, design system audits, and fast WCAG 2.2 compliance verification.

---

## Features

- **System-Wide Screen Color Sampling**: High-fidelity fullscreen overlay with a precision magnification loupe (zooming the pixel grid under the cursor with reticle crosshairs and live HEX/RGB readout).
- **Accurate WCAG 2.2 Contrast Calculation**: Computes sRGB relative luminance and contrast ratio ($1.00:1$ to $21.00:1$).
- **Minimalist Floating Card UI**: Compact 340px card with top background color preview, large contrast ratio sample text, and separate Background and Foreground pickers.
- **Global Shortcuts (Ctrl + Alt)**:
  - **`Ctrl + Alt + C`**: Toggle show/hide the Contrast Checker window from anywhere.
  - **`Ctrl + Alt + B`**: Immediately activate the Background color eyedropper loupe.
  - **`Ctrl + Alt + F`**: Immediately activate the Foreground color eyedropper loupe.
- **Window & App Shortcuts**:
  - **`Ctrl + W`** / **`Esc`**: Hide window to system tray (removes from taskbar, continues running in background).
  - **`Ctrl + Q`**: Quit application and terminate the process completely.
- **Permanent System Tray Companion**: Runs in the Windows Notification Area (System Tray) with right-click menu and single-click toggle. Hiding the window cleanly removes it from the taskbar while keeping it ready in the tray.
- **Single-File Self-Contained Executable**: Builds to a single portable `ContrastChecker.exe` with zero runtime dependencies.
- **MSI Installer**: Authoring via WiX Toolset v4/v5 (`ContrastChecker.msi`) with Start Menu and Desktop shortcuts.

---

## Installation

Pre-compiled downloads are available from the **[GitHub Releases](https://github.com/svinkle/contrast-checker/releases)** page:
- **`ContrastChecker.msi`**: Complete Windows installer with Start Menu and Desktop shortcuts.
- **`ContrastChecker.exe`**: Standalone portable executable with zero runtime dependencies.

> [!NOTE]
> **SmartScreen / Unknown Publisher Prompt**:  
> Because Contrast Checker is a free open-source project and is not signed with a commercial code-signing certificate, Windows Defender SmartScreen or User Account Control (UAC) may show a *"Windows protected your PC"* or *"Unknown Publisher"* prompt when launching the downloaded file.  
> - In SmartScreen: click **More info** &rarr; click **Run anyway**.  
> - In UAC: click **Yes** to proceed with installation.  
> - Alternatively, right-click the file &rarr; **Properties** &rarr; check **Unblock** at the bottom &rarr; click **OK**.

---

## Dependencies & Requirements

### Operating System

- **Windows 10 (version 1809 / Build 17763+)** or **Windows 11** (64-bit `win-x64`).

### Build & Development Tools

- **[.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)** (v8.0.100 or later): Provides the C# compiler, MSBuild, and NuGet restore. Verify via:
  ```powershell
  dotnet --version
  ```
- **PowerShell**: PowerShell 5.1 (bundled with Windows 10/11) or PowerShell 7+ for running `build.ps1`.
- **WiX Toolset v4 / v5** _(Optional, for packaging `.msi` installers)_:
  ```powershell
  dotnet tool install --global wix
  wix extension add WixToolset.UI.wixext
  ```
- **Python 3 + Pillow** _(Optional, only needed if regenerating `app.ico` from scratch)_:
  ```powershell
  pip install Pillow
  ```

### Runtime Dependencies

- **Zero Runtime Dependencies**: The default build script publishes a **self-contained, single-file executable** (`ContrastChecker.exe`). The .NET runtime and WPF libraries are embedded directly inside the binary. End users do **not** need the .NET runtime or any external frameworks installed.

### Native Frameworks & Windows APIs

- **WPF (`net8.0-windows`)**: Presentation framework for XAML UI, live data binding, and `:focus-visible` custom adorners.
- **Win32 User32 APIs**:
  - `RegisterHotKey` / `UnregisterHotKey`: Global shortcuts (`Ctrl+Alt+C`, `Ctrl+Alt+B`, `Ctrl+Alt+F`).
  - `SetWindowsHookEx` (`WH_MOUSE_LL`): Low-level mouse hook for tracking cursor position across all windows and displays during color sampling.
- **Win32 GDI32 APIs**:
  - `GetDC(IntPtr.Zero)`, `GetPixel`, `ReleaseDC`: Real-time desktop pixel color sampling across all connected monitors.
- **System Tray (`System.Windows.Forms.NotifyIcon`)**: Native notification area icon, right-click context menu, and background lifecycle management.

---

## Quick Start (Building on Windows)

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
│   │   └── ColorModel.cs                # WCAG 2.2 math & clipboard
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

---

## License

This project is licensed under the [MIT License](../LICENSE).
