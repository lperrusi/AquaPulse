# 🚀 Ad Configuration Quick Reference

## Quick Checklist

When you're ready to switch to production ads, update these 4 places:

- [ ] **1. Ad Service** - Update production ad unit IDs and set `_useTestAds = false`
- [ ] **2. Android Manifest** - Update Android App ID
- [ ] **3. iOS Info.plist** - Update iOS App ID
- [ ] **4. Test** - Verify ads load correctly before release

---

## 📝 Exact Changes Needed

### 1. `lib/services/ad_service.dart` (Lines 30, 38-39)

**Change 1:** Set production mode
```dart
// Line 30 - Change from:
static const bool _useTestAds = true;

// To:
static const bool _useTestAds = false;
```

**Change 2:** Add your production ad unit IDs
```dart
// Lines 38-39 - Replace placeholders:
static const String _productionBannerAdUnitId = 'ca-app-pub-XXXXXXXXXX/YYYYYYYYYY';
static const String _productionInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXX/ZZZZZZZZZZ';

// With your actual IDs from AdMob:
static const String _productionBannerAdUnitId = 'ca-app-pub-1234567890/1234567890';
static const String _productionInterstitialAdUnitId = 'ca-app-pub-1234567890/0987654321';
```

### 2. `android/app/src/main/AndroidManifest.xml` (Line 35)

```xml
<!-- Replace test App ID with your Android production App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXX~YYYYYYYYYY"/>
```

### 3. `ios/Runner/Info.plist` (Line 53)

```xml
<!-- Replace test App ID with your iOS production App ID -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~YYYYYYYYYY</string>
```

---

## 🔍 How to Get Your IDs from AdMob

1. Go to [https://apps.admob.com/](https://apps.admob.com/)
2. Select your app
3. **For App ID:** Go to "App settings" → Copy the "App ID"
4. **For Ad Unit IDs:** Go to "Ad units" → Copy each ad unit's ID

---

## ⚠️ Important Reminders

- **App ID format:** `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY` (has `~`)
- **Ad Unit ID format:** `ca-app-pub-XXXXXXXXXX/YYYYYYYYYY` (has `/`)
- **Never click your own ads** - This violates AdMob policies
- Test with production IDs before releasing
- Keep test mode (`_useTestAds = true`) during development

---

## 📚 Full Documentation

See `AD_SETUP_GUIDE.md` for detailed step-by-step instructions.
