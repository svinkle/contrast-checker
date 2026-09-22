# Contrast Checker Windows Build Script
# Usage: powershell -ExecutionPolicy Bypass -File build.ps1 [-BuildMsi]

param (
    [switch]$BuildMsi = $false,
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputDir = Join-Path $ScriptDir "build"

Write-Host "==> Building Contrast Checker for Windows ($Configuration)..." -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# 1. Run Tests
Write-Host "==> Running ColorModel unit tests..." -ForegroundColor Yellow
dotnet test (Join-Path $ScriptDir "ContrastChecker.Tests\ContrastChecker.Tests.csproj") -c $Configuration --nologo

# 2. Publish Self-Contained Single-File Executable
Write-Host "==> Publishing self-contained single-file executable (win-x64)..." -ForegroundColor Yellow
$ProjectFile = Join-Path $ScriptDir "ContrastChecker\ContrastChecker.csproj"
dotnet publish $ProjectFile `
    -c $Configuration `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    --nologo

$PublishDir = Join-Path $ScriptDir "ContrastChecker\bin\$Configuration\net8.0-windows\win-x64\publish"
$ExeSource = Join-Path $PublishDir "ContrastChecker.exe"
$ExeDest = Join-Path $OutputDir "ContrastChecker.exe"

Copy-Item $ExeSource $ExeDest -Force
Write-Host "==> Standalone executable created: $ExeDest" -ForegroundColor Green

# 3. Optional MSI Build with WiX
if ($BuildMsi) {
    Write-Host "==> Building MSI Installer with WiX..." -ForegroundColor Yellow
    $WixInstalled = Get-Command wix -ErrorAction SilentlyContinue
    if (-not $WixInstalled) {
        Write-Host "--> Installing WiX CLI (.NET Tool)..." -ForegroundColor Gray
        dotnet tool install --global wix
    }

    $WixProj = Join-Path $ScriptDir "ContrastChecker.Installer\ContrastChecker.Installer.wixproj"
    dotnet build $WixProj -c $Configuration -p:Platform=x64 --nologo

    $MsiSource = Join-Path $ScriptDir "ContrastChecker.Installer\bin\x64\$Configuration\ContrastChecker.msi"
    if (Test-Path $MsiSource) {
        $MsiDest = Join-Path $OutputDir "ContrastChecker.msi"
        Copy-Item $MsiSource $MsiDest -Force
        Write-Host "==> MSI Installer created: $MsiDest" -ForegroundColor Green
    } else {
        Write-Host "Warning: MSI file not found at expected path: $MsiSource" -ForegroundColor Yellow
    }
}

Write-Host "==> Build complete! Output located at: $OutputDir" -ForegroundColor Green
