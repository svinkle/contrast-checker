#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Building standalone ContrastChecker.flatpak bundle..."
make bundle
echo "==> Done: ContrastChecker.flatpak"
