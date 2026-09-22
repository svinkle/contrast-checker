#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ContrastChecker"
BUILD_DIR="build"
DMG_STAGING="${BUILD_DIR}/dmg_staging"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"
VOL_NAME="Contrast Checker"

# Ensure the app is built first
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo "==> Building ${APP_NAME}.app first..."
    ./build.sh
fi

echo "==> Preparing DMG staging folder..."
rm -rf "${DMG_STAGING}" "${DMG_PATH}"
mkdir -p "${DMG_STAGING}"

# Copy the .app bundle
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_STAGING}/"

# Create symlink to /Applications for easy drag-and-drop installation
ln -s /Applications "${DMG_STAGING}/Applications"

echo "==> Creating DMG disk image..."
hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Clean up staging directory
rm -rf "${DMG_STAGING}"

echo "==> DMG successfully created: ${DMG_PATH}"

