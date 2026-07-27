#!/bin/bash
set -e

echo "=== Building Roll a Die ==="

# 1. Ensure directory structure exists
mkdir -p RollADie.app/Contents/MacOS
mkdir -p RollADie.app/Contents/Resources

# Create Info.plist with CFBundleIconFile
cat <<EOF > RollADie.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>RollADie</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mk.RollADie</string>
    <key>CFBundleName</key>
    <string>Roll a Die</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 2. Compile Swift file with size optimizations
echo "Compiling swift source code..."
swiftc -Osize -wmo -Xlinker -dead_strip main.swift -o RollADie.app/Contents/MacOS/RollADie

if [ -f AppIcon.png ]; then
    echo "Generating AppIcon.icns from AppIcon.png..."
    chmod +x make_icon.sh
    ./make_icon.sh
fi

if [ -f AppIcon.icns ]; then
    echo "Copying AppIcon.icns to resources..."
    cp AppIcon.icns RollADie.app/Contents/Resources/
fi

# 3. Strip binary symbols to minimize size
echo "Stripping binary..."
strip RollADie.app/Contents/MacOS/RollADie

# 4. Create DMG (Disk Image) for intuitive installation
echo "Creating distribution DMG (Disk Image)..."
rm -f RollADie.dmg
rm -rf dmg_source
mkdir -p dmg_source

# Copy the app to the DMG source directory
cp -R RollADie.app dmg_source/

# Create a symlink to the Applications folder inside the DMG source
ln -s /Applications dmg_source/Applications

if [ -f AppIcon.icns ]; then
    echo "Setting custom volume icon for DMG..."
    cp AppIcon.icns dmg_source/.VolumeIcon.icns
    SetFile -a C dmg_source
fi

# Build the DMG
hdiutil create -volname "Roll a Die Installation" -srcfolder dmg_source -ov -format UDZO RollADie.dmg

# Clean up DMG source directory
rm -rf dmg_source

echo "=== Build and packaging complete ==="
echo "Final app bundle: RollADie.app/"
echo "Disk Image (DMG): RollADie.dmg"
du -sh RollADie.app RollADie.dmg
