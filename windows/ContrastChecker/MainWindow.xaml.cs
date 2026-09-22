using System;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Automation.Peers;
using System.Windows.Input;
using System.Windows.Media.Animation;
using ContrastChecker.Models;
using ContrastChecker.Services;
using ContrastChecker.Views;

namespace ContrastChecker
{
    public partial class MainWindow : Window
    {
        private readonly ColorModel _model;
        private readonly ScreenColorSampler _sampler;
        private readonly HotKeyManager _hotKeyManager;
        private readonly TrayIconManager _trayManager;
        private bool _isExplicitExit;

        public MainWindow()
        {
            InitializeComponent();

            _model = new ColorModel();
            _sampler = new ScreenColorSampler();
            _hotKeyManager = new HotKeyManager();
            _trayManager = new TrayIconManager();

            DataContext = _model;

            _model.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(_model.CopiedMessage))
                {
                    Dispatcher.Invoke(UpdateToast);
                }
            };

            Loaded += OnWindowLoaded;
            Closing += OnWindowClosing;
        }

        private void OnWindowLoaded(object sender, RoutedEventArgs e)
        {
            // Initialize Win32 Services
            _hotKeyManager.Initialize(this);
            _hotKeyManager.ToggleRequested += ToggleAppVisibility;
            _hotKeyManager.PickBackgroundRequested += PickBackground;
            _hotKeyManager.PickForegroundRequested += PickForeground;

            _trayManager.Initialize();
            _trayManager.ToggleRequested += ToggleAppVisibility;
            _trayManager.PickBackgroundRequested += PickBackground;
            _trayManager.PickForegroundRequested += PickForeground;
            _trayManager.AboutRequested += ShowAbout;
            _trayManager.ExitRequested += ExitApp;
        }

        private void OnWindowClosing(object? sender, System.ComponentModel.CancelEventArgs e)
        {
            if (!_isExplicitExit)
            {
                // Minimize/Hide to tray instead of quitting
                e.Cancel = true;
                HideApp();
            }
            else
            {
                _hotKeyManager.Dispose();
                _trayManager.Dispose();
            }
        }

        public void ShowApp()
        {
            Show();
            ShowInTaskbar = true;
            WindowState = WindowState.Normal;
            Activate();
            Focus();
        }

        public void HideApp()
        {
            Hide();
            ShowInTaskbar = false;
        }

        public void ToggleAppVisibility()
        {
            if (IsVisible && WindowState != WindowState.Minimized)
            {
                HideApp();
            }
            else
            {
                ShowApp();
            }
        }

        private void PickBackground()
        {
            if (!IsVisible)
            {
                ShowApp();
            }
            _sampler.PickBackgroundColor(_model);
        }

        private void PickForeground()
        {
            if (!IsVisible)
            {
                ShowApp();
            }
            _sampler.PickForegroundColor(_model);
        }

        private void ShowAbout()
        {
            var aboutWindow = new AboutWindow();
            aboutWindow.Owner = this;
            aboutWindow.ShowDialog();
        }

        public void ExitApp()
        {
            _isExplicitExit = true;
            Close();
            Application.Current.Shutdown();
        }

        private void UpdateToast()
        {
            if (!string.IsNullOrEmpty(_model.CopiedMessage))
            {
                ToastText.Text = _model.CopiedMessage;
                AutomationProperties.SetName(ToastText, _model.CopiedMessage);
                ToastBorder.Visibility = Visibility.Visible;

                // Raise UIA LiveRegionChanged event to announce out loud in Narrator, NVDA, JAWS
                var peer = UIElementAutomationPeer.FromElement(ToastText) ?? UIElementAutomationPeer.CreatePeerForElement(ToastText);
                peer?.RaiseAutomationEvent(AutomationEvents.LiveRegionChanged);
            }
            else
            {
                ToastBorder.Visibility = Visibility.Collapsed;
            }
        }

        // Window interaction event handlers

        private void OnWindowDrag(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed)
            {
                DragMove();
            }
        }

        private void OnCloseClicked(object sender, RoutedEventArgs e)
        {
            HideApp();
        }

        private void OnKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Escape || (e.Key == Key.W && (Keyboard.Modifiers & ModifierKeys.Control) == ModifierKeys.Control))
            {
                HideApp();
                e.Handled = true;
            }
        }

        private void OnCopyContrastRatioClicked(object sender, RoutedEventArgs e)
        {
            _model.CopyValue(_model.ContrastRatioString, _model.ContrastRatioString);
        }

        private void OnPickBackgroundClicked(object sender, RoutedEventArgs e)
        {
            PickBackground();
        }

        private void OnPickForegroundClicked(object sender, RoutedEventArgs e)
        {
            PickForeground();
        }

        private void OnCopyBackgroundHexClicked(object sender, RoutedEventArgs e)
        {
            _model.CopyValue(_model.BgHex, _model.BgHex);
        }

        private void OnCopyForegroundHexClicked(object sender, RoutedEventArgs e)
        {
            _model.CopyValue(_model.FgHex, _model.FgHex);
        }
    }
}

