using System;
using System.Drawing;
using System.Windows;
using System.Windows.Media;
using ContrastChecker.Models;
using ContrastChecker.Views;
using Color = System.Windows.Media.Color;
using Size = System.Drawing.Size;

namespace ContrastChecker.Services
{
    public class ScreenColorSampler
    {
        private bool _isPicking;

        public bool IsPicking => _isPicking;

        public void PickBackgroundColor(ColorModel model)
        {
            PickColor(color =>
            {
                model.SetBackgroundColor(color);
            });
        }

        public void PickForegroundColor(ColorModel model)
        {
            PickColor(color =>
            {
                model.SetForegroundColor(color);
            });
        }

        public void PickColor(Action<Color> onSelected)
        {
            if (_isPicking)
                return;

            _isPicking = true;

            try
            {
                int left = (int)SystemParameters.VirtualScreenLeft;
                int top = (int)SystemParameters.VirtualScreenTop;
                int width = (int)SystemParameters.VirtualScreenWidth;
                int height = (int)SystemParameters.VirtualScreenHeight;

                if (width <= 0 || height <= 0)
                {
                    width = 1920;
                    height = 1080;
                }

                // Capture virtual desktop bitmap
                var screenBitmap = new Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
                using (var g = Graphics.FromImage(screenBitmap))
                {
                    g.CopyFromScreen(left, top, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);
                }

                var overlay = new PickerOverlayWindow(screenBitmap, left, top, color =>
                {
                    onSelected?.Invoke(color);
                });

                overlay.Closed += (s, e) =>
                {
                    _isPicking = false;
                };

                overlay.Show();
                overlay.Activate();
            }
            catch (Exception ex)
            {
                _isPicking = false;
                MessageBox.Show($"Failed to sample screen: {ex.Message}", "Contrast Checker", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }
    }
}
