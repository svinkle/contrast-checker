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

SOURCES=(
    "Sources/ColorModel.swift"
    "Sources/ColorSamplerManager.swift"
    "Sources/HotKeyManager.swift"
    "Sources/ContentView.swift"
    "Sources/main.swift"
)

echo "==> Compiling Swift sources for Universal 2 (arm64 & x86_64)..."
if swiftc -O -parse-as-library -target arm64-apple-macos13.0 -module-cache-path "${CACHE_DIR}" "${SOURCES[@]}" -o "${BUILD_DIR}/${APP_NAME}-arm64" && \
   swiftc -O -parse-as-library -target x86_64-apple-macos13.0 -module-cache-path "${CACHE_DIR}" "${SOURCES[@]}" -o "${BUILD_DIR}/${APP_NAME}-x86_64" && \
   lipo -create -output "${MACOS_DIR}/${APP_NAME}" "${BUILD_DIR}/${APP_NAME}-arm64" "${BUILD_DIR}/${APP_NAME}-x86_64"; then
    echo "==> Successfully created Universal 2 binary (arm64 + x86_64)"
    rm -f "${BUILD_DIR}/${APP_NAME}-arm64" "${BUILD_DIR}/${APP_NAME}-x86_64"
else
    echo "==> Universal build failed; falling back to host architecture..."
    swiftc -O -parse-as-library -module-cache-path "${CACHE_DIR}" "${SOURCES[@]}" -o "${MACOS_DIR}/${APP_NAME}"
fi

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

