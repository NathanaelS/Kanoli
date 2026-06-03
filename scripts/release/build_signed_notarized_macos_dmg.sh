#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$REPO_ROOT/kanoli_flutter"
PUBSPEC="$APP_DIR/pubspec.yaml"
APP_NAME="Kanoli"
TEAM_ID="${KANOLI_APPLE_TEAM_ID:-5Z6FYPML23}"
SIGNING_IDENTITY="${KANOLI_MACOS_SIGNING_IDENTITY:-}"
NOTARY_PROFILE="${KANOLI_NOTARY_PROFILE:-kanoli-notary}"
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

for required_command in flutter hdiutil codesign security xcrun; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "Missing required command: $required_command" >&2
    exit 1
  }
done

SIGNING_IDENTITIES="$(security find-identity -v -p codesigning)"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  MATCHING_IDENTITIES="$(
    printf '%s\n' "$SIGNING_IDENTITIES" |
      grep -F "Developer ID Application:" |
      grep -F "($TEAM_ID)" || true
  )"
  SIGNING_IDENTITY_MATCH_COUNT="$(printf '%s\n' "$MATCHING_IDENTITIES" | grep -c '[^[:space:]]' || true)"

  if [[ "$SIGNING_IDENTITY_MATCH_COUNT" -eq 1 ]]; then
    SIGNING_IDENTITY="$(printf '%s\n' "$MATCHING_IDENTITIES" | awk '{ print $2 }')"
  elif [[ "$SIGNING_IDENTITY_MATCH_COUNT" -eq 0 ]]; then
    echo "Could not find a Developer ID Application signing identity for Team ID $TEAM_ID." >&2
    echo "Install the certificate or set KANOLI_MACOS_SIGNING_IDENTITY to a certificate hash." >&2
    exit 1
  else
    echo "Multiple Developer ID Application identities found for Team ID $TEAM_ID:" >&2
    printf '%s\n' "$MATCHING_IDENTITIES" >&2
    echo >&2
    echo "Set KANOLI_MACOS_SIGNING_IDENTITY to the certificate hash from the matching line." >&2
    exit 1
  fi
else
  SIGNING_IDENTITY_MATCH_COUNT="$(printf '%s\n' "$SIGNING_IDENTITIES" | grep -F -c "$SIGNING_IDENTITY" || true)"

  if [[ "$SIGNING_IDENTITY_MATCH_COUNT" -eq 0 ]]; then
    echo "Could not find signing identity in keychain:" >&2
    echo "$SIGNING_IDENTITY" >&2
    echo >&2
    echo "Override KANOLI_MACOS_SIGNING_IDENTITY with a valid certificate hash or exact name." >&2
    exit 1
  fi

  if [[ "$SIGNING_IDENTITY_MATCH_COUNT" -gt 1 ]]; then
    echo "Signing identity is ambiguous:" >&2
    echo "$SIGNING_IDENTITY" >&2
    echo >&2
    printf '%s\n' "$SIGNING_IDENTITIES" | grep -F "$SIGNING_IDENTITY" >&2
    echo >&2
    echo "Set KANOLI_MACOS_SIGNING_IDENTITY to the certificate hash from the matching line." >&2
    exit 1
  fi
fi

echo "Using signing identity: $SIGNING_IDENTITY"

APP_BUNDLE="$APP_DIR/build/macos/Build/Products/Release/$APP_NAME.app"
ENTITLEMENTS="$APP_DIR/macos/Runner/Release.entitlements"
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

echo "Signing app bundle..."
codesign \
  --force \
  --deep \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$APP_BUNDLE"

echo "Verifying app signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "Staging app bundle..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating DMG: $OUTPUT_DMG"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"

echo "Signing DMG..."
codesign \
  --force \
  --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$OUTPUT_DMG"

echo "Submitting DMG for notarization with profile: $NOTARY_PROFILE"
xcrun notarytool submit "$OUTPUT_DMG" \
  --keychain-profile "$NOTARY_PROFILE" \
  --team-id "$TEAM_ID" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$OUTPUT_DMG"

echo "Validating notarized DMG..."
xcrun stapler validate "$OUTPUT_DMG"
spctl -a -vv -t open --context context:primary-signature "$OUTPUT_DMG"

"$REPO_ROOT/scripts/release/generate_checksums.sh" "$DIST_DIR"

echo
echo "Signed and notarized macOS release artifact ready:"
echo "$OUTPUT_DMG"
