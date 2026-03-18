#!/usr/bin/env bash
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.1.0
#
# Prerequisites:
#   brew install create-dmg
#   gh auth login

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>  (e.g. 1.1.0)" >&2
  exit 1
fi

TAG="v${VERSION}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAP_ROOT="$(cd "$REPO_ROOT/../homebrew-tap" 2>/dev/null && pwd)" || true
DMG_NAME="WhisperFly.dmg"
APP_NAME="WhisperFly.app"
BUILD_DIR="$REPO_ROOT/.build/release-stage"

echo "==> Building WhisperFly ${TAG}..."
xcodebuild \
  -scheme WhisperFly \
  -configuration Release \
  -derivedDataPath "$REPO_ROOT/.build/xcode" \
  -destination 'platform=macOS' \
  build

APP_PATH=$(find "$REPO_ROOT/.build/xcode" -name "$APP_NAME" -maxdepth 6 | head -1)
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: $APP_NAME not found after build." >&2
  exit 1
fi

echo "==> Creating DMG..."
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
cp -R "$APP_PATH" "$BUILD_DIR/"
create-dmg \
  --volname "WhisperFly ${VERSION}" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --icon "$APP_NAME" 180 170 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 480 170 \
  "$REPO_ROOT/$DMG_NAME" \
  "$BUILD_DIR/"

SHA256=$(shasum -a 256 "$REPO_ROOT/$DMG_NAME" | awk '{print $1}')
echo "==> DMG SHA256: $SHA256"

echo "==> Tagging ${TAG} and pushing..."
git -C "$REPO_ROOT" tag "$TAG"
git -C "$REPO_ROOT" push origin "$TAG"

echo "==> Creating GitHub release..."
gh release create "$TAG" \
  "$REPO_ROOT/$DMG_NAME" \
  --repo dandysuper/WhisperFly \
  --title "WhisperFly ${TAG}" \
  --generate-notes

echo "==> Updating Homebrew tap cask..."
if [[ -d "$TAP_ROOT" ]]; then
  CASK_FILE="$TAP_ROOT/Casks/whisperfly.rb"
  sed -i '' "s/version \".*\"/version \"${VERSION}\"/" "$CASK_FILE"
  sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" "$CASK_FILE"
  git -C "$TAP_ROOT" add Casks/whisperfly.rb
  git -C "$TAP_ROOT" commit -m "chore: bump whisperfly to ${TAG}"
  git -C "$TAP_ROOT" push origin main
  echo "==> Tap updated."
else
  echo "WARN: Tap not found at $TAP_ROOT — update Casks/whisperfly.rb manually:"
  echo "  version \"${VERSION}\""
  echo "  sha256 \"${SHA256}\""
fi

echo "==> Done! Release ${TAG} is live."
