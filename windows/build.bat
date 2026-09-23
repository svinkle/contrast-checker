@echo off
setlocal
cd /d "%~dp0"
echo ==> Building Contrast Checker for Windows (.exe and .msi)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" -BuildMsi
