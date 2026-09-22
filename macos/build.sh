#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ContrastChecker"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
CACHE_DIR="./.cache"

echo "==> Building ${APP_NAME} for macOS..."

mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"
mkdir -p "${CACHE_DIR}"

echo "==> Compiling Swift sources..."
swiftc \
    -O \
    -parse-as-library \
    -module-cache-path "${CACHE_DIR}" \
    Sources/ColorModel.swift \
    Sources/ColorSamplerManager.swift \
    Sources/HotKeyManager.swift \
    Sources/ContentView.swift \
    Sources/main.swift \
    -o "${MACOS_DIR}/${APP_NAME}"

echo "==> Installing bundle resources..."
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Create a convenient CLI wrapper
cat << 'EOF' > "${BUILD_DIR}/contrast-checker"
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${DIR}/ContrastChecker.app/Contents/MacOS/ContrastChecker" "$@"
EOF
chmod +x "${BUILD_DIR}/contrast-checker"

echo "==> Build complete: ${APP_BUNDLE}"
echo "    Run with: open ${APP_BUNDLE} or ./build/contrast-checker"

