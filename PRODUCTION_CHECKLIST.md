# 🚀 Production Readiness Checklist

This document outlines all the steps needed to prepare AquaPulse for production release.

**→ For a short, ordered list of what to do first, see [PUBLISH_ROADMAP.md](PUBLISH_ROADMAP.md).**

## ✅ COMPLETED

- ✅ Core app functionality working
- ✅ UI/UX design standardized
- ✅ Weather API key configured
- ✅ Firebase initialized
- ✅ Local data persistence working
- ✅ Notifications working
- ✅ App version set (1.0.0+1)
- ✅ Error handling in place (basic)

---

## 🔴 CRITICAL - Must Do Before Production

### 1. **Replace Test Ad Units with Production Ad Units**

**File:** `lib/services/ad_service.dart`

**Current Status:** Using Google test ad unit IDs

**Action Required:**
1. Create AdMob account at https://admob.google.com/
2. Create your app in AdMob
3. Create two ad units:
   - **Banner Ad** (320x50)
   - **Interstitial Ad**
4. Replace test IDs in `ad_service.dart`:
   ```dart
   // Replace these lines (15-16):
   static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
   static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
   
   // With your production IDs:
   static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXXXX/YYYYYYYYYY';
   static const String _interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXX/ZZZZZZZZZZ';
   ```

**File:** `android/app/src/main/AndroidManifest.xml`

**Current Status:** Using test AdMob app ID

**Action Required:**
Replace line 35:
```xml
<!-- Current (test): -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>

<!-- Replace with your production AdMob App ID: -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXX~YYYYYYYYYY"/>
```

**File:** `ios/Runner/Info.plist`

**Action Required:**
Add your AdMob App ID (if not already present):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXX~YYYYYYYYYY</string>
```

---

### 2. **Remove/Replace Debug Print Statements**

**Current Status:** 224+ `print()` statements throughout codebase

**Action Required:**
Replace all `print()` statements with proper logging:

**Option A: Use `debugPrint` (recommended for Flutter)**
```dart
// Replace:
print('Error message');

// With:
debugPrint('Error message'); // Only shows in debug mode
```

**Option B: Use a logging package (better for production)**
```dart
// Add to pubspec.yaml:
// logger: ^2.0.2

// Then use:
import 'package:logger/logger.dart';
final logger = Logger();
logger.e('Error message'); // Error level
logger.w('Warning message'); // Warning level
logger.i('Info message'); // Info level
```

**Files to Update:**
- `lib/services/ad_service.dart` (12 print statements)
- `lib/providers/app_providers.dart` (50+ print statements)
- `lib/services/weather_service.dart` (20+ print statements)
- `lib/services/notification_service.dart` (15+ print statements)
- `lib/services/database_service.dart` (10+ print statements)
- `lib/main.dart` (5 print statements)
- All screen files

**Quick Fix Script:**
```bash
# Find all print statements:
grep -r "print(" lib/ --include="*.dart"

# Consider using sed or find/replace in IDE to replace with debugPrint
```

---

### 3. **Create Privacy Policy**

**Required for:**
- App Store (iOS)
- Google Play Store (Android)
- GDPR compliance (if targeting EU users)
- AdMob requirements

**Action Required:**
1. Create a privacy policy that covers:
   - What data you collect (user profile, water intake, location for weather)
   - How you use the data
   - Third-party services (Firebase, AdMob, OpenWeatherMap)
   - User rights (data deletion, export)
   - Contact information

2. Host it online (GitHub Pages, your website, or privacy policy generator)

3. Add privacy policy URL to:
   - App Store Connect listing
   - Google Play Console listing
   - Settings screen in app (optional but recommended)

**Template:** A starter template is in this repo: `PRIVACY_POLICY.md`. Edit it, host it at a public URL, then set that URL in `lib/config/app_urls.dart` (see `AppUrls.privacyPolicyUrl`) and in your store listings.

Alternatively use a service like:
- https://www.privacypolicygenerator.info/
- https://www.freeprivacypolicy.com/

---

### 4. **App Store Listings**

#### iOS (App Store Connect)

**Required:**
- [ ] App name: "AquaPulse" (or your chosen name)
- [ ] App description (short and long)
- [ ] Keywords (for search optimization)
- [ ] Screenshots (required for all device sizes):
  - iPhone 6.7" (iPhone 14 Pro Max)
  - iPhone 6.5" (iPhone 11 Pro Max)
  - iPhone 5.5" (iPhone 8 Plus)
  - iPad Pro 12.9"
- [ ] App icon (1024x1024px)
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Age rating
- [ ] Pricing (Free with ads)
- [ ] App Store categories

**Screenshot Requirements:**
- Minimum 3 screenshots per device size
- Show key features: dashboard, stats, reminders, profile
- Use actual device screenshots (not simulators if possible)

#### Android (Google Play Console)

**Required:**
- [ ] App name: "AquaPulse"
- [ ] Short description (80 characters)
- [ ] Full description (4000 characters)
- [ ] Screenshots:
  - Phone (at least 2)
  - Tablet (at least 2, if supporting tablets)
  - Feature graphic (1024x500px)
- [ ] App icon (512x512px)
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Store listing categories

---

### 5. **App Icons and Assets**

**Current Status:** Need to verify all required sizes exist

**Action Required:**

**iOS Icons:**
- [ ] App icon set in Xcode (all sizes)
- [ ] Launch screen configured
- [ ] Verify `ios/Runner/Assets.xcassets/AppIcon.appiconset/` has all sizes

**Android Icons:**
- [ ] `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- [ ] Adaptive icon (if using)
- [ ] Feature graphic for Play Store (1024x500px)

**Generate Icons:**
Use tools like:
- https://www.appicon.co/
- https://icon.kitchen/
- https://makeappicon.com/

