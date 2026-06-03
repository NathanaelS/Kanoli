#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${1:-kanoli_flutter/dist}"

if [[ "$DIST_DIR" != /* ]]; then
  DIST_DIR="$REPO_ROOT/$DIST_DIR"
fi

if [[ ! -d "$DIST_DIR" ]]; then
  echo "Missing dist directory: $DIST_DIR" >&2
  exit 1
fi

OUTPUT_FILE="$DIST_DIR/SHA256SUMS.txt"
ARTIFACT_LIST="$(mktemp)"
trap 'rm -f "$ARTIFACT_LIST"' EXIT

find "$DIST_DIR" -maxdepth 1 -type f \
  \( -name '*.AppImage' -o -name '*.dmg' -o -name '*.exe' -o -name '*.msi' -o -name '*.pkg' -o -name '*.zip' \) \
  ! -name 'SHA256SUMS.txt' \
  ! -name 'SHA256SUMS.txt.sig' \
  -print \
  | sort > "$ARTIFACT_LIST"

if [[ ! -s "$ARTIFACT_LIST" ]]; then
  echo "No release artifacts found in: $DIST_DIR" >&2
  echo "Expected one or more files ending in .AppImage, .dmg, .exe, .msi, .pkg, or .zip." >&2
  exit 1
fi

(
  cd "$DIST_DIR"
  while IFS= read -r artifact; do
    shasum -a 256 "$(basename "$artifact")"
  done < "$ARTIFACT_LIST"
) > "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"
echo
echo "Release verification note:"
echo "- Download the artifact and SHA256SUMS.txt from the same GitHub release."
echo "- Run: shasum -a 256 <artifact>"
echo "- Compare the output with the matching line in SHA256SUMS.txt."
