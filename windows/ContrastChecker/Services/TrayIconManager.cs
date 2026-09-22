using System;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace ContrastChecker.Services
{
    public class TrayIconManager : IDisposable
    {
        private NotifyIcon? _notifyIcon;
        private bool _disposed;

        public event Action? ToggleRequested;
        public event Action? PickBackgroundRequested;
        public event Action? PickForegroundRequested;
        public event Action? AboutRequested;
        public event Action? ExitRequested;

        public void Initialize()
        {
            var contextMenu = new ContextMenuStrip();

            var toggleItem = new ToolStripMenuItem("Toggle Contrast Checker", null, (s, e) => ToggleRequested?.Invoke())
            {
                ShortcutKeyDisplayString = "Ctrl+Alt+C"
            };

            var pickBgItem = new ToolStripMenuItem("Pick Background Color", null, (s, e) => PickBackgroundRequested?.Invoke())
            {
                ShortcutKeyDisplayString = "Ctrl+Alt+B"
            };

            var pickFgItem = new ToolStripMenuItem("Pick Foreground Color", null, (s, e) => PickForegroundRequested?.Invoke())
            {
                ShortcutKeyDisplayString = "Ctrl+Alt+F"
            };

            var aboutItem = new ToolStripMenuItem("About Contrast Checker", null, (s, e) => AboutRequested?.Invoke());
            var exitItem = new ToolStripMenuItem("Exit", null, (s, e) => ExitRequested?.Invoke());

            contextMenu.Items.Add(toggleItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(pickBgItem);
            contextMenu.Items.Add(pickFgItem);
            contextMenu.Items.Add(new ToolStripSeparator());
            contextMenu.Items.Add(aboutItem);
            contextMenu.Items.Add(exitItem);

            _notifyIcon = new NotifyIcon
            {
                Text = "Contrast Checker",
                ContextMenuStrip = contextMenu,
                Visible = true
            };

            // Load app icon
            try
            {
                var iconPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "app.ico");
                if (File.Exists(iconPath))
                {
                    _notifyIcon.Icon = new Icon(iconPath);
                }
                else
                {
                    // Fallback to application icon
                    var exePath = Assembly.GetEntryAssembly()?.Location;
                    if (!string.IsNullOrEmpty(exePath) && File.Exists(exePath))
                    {
                        _notifyIcon.Icon = Icon.ExtractAssociatedIcon(exePath);
                    }
                }
            }
            catch
            {
                _notifyIcon.Icon = SystemIcons.Application;
            }

            // Left-click toggles app window
            _notifyIcon.MouseClick += (s, e) =>
            {
                if (e.Button == MouseButtons.Left)
                {
                    ToggleRequested?.Invoke();
                }
            };
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                _disposed = true;
                if (_notifyIcon != null)
                {
                    _notifyIcon.Visible = false;
                    _notifyIcon.Dispose();
                    _notifyIcon = null;
                }
            }
        }
    }
}
