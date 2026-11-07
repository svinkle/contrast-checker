using System;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Automation.Peers;
using System.Windows.Controls;
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
        private string _bgInitialHex = "#000000";
        private string _fgInitialHex = "#FFFFFF";
        private bool _bgEditFinished;
        private bool _fgEditFinished;

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
                _sampler.Dispose();
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
            if (BgHexTextBox.Visibility == Visibility.Visible && !BgHexTextBox.IsMouseOver)
            {
                CommitBgHexEdit();
            }
            if (FgHexTextBox.Visibility == Visibility.Visible && !FgHexTextBox.IsMouseOver)
            {
                CommitFgHexEdit();
            }
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
            if (Keyboard.FocusedElement is TextBox)
            {
                return;
            }

            var ctrl = (Keyboard.Modifiers & ModifierKeys.Control) == ModifierKeys.Control;
            var alt = (Keyboard.Modifiers & ModifierKeys.Alt) == ModifierKeys.Alt;

            if (ctrl && alt && e.Key == Key.C)
            {
                ToggleAppVisibility();
                e.Handled = true;
            }
            else if (ctrl && !alt && e.Key == Key.C)
            {
                OnCopyContrastRatioClicked(this, new RoutedEventArgs());
                e.Handled = true;
            }
            else if (ctrl && alt && e.Key == Key.B)
            {
                PickBackground();
                e.Handled = true;
            }
            else if (ctrl && alt && e.Key == Key.F)
            {
                PickForeground();
                e.Handled = true;
            }
            else if (e.Key == Key.Escape || (ctrl && e.Key == Key.W))
            {
                HideApp();
                e.Handled = true;
            }
            else if (ctrl && e.Key == Key.Q)
            {
                ExitApp();
                e.Handled = true;
            }
            else if (e.Key == Key.Enter && Keyboard.FocusedElement is Button focusedBtn)
            {
                focusedBtn.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
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

        // Inline HEX Editing Handlers

        private void OnEditBackgroundHexClicked(object sender, RoutedEventArgs e)
        {
            if (FgHexTextBox.Visibility == Visibility.Visible)
            {
                CommitFgHexEdit();
            }
            _bgInitialHex = _model.BgHex;
            _bgEditFinished = false;
            BgHexTextBox.Text = _model.BgHex;
            BgHexButton.Visibility = Visibility.Collapsed;
            BgHexTextBox.Visibility = Visibility.Visible;
            BgHexTextBox.Focus();
            BgHexTextBox.SelectAll();
        }

        private void OnEditForegroundHexClicked(object sender, RoutedEventArgs e)
        {
            if (BgHexTextBox.Visibility == Visibility.Visible)
            {
                CommitBgHexEdit();
            }
            _fgInitialHex = _model.FgHex;
            _fgEditFinished = false;
            FgHexTextBox.Text = _model.FgHex;
            FgHexButton.Visibility = Visibility.Collapsed;
            FgHexTextBox.Visibility = Visibility.Visible;
            FgHexTextBox.Focus();
            FgHexTextBox.SelectAll();
        }

        private void OnBgHexTextChanged(object sender, TextChangedEventArgs e)
        {
            var raw = BgHexTextBox.Text.Trim();
            var cleaned = raw.StartsWith("#", StringComparison.Ordinal) ? raw.Substring(1) : raw;
            if (cleaned.Length == 6 && ColorModel.ParseHex(cleaned).HasValue)
            {
                _model.SetBackgroundHex(cleaned);
            }
        }

        private void OnFgHexTextChanged(object sender, TextChangedEventArgs e)
        {
            var raw = FgHexTextBox.Text.Trim();
            var cleaned = raw.StartsWith("#", StringComparison.Ordinal) ? raw.Substring(1) : raw;
            if (cleaned.Length == 6 && ColorModel.ParseHex(cleaned).HasValue)
            {
                _model.SetForegroundHex(cleaned);
            }
        }

        private void OnBgHexKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                CommitBgHexEdit();
                e.Handled = true;
            }
            else if (e.Key == Key.Escape)
            {
                CancelBgHexEdit();
                e.Handled = true;
            }
        }

        private void OnFgHexKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                CommitFgHexEdit();
                e.Handled = true;
            }
            else if (e.Key == Key.Escape)
            {
                CancelFgHexEdit();
                e.Handled = true;
            }
        }

        private void OnBgHexLostFocus(object sender, RoutedEventArgs e)
        {
            CommitBgHexEdit();
        }

        private void OnFgHexLostFocus(object sender, RoutedEventArgs e)
        {
            CommitFgHexEdit();
        }

        private void CommitBgHexEdit()
        {
            if (_bgEditFinished || BgHexTextBox.Visibility != Visibility.Visible)
            {
                return;
            }
            _bgEditFinished = true;
            var text = BgHexTextBox.Text.Trim();
            if (ColorModel.ParseHex(text).HasValue)
            {
                _model.SetBackgroundHex(text);
            }
            else
            {
                _model.SetBackgroundHex(_bgInitialHex);
            }
            BgHexTextBox.Visibility = Visibility.Collapsed;
            BgHexButton.Visibility = Visibility.Visible;
        }

        private void CancelBgHexEdit()
        {
            if (_bgEditFinished || BgHexTextBox.Visibility != Visibility.Visible)
            {
                return;
            }
            _bgEditFinished = true;
            _model.SetBackgroundHex(_bgInitialHex);
            BgHexTextBox.Visibility = Visibility.Collapsed;
            BgHexButton.Visibility = Visibility.Visible;
            BgSwatchButton.Focus();
        }

        private void CommitFgHexEdit()
        {
            if (_fgEditFinished || FgHexTextBox.Visibility != Visibility.Visible)
            {
                return;
            }
            _fgEditFinished = true;
            var text = FgHexTextBox.Text.Trim();
            if (ColorModel.ParseHex(text).HasValue)
            {
                _model.SetForegroundHex(text);
            }
            else
            {
                _model.SetForegroundHex(_fgInitialHex);
            }
            FgHexTextBox.Visibility = Visibility.Collapsed;
            FgHexButton.Visibility = Visibility.Visible;
        }

        private void CancelFgHexEdit()
        {
            if (_fgEditFinished || FgHexTextBox.Visibility != Visibility.Visible)
            {
                return;
            }
            _fgEditFinished = true;
            _model.SetForegroundHex(_fgInitialHex);
            FgHexTextBox.Visibility = Visibility.Collapsed;
            FgHexButton.Visibility = Visibility.Visible;
            FgSwatchButton.Focus();
        }
    }
}

