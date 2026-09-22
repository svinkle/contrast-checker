using System.Windows;

namespace ContrastChecker
{
    public partial class App : Application
    {
        private MainWindow? _mainWindow;

        private void OnStartup(object sender, StartupEventArgs e)
        {
            _mainWindow = new MainWindow();
            _mainWindow.ShowApp();
        }
    }
}
