#!/bin/bash

# App Icon Generator Script for AquaPulse
# This script generates all required icon sizes for iOS and Android

echo "🎨 AquaPulse App Icon Generator"
echo "================================"

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "❌ ImageMagick is not installed. Please install it first:"
    echo "   brew install imagemagick"
    exit 1
fi

# Check if source icon exists
SOURCE_ICON="assets/icons/app_icon.png"
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Source icon not found at: $SOURCE_ICON"
    echo "   Please upload your app icon to: assets/icons/app_icon.png"
    exit 1
fi

echo "✅ Found source icon: $SOURCE_ICON"
echo "🔄 Generating icon sizes..."

# Create temporary directory
TEMP_DIR="temp_icons"
mkdir -p "$TEMP_DIR"

# iOS Icon Sizes with proper naming
echo "📱 Generating iOS icons..."

# iOS App Icon sizes with proper @1x, @2x, @3x naming
declare -a ios_icons=(
    "20:20:Icon-App-20x20@1x.png"
    "40:40:Icon-App-20x20@2x.png"
    "60:60:Icon-App-20x20@3x.png"
    "29:29:Icon-App-29x29@1x.png"
    "58:58:Icon-App-29x29@2x.png"
    "87:87:Icon-App-29x29@3x.png"
    "40:40:Icon-App-40x40@1x.png"
    "80:80:Icon-App-40x40@2x.png"
    "120:120:Icon-App-40x40@3x.png"
    "120:120:Icon-App-60x60@2x.png"
    "180:180:Icon-App-60x60@3x.png"
    "76:76:Icon-App-76x76@1x.png"
    "152:152:Icon-App-76x76@2x.png"
    "167:167:Icon-App-83.5x83.5@2x.png"
    "1024:1024:Icon-App-1024x1024@1x.png"
)

# Generate iOS icons with high quality
for icon_info in "${ios_icons[@]}"; do
    IFS=':' read -r width height filename <<< "$icon_info"
    echo "   ✅ Generating: $filename (${width}x${height})"
    magick "$SOURCE_ICON" -resize "${width}x${height}" -quality 100 -strip "$TEMP_DIR/$filename"
done

# Android Icon Sizes
echo "🤖 Generating Android icons..."

# Android mipmap sizes
declare -a android_sizes=(
    "48:48"   # mdpi
    "72:72"   # hdpi
    "96:96"   # xhdpi
    "144:144" # xxhdpi
    "192:192" # xxxhdpi
)

# Generate Android icons with high quality
for size in "${android_sizes[@]}"; do
    IFS=':' read -r width height <<< "$size"
    filename="ic_launcher_${width}x${height}.png"
    echo "   ✅ Generating: $filename (${width}x${height})"
    magick "$SOURCE_ICON" -resize "${width}x${height}" -quality 100 -strip "$TEMP_DIR/$filename"
done

# Copy iOS icons to the correct locations
echo "📁 Copying iOS icons..."
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Remove old icons first
rm -f "$IOS_ICON_DIR"/Icon-App-*.png

# Copy all generated iOS icons
cp "$TEMP_DIR"/Icon-App-*.png "$IOS_ICON_DIR/"

# Copy Android icons to the correct locations
echo "📁 Copying Android icons..."

# Copy to mipmap directories
cp "$TEMP_DIR/ic_launcher_48x48.png" "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
cp "$TEMP_DIR/ic_launcher_72x72.png" "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
cp "$TEMP_DIR/ic_launcher_96x96.png" "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
cp "$TEMP_DIR/ic_launcher_144x144.png" "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
cp "$TEMP_DIR/ic_launcher_192x192.png" "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "✅ App icons generated successfully!"
echo "🎉 Your beautiful neumorphic water drop icon is now set up!"
echo ""
echo "📱 Next steps:"
echo "   1. Run: flutter clean"
echo "   2. Run: flutter build ios --release"
echo "   3. Run: flutter install"
echo ""
echo "🚀 Your AquaPulse app will now have your custom icon!"
