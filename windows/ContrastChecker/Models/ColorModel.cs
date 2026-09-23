using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Media;
using System.Windows.Threading;

namespace ContrastChecker.Models
{
    public class ColorModel : INotifyPropertyChanged
    {
        private Color _backgroundColor;
        private Color _foregroundColor;
        private string _bgHex = "#000000";
        private string _fgHex = "#FFFFFF";
        private string? _copiedMessage;
        private DispatcherTimer? _copiedTimer;

        public event PropertyChangedEventHandler? PropertyChanged;

        public ColorModel(Color? background = null, Color? foreground = null)
        {
            _backgroundColor = background ?? Color.FromRgb(0, 0, 0);
            _foregroundColor = foreground ?? Color.FromRgb(255, 255, 255);
            UpdateHexAndRatios();
        }

        public Color BackgroundColor
        {
            get => _backgroundColor;
            set
            {
                if (_backgroundColor != value)
                {
                    _backgroundColor = value;
                    OnPropertyChanged();
                    UpdateHexAndRatios();
                }
            }
        }

        public Color ForegroundColor
        {
            get => _foregroundColor;
            set
            {
                if (_foregroundColor != value)
                {
                    _foregroundColor = value;
                    OnPropertyChanged();
                    UpdateHexAndRatios();
                }
            }
        }

        public string BgHex
        {
            get => _bgHex;
            private set
            {
                if (_bgHex != value)
                {
                    _bgHex = value;
                    OnPropertyChanged();
                }
            }
        }

        public string FgHex
        {
            get => _fgHex;
            private set
            {
                if (_fgHex != value)
                {
                    _fgHex = value;
                    OnPropertyChanged();
                }
            }
        }

        public double ContrastRatio => CalculateContrastRatio(_backgroundColor, _foregroundColor);

        public string ContrastRatioString => $"{ContrastRatio:F2}:1";

        public string ContrastRatioValueOnly => $"{ContrastRatio:F2}";

        public SolidColorBrush BackgroundBrush => new SolidColorBrush(_backgroundColor);

        public SolidColorBrush ForegroundBrush => new SolidColorBrush(_foregroundColor);

        public string? CopiedMessage
        {
            get => _copiedMessage;
            set
            {
                if (_copiedMessage != value)
                {
                    _copiedMessage = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(HasCopiedMessage));
                }
            }
        }

        public bool HasCopiedMessage => !string.IsNullOrEmpty(_copiedMessage);

        public void SetBackgroundColor(Color color)
        {
            BackgroundColor = color;
        }

        public void SetForegroundColor(Color color)
        {
            ForegroundColor = color;
        }

        public bool SetBackgroundHex(string hex)
        {
            var color = ParseHex(hex);
            if (color.HasValue)
            {
                BackgroundColor = color.Value;
                return true;
            }
            return false;
        }

        public bool SetForegroundHex(string hex)
        {
            var color = ParseHex(hex);
            if (color.HasValue)
            {
                ForegroundColor = color.Value;
                return true;
            }
            return false;
        }

        // MARK: - WCAG 2.2 Luminance and Contrast Ratio

        public static double CalculateContrastRatio(Color c1, Color c2)
        {
            double lum1 = RelativeLuminance(c1);
            double lum2 = RelativeLuminance(c2);
            double lighter = Math.Max(lum1, lum2);
            double darker = Math.Min(lum1, lum2);
            return (lighter + 0.05) / (darker + 0.05);
        }

        public static double RelativeLuminance(Color color)
        {
            double r = color.R / 255.0;
            double g = color.G / 255.0;
            double b = color.B / 255.0;

            double rLin = SRGBToLinear(r);
            double gLin = SRGBToLinear(g);
            double bLin = SRGBToLinear(b);

            return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
        }

        public static double SRGBToLinear(double val)
        {
            double clamped = Math.Max(0.0, Math.Min(1.0, val));
            if (clamped <= 0.04045)
            {
                return clamped / 12.92;
            }
            else
            {
                return Math.Pow((clamped + 0.055) / 1.055, 2.4);
            }
        }

        // MARK: - Hex Parsing and Formatting

        public static string ColorToHex(Color color)
        {
            return $"#{color.R:X2}{color.G:X2}{color.B:X2}";
        }

        public static Color? ParseHex(string hex)
        {
            if (string.IsNullOrWhiteSpace(hex))
                return null;

            string clean = hex.Trim().ToUpperInvariant();
            if (clean.StartsWith("#"))
            {
                clean = clean.Substring(1);
            }

            // Expand 3-digit shorthand "FFF" -> "FFFFFF"
            if (clean.Length == 3)
            {
                clean = $"{clean[0]}{clean[0]}{clean[1]}{clean[1]}{clean[2]}{clean[2]}";
            }

            if (clean.Length != 6)
                return null;

            if (byte.TryParse(clean.Substring(0, 2), System.Globalization.NumberStyles.HexNumber, null, out byte r) &&
                byte.TryParse(clean.Substring(2, 2), System.Globalization.NumberStyles.HexNumber, null, out byte g) &&
                byte.TryParse(clean.Substring(4, 2), System.Globalization.NumberStyles.HexNumber, null, out byte b))
            {
                return Color.FromRgb(r, g, b);
            }

            return null;
        }

        // MARK: - Clipboard Helpers

        public void CopyValue(string text, string label)
        {
            try
            {
                Clipboard.SetText(text);
                CopiedMessage = $"Copied {label}";

                _copiedTimer?.Stop();
                _copiedTimer = new DispatcherTimer
                {
                    Interval = TimeSpan.FromSeconds(1.4)
                };
                _copiedTimer.Tick += (s, e) =>
                {
                    _copiedTimer?.Stop();
                    CopiedMessage = null;
                };
                _copiedTimer.Start();
            }
            catch
            {
                // In case clipboard is locked by another process
            }
        }

        private void UpdateHexAndRatios()
        {
            BgHex = ColorToHex(_backgroundColor);
            FgHex = ColorToHex(_foregroundColor);
            OnPropertyChanged(nameof(ContrastRatio));
            OnPropertyChanged(nameof(ContrastRatioString));
            OnPropertyChanged(nameof(ContrastRatioValueOnly));
            OnPropertyChanged(nameof(BackgroundBrush));
            OnPropertyChanged(nameof(ForegroundBrush));
        }

        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}

