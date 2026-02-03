# 📱 AdMob Production Setup Guide

This guide will walk you through setting up production ad units for AquaPulse.

---

## Step 1: Create AdMob Account

1. Go to [Google AdMob](https://admob.google.com/)
2. Sign in with your Google account
3. Click **"Get Started"** or **"Add App"**
4. Accept the AdMob terms of service

---

## Step 2: Add Your App to AdMob

1. In AdMob dashboard, click **"Apps"** → **"Add App"**
2. Select platform:
   - **iOS** (if releasing on App Store)
   - **Android** (if releasing on Google Play)
   - Add both if releasing on both platforms
3. Enter your app details:
   - **App name:** AquaPulse (or your app name)
   - **Platform:** iOS/Android
   - **App Store/Play Store URL:** (can add later if not published yet)
4. Click **"Add"**

---

## Step 3: Get Your AdMob App ID

After adding your app, AdMob will provide you with an **App ID** that looks like:
- iOS: `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY`
- Android: `ca-app-pub-XXXXXXXXXX~ZZZZZZZZZZ`

**Save these IDs** - you'll need them in the next steps.

---

## Step 4: Create Ad Units

For each app (iOS and Android), create two ad units:

### 4.1 Create Banner Ad Unit

1. In your app's page, click **"Ad units"** → **"Add ad unit"**
2. Select **"Banner"**
3. Enter ad unit name: `Banner - AquaPulse` (or any name you prefer)
4. Click **"Create ad unit"**
5. **Copy the Ad Unit ID** (looks like: `ca-app-pub-XXXXXXXXXX/YYYYYYYYYY`)

### 4.2 Create Interstitial Ad Unit

1. Click **"Add ad unit"** again
2. Select **"Interstitial"**
3. Enter ad unit name: `Interstitial - AquaPulse`
4. Click **"Create ad unit"**
5. **Copy the Ad Unit ID** (looks like: `ca-app-pub-XXXXXXXXXX/ZZZZZZZZZZ`)

---

## Step 5: Update Your Code

### 5.1 Update Ad Service (Dart Code)

**File:** `lib/services/ad_service.dart`

1. Open the file and find the configuration section (around line 23-43)
2. Replace the production ad unit IDs:

```dart
// Production Ad Unit IDs - REPLACE THESE WITH YOUR ACTUAL PRODUCTION IDs
static const String _productionBannerAdUnitId = 'ca-app-pub-XXXXXXXXXX/YYYYYYYYYY'; // Your Banner ID
static const String _productionInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXX/ZZZZZZZZZZ'; // Your Interstitial ID
```

3. **IMPORTANT:** Set `_useTestAds` to `false` for production:

```dart
/// Set to false to use production ad IDs, true for test IDs
/// IMPORTANT: Set to false before releasing to production!
static const bool _useTestAds = false; // ← Change this to false
```

### 5.2 Update Android Manifest

**File:** `android/app/src/main/AndroidManifest.xml`

1. Find line 34-35 (around the `APPLICATION_ID` meta-data)
2. Replace the test App ID with your Android production App ID:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXX~ZZZZZZZZZZ"/> <!-- Your Android App ID -->
```

### 5.3 Update iOS Info.plist

**File:** `ios/Runner/Info.plist`

1. Find line 52-53 (the `GADApplicationIdentifier` key)
2. Replace the test App ID with your iOS production App ID:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~YYYYYYYYYY</string> <!-- Your iOS App ID -->
```

---

## Step 6: Verify Configuration

### 6.1 Check All IDs Are Updated

Make sure you've updated:
- ✅ `lib/services/ad_service.dart` - Production ad unit IDs
- ✅ `lib/services/ad_service.dart` - `_useTestAds = false`
- ✅ `android/app/src/main/AndroidManifest.xml` - Android App ID
- ✅ `ios/Runner/Info.plist` - iOS App ID

### 6.2 Test in Debug Mode First

Before releasing, test with production IDs in debug mode:

1. Set `_useTestAds = false` in `ad_service.dart`
2. Update all App IDs in manifest files
3. Run the app: `flutter run`
4. Verify ads are loading (they should be real ads, not test ads)
5. Check the AdMob dashboard to see if impressions are being recorded

---

## Step 7: Build for Production

### 7.1 Android Release Build

```bash
flutter build appbundle --release
```

### 7.2 iOS Release Build

```bash
flutter build ios --release
```

---

## Important Notes

### ⚠️ Testing with Production Ads

- **Never click your own ads** - This violates AdMob policies and can get your account banned
- Use test ads during development (`_useTestAds = true`)
- Only switch to production ads when ready to release

### 📊 AdMob Policies

Make sure your app complies with AdMob policies:
- Don't encourage users to click ads
- Don't place ads too close to interactive elements
- Provide value to users beyond ads
- Follow platform-specific guidelines

### 🔒 Security

- **Never commit production ad IDs to public repositories**
- Consider using environment variables or build configurations for sensitive IDs
- Keep your AdMob account secure with 2FA enabled

---

## Troubleshooting

### Ads Not Showing

1. **Check AdMob Dashboard:**
   - Verify your app is approved
   - Check if ad units are active
   - Look for any policy violations

2. **Check Logs:**
   - Look for error messages in debug console
   - Common errors:
     - Invalid ad unit ID
     - App ID mismatch
     - Ad unit not approved yet

3. **Verify Configuration:**
   - Double-check all IDs are correct
   - Ensure `_useTestAds = false` for production
   - Verify App IDs match in manifest files

### Test Ads Still Showing

- Make sure `_useTestAds = false` in `ad_service.dart`
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`
- Verify production IDs are correct (not test IDs)

---

## Quick Reference

### File Locations

| File | What to Update | Line Number |
|------|---------------|-------------|
| `lib/services/ad_service.dart` | Production ad unit IDs | ~36-37 |
| `lib/services/ad_service.dart` | `_useTestAds` flag | ~30 |
| `android/app/src/main/AndroidManifest.xml` | Android App ID | ~35 |
| `ios/Runner/Info.plist` | iOS App ID | ~53 |

### ID Format

- **App ID:** `ca-app-pub-XXXXXXXXXX~YYYYYYYYYY` (has a `~`)
- **Ad Unit ID:** `ca-app-pub-XXXXXXXXXX/YYYYYYYYYY` (has a `/`)

---

## Support

- [AdMob Help Center](https://support.google.com/admob)
- [AdMob Policies](https://support.google.com/admob/answer/6128543)
- [Flutter AdMob Plugin](https://pub.dev/packages/google_mobile_ads)

---

**Last Updated:** 2024
**App Version:** 1.0.0+1
