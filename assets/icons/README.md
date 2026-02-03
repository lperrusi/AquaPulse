# 🎨 App Icon Setup for AquaPulse

## 📁 Upload Your Icon Here

1. **Save your app icon** as `app_icon.png` in this folder
2. **Run the generation script** to create all required sizes
3. **Build and install** the app with your new icon

## 🚀 Quick Setup

### Step 1: Upload Your Icon
- Save your neumorphic water drop icon as: `app_icon.png`
- Place it in this folder: `assets/icons/app_icon.png`

### Step 2: Generate All Icon Sizes
```bash
# Install ImageMagick (if not already installed)
brew install imagemagick

# Run the icon generator script
./scripts/generate_app_icons.sh
```

### Step 3: Build and Install
```bash
# Clean and rebuild the app
flutter clean
flutter build ios --release
flutter install
```

## 📱 What the Script Does

The `generate_app_icons.sh` script will:

✅ **Generate iOS icons** (20x20 to 1024x1024)
✅ **Generate Android icons** (48x48 to 192x192)
✅ **Copy files** to the correct locations
✅ **Clean up** temporary files

## 🎯 Icon Requirements

- **Format**: PNG
- **Background**: Transparent (preferred) or solid
- **Minimum size**: 1024x1024 pixels
- **Style**: Your beautiful neumorphic water drop design

## 🎉 Result

Your AquaPulse app will have your custom neumorphic water drop icon on both iOS and Android!

---

**Your icon design is perfect for AquaPulse!** 💧✨