---

### 6. **Build Configuration**

#### iOS

**File:** `ios/Runner.xcodeproj`

**Check:**
- [ ] Bundle Identifier is set correctly
- [ ] Signing & Capabilities configured
- [ ] Deployment target (iOS 12.0+ recommended)
- [ ] Release build configuration
- [ ] App Transport Security settings

**Build Command:**
```bash
flutter build ios --release
```

#### Android

**File:** `android/app/build.gradle`

**Check:**
- [ ] `applicationId` is set correctly
- [ ] `versionCode` and `versionName` match `pubspec.yaml`
- [ ] Signing config for release (create keystore)
- [ ] Min SDK version (21+ recommended)
- [ ] Target SDK version (latest)

**Create Release Keystore:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Build Command:**
```bash
flutter build appbundle --release
```

---

### 7. **Testing Checklist**

**Before Release:**
- [ ] Test on real iOS device
- [ ] Test on real Android device
- [ ] Test all core features:
  - [ ] Water intake tracking
  - [ ] Daily goal calculation
  - [ ] Reminders (create, edit, delete)
  - [ ] Statistics viewing
  - [ ] Profile editing
  - [ ] Weather integration
  - [ ] Ad display (with production ads)
- [ ] Test edge cases:
  - [ ] No internet connection
  - [ ] Location permission denied
  - [ ] Notification permission denied
  - [ ] Large data sets
- [ ] Performance testing:
  - [ ] App startup time
  - [ ] Memory usage
  - [ ] Battery impact
- [ ] Test on different screen sizes
- [ ] Test on different iOS/Android versions

---

## 🟡 IMPORTANT - Should Do

### 8. **Error Handling & Crash Reporting**

**Current Status:** Basic error handling exists

**Recommended:**
- [ ] Add Firebase Crashlytics for crash reporting
- [ ] Add Firebase Performance Monitoring
- [ ] Improve error messages for users
- [ ] Add offline mode handling

**Add Crashlytics:**
```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

```dart
// main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // ... rest of initialization
}
```

---

### 9. **Analytics Setup**

**Current Status:** Firebase Analytics initialized but not fully utilized

**Recommended:**
- [ ] Track key user events:
  - Water intake recorded
  - Goal achieved
  - Reminder created
  - Profile updated
  - Ad viewed/clicked
- [ ] Set up conversion tracking
- [ ] Monitor user retention

---

### 10. **App Store Optimization (ASO)**

**Keywords Research:**
- [ ] Research competitor apps
- [ ] Identify high-value keywords
- [ ] Optimize app name and description
- [ ] Use relevant categories

**Visual Assets:**
- [ ] Create compelling screenshots
- [ ] Add text overlays highlighting features
- [ ] Create app preview video (optional but recommended)

---

### 11. **Legal & Compliance**

- [ ] Privacy policy (see #3)
- [ ] Terms of service (optional but recommended)
- [ ] GDPR compliance (if targeting EU)
- [ ] COPPA compliance (if targeting children)
- [ ] Data retention policy
- [ ] User data export functionality

---

### 12. **Performance Optimization**

- [ ] Review and optimize app size
- [ ] Remove unused assets
- [ ] Optimize images (compress)
- [ ] Enable code obfuscation for release:
  ```bash
  flutter build apk --release --obfuscate --split-debug-info=./debug-info
  flutter build ios --release --obfuscate --split-debug-info=./debug-info
  ```
- [ ] Test app performance on low-end devices

---

## 🟢 NICE TO HAVE

### 13. **Additional Features**

- [ ] App Store reviews prompt (after positive experience)
- [ ] Share app functionality
- [ ] Rate app prompt
- [ ] Onboarding improvements
- [ ] Help/FAQ section
- [ ] Support email/contact

### 14. **Marketing Preparation**

- [ ] App website/landing page
- [ ] Social media accounts
- [ ] Press kit
- [ ] Launch announcement plan

---

## 📋 PRE-LAUNCH CHECKLIST

**One Week Before Launch:**
- [ ] All critical items completed
- [ ] Final testing on multiple devices
- [ ] App Store listings prepared
- [ ] Privacy policy published
- [ ] Support email ready
- [ ] Marketing materials ready

**Day Before Launch:**
- [ ] Final build created and tested
- [ ] App Store submissions ready
- [ ] All assets uploaded
- [ ] Release notes written

**Launch Day:**
- [ ] Submit to App Store
- [ ] Submit to Google Play
- [ ] Monitor for issues
- [ ] Respond to initial reviews

---

## 🚨 POST-LAUNCH MONITORING

**First Week:**
- [ ] Monitor crash reports
- [ ] Check analytics daily
- [ ] Respond to user reviews
- [ ] Monitor ad revenue
- [ ] Fix critical bugs immediately

**First Month:**
- [ ] Analyze user behavior
- [ ] Optimize ad placement
- [ ] Plan feature updates
- [ ] Gather user feedback

---

## 📝 NOTES

- **Version Numbering:** Current version is `1.0.0+1`. Follow semantic versioning:
  - Major.Minor.Patch+BuildNumber
  - Example: `1.0.1+2` for a bug fix, `1.1.0+3` for new features

- **Ad Revenue:** Monitor AdMob dashboard for:
  - Impressions
  - Clicks
  - Revenue
  - eCPM (effective cost per mille)

- **User Support:** Set up a support email and respond within 24-48 hours

---

## ✅ COMPLETION STATUS

**Critical Items:** 0/7 completed
**Important Items:** 0/5 completed
**Nice to Have:** 0/2 completed

**Estimated Time to Production:** 2-3 weeks (depending on App Store review times)

---

**Last Updated:** [Current Date]
**Next Review:** After completing critical items

