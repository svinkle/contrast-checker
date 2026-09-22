using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using ContrastChecker.Models;
using Color = System.Windows.Media.Color;
using Point = System.Windows.Point;

namespace ContrastChecker.Views
{
    public partial class PickerOverlayWindow : Window
    {
        private readonly Bitmap _screenBitmap;
        private readonly int _virtualLeft;
        private readonly int _virtualTop;
        private readonly Action<Color>? _onColorSelected;
        private const int ZoomSampleRadius = 6; // 13x13 pixel sample
        private Color _currentHoverColor;

        public PickerOverlayWindow(Bitmap screenBitmap, int virtualLeft, int virtualTop, Action<Color>? onColorSelected)
        {
            InitializeComponent();

            _screenBitmap = screenBitmap;
            _virtualLeft = virtualLeft;
            _virtualTop = virtualTop;
            _onColorSelected = onColorSelected;

            Left = virtualLeft;
            Top = virtualTop;
            Width = screenBitmap.Width;
            Height = screenBitmap.Height;

            Loaded += (s, e) =>
            {
                var mousePos = Mouse.GetPosition(this);
                UpdateLoupe(mousePos);
            };
        }

        private void OnMouseMove(object sender, MouseEventArgs e)
        {
            var pos = e.GetPosition(this);
            UpdateLoupe(pos);
        }

        private void UpdateLoupe(Point pos)
        {
            int screenX = (int)pos.X;
            int screenY = (int)pos.Y;

            if (screenX < 0 || screenX >= _screenBitmap.Width || screenY < 0 || screenY >= _screenBitmap.Height)
                return;

            // Sample center pixel
            var pixel = _screenBitmap.GetPixel(screenX, screenY);
            _currentHoverColor = Color.FromRgb(pixel.R, pixel.G, pixel.B);

            ColorSwatch.Background = new SolidColorBrush(_currentHoverColor);
            HexText.Text = ColorModel.ColorToHex(_currentHoverColor);

            // Crop sample region around cursor for magnifier
            int sampleSize = (ZoomSampleRadius * 2) + 1;
            int cropX = Math.Max(0, Math.Min(_screenBitmap.Width - sampleSize, screenX - ZoomSampleRadius));
            int cropY = Math.Max(0, Math.Min(_screenBitmap.Height - sampleSize, screenY - ZoomSampleRadius));

            using (var cropped = new Bitmap(sampleSize, sampleSize, System.Drawing.Imaging.PixelFormat.Format32bppArgb))
            {
                using (var g = Graphics.FromImage(cropped))
                {
                    g.DrawImage(_screenBitmap,
                        new Rectangle(0, 0, sampleSize, sampleSize),
                        new Rectangle(cropX, cropY, sampleSize, sampleSize),
                        GraphicsUnit.Pixel);
                }

                MagnifierImage.Source = ConvertBitmapToBitmapImage(cropped);
            }

            // Position loupe container offset from cursor with bounds safety
            double loupeWidth = LoupeContainer.Width;
            double loupeHeight = LoupeContainer.Height;

            double targetX = pos.X + 24;
            double targetY = pos.Y + 24;

            if (targetX + loupeWidth > ActualWidth)
                targetX = pos.X - loupeWidth - 24;

            if (targetY + loupeHeight > ActualHeight)
                targetY = pos.Y - loupeHeight - 24;

            Canvas.SetLeft(LoupeContainer, Math.Max(10, targetX));
            Canvas.SetTop(LoupeContainer, Math.Max(10, targetY));
        }

        private void OnMouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ChangedButton == MouseButton.Left)
            {
                _onColorSelected?.Invoke(_currentHoverColor);
                Close();
            }
            else if (e.ChangedButton == MouseButton.Right)
            {
                // Right click cancels
                Close();
            }
        }

        private void OnKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Escape)
            {
                Close();
            }
        }

        protected override void OnClosed(EventArgs e)
        {
            base.OnClosed(e);
            _screenBitmap.Dispose();
        }

        private static BitmapImage ConvertBitmapToBitmapImage(Bitmap bitmap)
        {
            using (var memory = new MemoryStream())
            {
                bitmap.Save(memory, ImageFormat.Bmp);
                memory.Position = 0;

                var bitmapImage = new BitmapImage();
                bitmapImage.BeginInit();
                bitmapImage.StreamSource = memory;
                bitmapImage.CacheOption = BitmapCacheOption.OnLoad;
                bitmapImage.EndInit();
                bitmapImage.Freeze();
                return bitmapImage;
            }
        }
    }
}

