#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$REPO_ROOT/kanoli_flutter"
PUBSPEC="$APP_DIR/pubspec.yaml"
APP_NAME="Kanoli"
VERSION="${1:-}"
DIST_DIR="${2:-kanoli_flutter/dist}"

if [[ "$DIST_DIR" != /* ]]; then
  DIST_DIR="$REPO_ROOT/$DIST_DIR"
fi

if [[ -z "$VERSION" ]]; then
  VERSION="$(
    awk -F: '/^version:/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2)
      split($2, parts, "+")
      print parts[1]
      exit
    }' "$PUBSPEC"
  )"
fi

if [[ -z "$VERSION" ]]; then
  echo "Could not determine version from $PUBSPEC" >&2
  exit 1
fi

command -v flutter >/dev/null 2>&1 || {
  echo "Missing required command: flutter" >&2
  exit 1
}

command -v hdiutil >/dev/null 2>&1 || {
  echo "Missing required command: hdiutil" >&2
  exit 1
}

APP_BUNDLE="$APP_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
OUTPUT_DMG="$DIST_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

mkdir -p "$DIST_DIR"

echo "Building macOS release app..."
(
  cd "$APP_DIR"
  flutter build macos --release
)

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Expected app bundle was not created: $APP_BUNDLE" >&2
  exit 1
fi

echo "Staging app bundle..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"

echo "Creating DMG: $OUTPUT_DMG"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"

"$REPO_ROOT/scripts/release/generate_checksums.sh" "$DIST_DIR"

echo
echo "macOS release artifact ready:"
echo "$OUTPUT_DMG"
