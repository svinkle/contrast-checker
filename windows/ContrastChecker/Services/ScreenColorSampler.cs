using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using ContrastChecker.Models;

namespace ContrastChecker.Services
{
    public class ScreenColorSampler : IDisposable
    {
        private const int WH_MOUSE_LL = 14;
        private const int WH_KEYBOARD_LL = 13;

        private const int WM_MOUSEMOVE = 0x0200;
        private const int WM_LBUTTONDOWN = 0x0201;
        private const int WM_RBUTTONDOWN = 0x0204;
        private const int WM_KEYDOWN = 0x0100;
        private const int VK_ESCAPE = 0x1B;

        private const uint SPI_SETCURSORS = 0x0057;
        private const uint OCR_NORMAL = 32512;
        private const uint OCR_IBEAM = 32513;
        private const uint OCR_HAND = 32649;
        private const int IDC_CROSS = 32515;

        [StructLayout(LayoutKind.Sequential)]
        private struct POINT
        {
            public int x;
            public int y;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MSLLHOOKSTRUCT
        {
            public POINT pt;
            public uint mouseData;
            public uint flags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        private delegate IntPtr LowLevelProc(int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string? lpModuleName);

        [DllImport("user32.dll")]
        private static extern IntPtr GetDC(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

        [DllImport("gdi32.dll")]
        private static extern uint GetPixel(IntPtr hdc, int nXPos, int nYPos);

        [DllImport("user32.dll")]
        private static extern bool GetCursorPos(out POINT lpPoint);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SetSystemCursor(IntPtr hcur, uint id);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

        [DllImport("user32.dll")]
        private static extern IntPtr LoadCursor(IntPtr hInstance, int lpCursorName);

        [DllImport("user32.dll")]
        private static extern IntPtr CopyIcon(IntPtr hIcon);

        private IntPtr _mouseHook = IntPtr.Zero;
        private IntPtr _keyboardHook = IntPtr.Zero;
        private LowLevelProc? _mouseProc;
        private LowLevelProc? _keyboardProc;

        private bool _isPicking;
        private bool _systemCursorReplaced;
        private Color _currentHoverColor;
        private Action<Color>? _onHover;
        private Action<Color>? _onSelected;
        private Action? _onCancelled;

        public bool IsPicking => _isPicking;

        public ScreenColorSampler()
        {
            AppDomain.CurrentDomain.ProcessExit += (s, e) => RestoreGlobalCursor();
        }

        private void EnableGlobalCrosshair()
        {
            try
            {
                IntPtr hCross = LoadCursor(IntPtr.Zero, IDC_CROSS);
                if (hCross != IntPtr.Zero)
                {
                    // SetSystemCursor takes ownership and destroys the cursor passed to it,
                    // so we must pass a copy via CopyIcon for each cursor slot.
                    SetSystemCursor(CopyIcon(hCross), OCR_NORMAL);
                    SetSystemCursor(CopyIcon(hCross), OCR_IBEAM);
                    SetSystemCursor(CopyIcon(hCross), OCR_HAND);
                    _systemCursorReplaced = true;
                }
            }
            catch
            {
                // Fallback to WPF OverrideCursor
            }

            Application.Current?.Dispatcher?.Invoke(() =>
            {
                Mouse.OverrideCursor = Cursors.Cross;
            });
        }

        private void RestoreGlobalCursor()
        {
            if (_systemCursorReplaced)
            {
                _systemCursorReplaced = false;
                try
                {
                    SystemParametersInfo(SPI_SETCURSORS, 0, IntPtr.Zero, 0);
                }
                catch
                {
                }
            }

            Application.Current?.Dispatcher?.Invoke(() =>
            {
                Mouse.OverrideCursor = null;
            });
        }

        public void PickBackgroundColor(ColorModel model)
        {
            if (_isPicking)
                return;

            Color originalColor = model.BackgroundColor;

            StartPicking(
                onHover: color =>
                {
                    model.SetBackgroundColor(color);
                },
                onSelected: color =>
                {
                    model.SetBackgroundColor(color);
                    model.CopyValue(model.BgHex, model.BgHex);
                },
                onCancelled: () =>
                {
                    model.SetBackgroundColor(originalColor);
                }
            );
        }

        public void PickForegroundColor(ColorModel model)
        {
            if (_isPicking)
                return;

            Color originalColor = model.ForegroundColor;

            StartPicking(
                onHover: color =>
                {
                    model.SetForegroundColor(color);
                },
                onSelected: color =>
                {
                    model.SetForegroundColor(color);
                    model.CopyValue(model.FgHex, model.FgHex);
                },
                onCancelled: () =>
                {
                    model.SetForegroundColor(originalColor);
                }
            );
        }

        public void StartPicking(Action<Color> onHover, Action<Color> onSelected, Action onCancelled)
        {
            if (_isPicking)
                StopPicking();

            _isPicking = true;
            _onHover = onHover;
            _onSelected = onSelected;
            _onCancelled = onCancelled;

            // Change cursor to Crosshair globally across the operating system
            EnableGlobalCrosshair();

            // Sample initial pixel under cursor
            if (GetCursorPos(out POINT initialPt))
            {
                SamplePixelAt(initialPt.x, initialPt.y);
            }

            _mouseProc = MouseHookCallback;
            _keyboardProc = KeyboardHookCallback;

            using (var curProcess = Process.GetCurrentProcess())
            using (var curModule = curProcess.MainModule)
            {
                IntPtr hMod = GetModuleHandle(curModule?.ModuleName);
                _mouseHook = SetWindowsHookEx(WH_MOUSE_LL, _mouseProc, hMod, 0);
                _keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, _keyboardProc, hMod, 0);
            }
        }

        public void StopPicking()
        {
            if (!_isPicking)
                return;

            _isPicking = false;

            if (_mouseHook != IntPtr.Zero)
            {
                UnhookWindowsHookEx(_mouseHook);
                _mouseHook = IntPtr.Zero;
            }

            if (_keyboardHook != IntPtr.Zero)
            {
                UnhookWindowsHookEx(_keyboardHook);
                _keyboardHook = IntPtr.Zero;
            }

            _mouseProc = null;
            _keyboardProc = null;

            RestoreGlobalCursor();
        }

        private IntPtr MouseHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && _isPicking)
            {
                int msg = wParam.ToInt32();

                if (msg == WM_MOUSEMOVE)
                {
                    var hookStruct = Marshal.PtrToStructure<MSLLHOOKSTRUCT>(lParam);
                    SamplePixelAt(hookStruct.pt.x, hookStruct.pt.y);
                }
                else if (msg == WM_LBUTTONDOWN)
                {
                    // Selection confirmed!
                    var selected = _currentHoverColor;
                    var onSelected = _onSelected;

                    StopPicking();

                    Application.Current?.Dispatcher?.Invoke(() =>
                    {
                        onSelected?.Invoke(selected);
                    });

                    // Swallow click event so other apps don't receive it
                    return (IntPtr)1;
                }
                else if (msg == WM_RBUTTONDOWN)
                {
                    // Cancelled via right click
                    var onCancelled = _onCancelled;

                    StopPicking();

                    Application.Current?.Dispatcher?.Invoke(() =>
                    {
                        onCancelled?.Invoke();
                    });

                    return (IntPtr)1;
                }
            }

