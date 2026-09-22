using System;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;

namespace ContrastChecker.Services
{
    public class HotKeyManager : IDisposable
    {
        private const int WM_HOTKEY = 0x0312;

        private const uint MOD_ALT = 0x0001;
        private const uint MOD_CONTROL = 0x0002;
        private const uint MOD_NOREPEAT = 0x4000;

        private const uint VK_C = 0x43;
        private const uint VK_B = 0x42;
        private const uint VK_F = 0x46;

        public const int HOTKEY_TOGGLE = 1001;
        public const int HOTKEY_PICK_BG = 1002;
        public const int HOTKEY_PICK_FG = 1003;

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        private IntPtr _hWnd;
        private HwndSource? _source;
        private bool _disposed;

        public event Action? ToggleRequested;
        public event Action? PickBackgroundRequested;
        public event Action? PickForegroundRequested;

        public void Initialize(Window window)
        {
            var helper = new WindowInteropHelper(window);
            _hWnd = helper.EnsureHandle();

            _source = HwndSource.FromHwnd(_hWnd);
            _source?.AddHook(HwndHook);

            RegisterHotKeys();
        }

        private void RegisterHotKeys()
        {
            uint modifiers = MOD_CONTROL | MOD_ALT | MOD_NOREPEAT;

            // Ctrl + Alt + C: Toggle app
            RegisterHotKey(_hWnd, HOTKEY_TOGGLE, modifiers, VK_C);

            // Ctrl + Alt + B: Pick background color
            RegisterHotKey(_hWnd, HOTKEY_PICK_BG, modifiers, VK_B);

            // Ctrl + Alt + F: Pick foreground color
            RegisterHotKey(_hWnd, HOTKEY_PICK_FG, modifiers, VK_F);
        }

        private IntPtr HwndHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg == WM_HOTKEY)
            {
                int id = wParam.ToInt32();
                switch (id)
                {
                    case HOTKEY_TOGGLE:
                        ToggleRequested?.Invoke();
                        handled = true;
                        break;
                    case HOTKEY_PICK_BG:
                        PickBackgroundRequested?.Invoke();
                        handled = true;
                        break;
                    case HOTKEY_PICK_FG:
                        PickForegroundRequested?.Invoke();
                        handled = true;
                        break;
                }
            }
            return IntPtr.Zero;
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                _disposed = true;
                _source?.RemoveHook(HwndHook);

                UnregisterHotKey(_hWnd, HOTKEY_TOGGLE);
                UnregisterHotKey(_hWnd, HOTKEY_PICK_BG);
                UnregisterHotKey(_hWnd, HOTKEY_PICK_FG);
            }
        }
    }
}
