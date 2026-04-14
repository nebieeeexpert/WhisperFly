#!/usr/bin/env bash
# scripts/build-dev.sh
#
# Builds WhisperFly (debug by default), copies the binary into the .app bundle,
# and re-signs it with the required entitlements so that Hardened Runtime permits
# microphone access and AppleScript/CGEvent keyboard injection.
#
# Usage:
#   ./scripts/build-dev.sh              # debug build
#   ./scripts/build-dev.sh --release    # release build
#
# Prerequisites:
#   - Xcode Command Line Tools
#   - A valid "Apple Development" signing identity in your Keychain
#     (run: security find-identity -v -p codesigning)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$REPO_ROOT/WhisperFly.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/WhisperFly"
ENTITLEMENTS="$REPO_ROOT/WhisperFly.entitlements"

# Build configuration
BUILD_CONFIG="debug"
SWIFT_BUILD_FLAGS=""
if [ "${1:-}" = "--release" ]; then
    BUILD_CONFIG="release"
    SWIFT_BUILD_FLAGS="-c release"
fi

# Auto-detect architecture
ARCH="$(uname -m)"
PLATFORM="apple-macosx"
BUILD_DIR="$REPO_ROOT/.build/${ARCH}-${PLATFORM}/${BUILD_CONFIG}"

echo "==> Building WhisperFly (${BUILD_CONFIG}, ${ARCH})..."
cd "$REPO_ROOT"
swift build $SWIFT_BUILD_FLAGS

BUILT_BINARY="$BUILD_DIR/WhisperFly"

if [ ! -f "$BUILT_BINARY" ]; then
    echo "ERROR: built binary not found at: $BUILT_BINARY" >&2
    exit 1
fi

# Copy binary into app bundle
echo "==> Copying binary into $APP_BUNDLE..."
cp "$BUILT_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Detect signing identity
# Use the identity already embedded in the .app if available; otherwise fall
# back to the first "Apple Development" cert found in the keychain.
CURRENT_IDENTITY=""

CURRENT_IDENTITY="$(codesign -d --verbose=1 "$APP_BUNDLE" 2>&1 \
    | grep 'Authority=' | head -1 | sed 's/Authority=//')" || true

if [ -z "$CURRENT_IDENTITY" ]; then
    CURRENT_IDENTITY="$(security find-identity -v -p codesigning \
        | grep 'Apple Development' | head -1 \
        | sed 's/.*) //' | sed 's/ ".*"//')" || true
fi

if [ -z "$CURRENT_IDENTITY" ]; then
    echo "ERROR: No signing identity found. Install an Apple Development certificate." >&2
    echo "       Run: security find-identity -v -p codesigning" >&2
    exit 1
fi

echo "==> Signing with identity: $CURRENT_IDENTITY"
echo "    Entitlements: $ENTITLEMENTS"

codesign \
    --force \
    --sign "$CURRENT_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --deep \
    "$APP_BUNDLE"

echo ""
echo "Build complete!"
echo "  App:    $APP_BUNDLE"
echo "  Binary: $APP_BINARY"
echo ""
echo "To launch:"
echo "  open $APP_BUNDLE"
echo ""
echo "After first launch, grant permissions in:"
echo "  System Settings -> Privacy & Security -> Microphone       (for mic recording)"
echo "  System Settings -> Privacy & Security -> Screen Recording (for system audio)"
echo "  System Settings -> Privacy & Security -> Accessibility    (for text injection)"
