@echo off
setlocal enabledelayedexpansion

echo ==> Launching Contrast Checker Windows build...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed with exit code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

exit /b 0
