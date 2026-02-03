# Publish roadmap – AquaPulse

Use this as your **ordered checklist** to get AquaPulse ready for first release on the App Store and Google Play.  
Details for each step are in [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

---

## Phase 1 – Must do before first submit

### 1. **Production ads**
- [ ] Create app in [AdMob](https://admob.google.com/) and get your **App ID** and **ad unit IDs** (banner + interstitial).
- [ ] Replace **test** ad IDs with **production** IDs in:
  - `lib/services/ad_service.dart` (banner + interstitial constants).
  - `android/app/src/main/AndroidManifest.xml` (`APPLICATION_ID` meta-data).
  - `ios/Runner/Info.plist` (add `GADApplicationIdentifier` if missing).

### 2. **Privacy policy (required by both stores)**
- [ ] Publish your privacy policy at a **public URL** (e.g. GitHub Pages, your site, or a policy generator).
- [ ] Put the **final** URL in `lib/config/app_urls.dart` → `privacyPolicyUrl`.
- [ ] Use that same URL in **App Store Connect** and **Google Play Console** (store listing → Privacy policy).
- [ ] Optional: add a “Privacy Policy” row in Profile that opens this URL (e.g. with `url_launcher`).

A starter template is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md). Edit it for your app and host it.

### 3. **Android release signing**
- [ ] Create a **release keystore** (see PRODUCTION_CHECKLIST.md §6).
- [ ] Create `android/key.properties` (do **not** commit it; add to `.gitignore`).
- [ ] In `android/app/build.gradle.kts`, configure `signingConfigs` for `release` and use it in `buildTypes.release`.

Without this, you can’t upload a release AAB to Play Console.

### 4. **iOS: App Store Connect & signing**
- [ ] In Xcode: set **Bundle ID** to your final ID (e.g. `com.yourcompany.aquapulse`).
- [ ] Configure **Signing & Capabilities** for release (Apple Developer account, provisioning profile).
- [ ] Ensure **Deployment target** is at least iOS 12 (or your chosen minimum).

### 5. **Store listings**
- [ ] **App name**, **short** and **long description**, **keywords** (iOS) / **short** and **full description** (Android).
- [ ] **Screenshots** for required device sizes (see PRODUCTION_CHECKLIST.md §4).
- [ ] **App icon**: 1024×1024 (iOS), 512×512 (Android). Feature graphic 1024×500 (Android).
- [ ] **Privacy policy URL** (same as in §2).
- [ ] **Support URL** (e.g. email or website); put it in `lib/config/app_urls.dart` → `supportUrl` and use in store listing.
- [ ] **Age rating** and **content rating** (complete the questionnaires in both consoles).

### 6. **Smoke test before submit**
- [ ] `flutter build appbundle --release` (Android) and upload to **Internal testing** or **Closed testing**; install and test.
- [ ] `flutter build ios --release` and run on a real device; then upload to TestFlight and test.
- [ ] Test: sign up, sign in (email + Google), profile edit (age/gender persist), hydration log, reminders, ads (production), and one full flow without crashes.

---

## Phase 2 – Strongly recommended soon after

- [ ] **Firebase Crashlytics** (and optional Performance) for crash reporting and stability.
- [ ] **Obfuscation** for release builds:  
  `flutter build appbundle --release --obfuscate --split-debug-info=./debug-info` (and same for iOS).
- [ ] **Remove or gate verbose logs**: keep `debugPrint` for development; avoid logging sensitive data in production (or use a logger that respects `kReleaseMode`).
- [ ] **Terms of service** URL (optional but good for trust); add to `app_urls.dart` and store listing if you use it.

---

## Phase 3 – Nice to have

- [ ] In-app “Privacy Policy” / “Terms” link (e.g. Profile or About) using `url_launcher`.
- [ ] Prompt for **App Store / Play Store review** after a positive moment (e.g. goal reached).
- [ ] **Support email** and reply within 24–48 hours.
- [ ] **Analytics**: use Firebase Analytics for key events (intake, goal hit, reminder created) to guide future updates.

---

## Quick reference

| Item              | Where to set / change |
|-------------------|------------------------|
| App version       | `pubspec.yaml` → `version:` (e.g. `1.0.0+1`) |
| Privacy policy URL| `lib/config/app_urls.dart` + App Store Connect + Play Console |
| Support URL       | `lib/config/app_urls.dart` + store listings |
| Ad unit IDs       | `lib/services/ad_service.dart`, AndroidManifest, Info.plist |
| Android signing   | `android/key.properties` + `android/app/build.gradle.kts` |
| iOS signing       | Xcode → Signing & Capabilities |

---

## When you’re ready to submit

1. Bump version/build in `pubspec.yaml` if needed.
2. Build release artifacts (see §6 above).
3. Upload to App Store Connect (iOS) and Google Play Console (Android).
4. Fill in all required fields (descriptions, screenshots, privacy URL, ratings).
5. Submit for review.

After first approval, use the same checklist for each new version (bump version, test, then submit).