            return CallNextHookEx(_mouseHook, nCode, wParam, lParam);
        }

        private IntPtr KeyboardHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && _isPicking)
            {
                int msg = wParam.ToInt32();
                if (msg == WM_KEYDOWN)
                {
                    int vkCode = Marshal.ReadInt32(lParam);
                    if (vkCode == VK_ESCAPE)
                    {
                        // Cancelled via Escape key
                        var onCancelled = _onCancelled;

                        StopPicking();

                        Application.Current?.Dispatcher?.Invoke(() =>
                        {
                            onCancelled?.Invoke();
                        });

                        return (IntPtr)1;
                    }
                }
            }

            return CallNextHookEx(_keyboardHook, nCode, wParam, lParam);
        }

        private void SamplePixelAt(int x, int y)
        {
            IntPtr hdc = GetDC(IntPtr.Zero);
            if (hdc != IntPtr.Zero)
            {
                uint pixel = GetPixel(hdc, x, y);
                ReleaseDC(IntPtr.Zero, hdc);

                if (pixel != 0xFFFFFFFF) // CLR_INVALID
                {
                    byte r = (byte)(pixel & 0xFF);
                    byte g = (byte)((pixel >> 8) & 0xFF);
                    byte b = (byte)((pixel >> 16) & 0xFF);

                    var color = Color.FromRgb(r, g, b);
                    _currentHoverColor = color;

                    Application.Current?.Dispatcher?.Invoke(() =>
                    {
                        _onHover?.Invoke(color);
                    });
                }
            }
        }

        public void Dispose()
        {
            StopPicking();
        }
    }
}
