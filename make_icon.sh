#!/bin/bash
set -e

SRC_IMG="AppIcon.png"
ICONSET="AppIcon.iconset"

mkdir -p "$ICONSET"

# Resize and convert to PNG format
sips -s format png -z 16 16     "$SRC_IMG" --out "$ICONSET/icon_16x16.png"
sips -s format png -z 32 32     "$SRC_IMG" --out "$ICONSET/icon_16x16@2x.png"
sips -s format png -z 32 32     "$SRC_IMG" --out "$ICONSET/icon_32x32.png"
sips -s format png -z 64 64     "$SRC_IMG" --out "$ICONSET/icon_32x32@2x.png"
sips -s format png -z 128 128   "$SRC_IMG" --out "$ICONSET/icon_128x128.png"
sips -s format png -z 256 256   "$SRC_IMG" --out "$ICONSET/icon_128x128@2x.png"
sips -s format png -z 256 256   "$SRC_IMG" --out "$ICONSET/icon_256x256.png"
sips -s format png -z 512 512   "$SRC_IMG" --out "$ICONSET/icon_256x256@2x.png"
sips -s format png -z 512 512   "$SRC_IMG" --out "$ICONSET/icon_512x512.png"
sips -s format png -z 1024 1024 "$SRC_IMG" --out "$ICONSET/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET" -o AppIcon.icns

# Clean up iconset directory
rm -rf "$ICONSET"
echo "Successfully created AppIcon.icns"
