#!/bin/bash
# Packages the built executable into a proper HydrationPet.app bundle so it
# can be double-clicked, added to Login Items, etc.
set -euo pipefail

APP_NAME="HydrationPet"
BUILD_CONFIG="release"

cd "$(dirname "$0")/.."

swift build -c "$BUILD_CONFIG"

BIN_PATH=".build/$BUILD_CONFIG/$APP_NAME"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$BIN_PATH" "$CONTENTS/MacOS/$APP_NAME"

# Copy the SwiftPM-generated resource bundle (contains idle.gif / drink.gif).
RESOURCE_BUNDLE=$(find ".build/$BUILD_CONFIG" -maxdepth 1 -name "*.bundle" | head -n 1)
if [ -n "$RESOURCE_BUNDLE" ]; then
  cp -R "$RESOURCE_BUNDLE" "$CONTENTS/Resources/"
else
  echo "⚠️  No resource bundle found in .build/$BUILD_CONFIG — did you add idle.gif/drink.gif?"
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.hydrationpet</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
PLIST

echo "Built $APP_BUNDLE — drag it into /Applications and double-click to launch."
echo "If the pet doesn't appear, check Console.app for GIFAnimator warnings —"
echo "it usually means the resource bundle wasn't found; try moving it into"
echo "$CONTENTS/MacOS/ instead of $CONTENTS/Resources/ and re-launch."
