# Publish roadmap – AquaPulse

Use this as your **ordered checklist** to get AquaPulse ready for first release on the App Store and Google Play.  
Details for each step are in [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

---

## ▶ Next: Release on Google Play

Your AAB is built. To publish:

1. **Privacy policy live** – Ensure the repo is public and GitHub Pages serves `/docs` from `main`. Open [privacy policy URL](https://lperrusi.github.io/AquaPulse/privacy-policy.html) and confirm it loads.
2. **Play Console** – Go to [Google Play Console](https://play.google.com/console), create the app (or open it), then:
   - **Release** → create a release → upload `build/app/outputs/bundle/release/app-release.aab` (use **Internal testing** first to test, then **Production** when ready).
   - **Store presence** → **Main store listing**: app name, short & full description, screenshots (phone + optional tablet), app icon 512×512, feature graphic 1024×500, **Privacy policy URL** (same as in `app_urls.dart`), **Support email** (e.g. lucasperrusi@gmail.com).
   - **Policy** → **App content**: complete **Privacy policy** (paste URL), **Ads** (declare “Yes, contains ads”), **Content rating** (fill questionnaire), **Target audience**.
3. **Submit** – When all required fields are green, submit the release for review.

---

## Phase 1 – Must do before first submit

### 1. **Production ads**
- [x] Create app in [AdMob](https://admob.google.com/) and get your **App ID** and **ad unit IDs** (banner + interstitial).
- [x] Replace **test** ad IDs with **production** IDs in:
  - `lib/services/ad_service.dart` (banner + interstitial constants).
  - `android/app/src/main/AndroidManifest.xml` (`APPLICATION_ID` meta-data).
  - `ios/Runner/Info.plist` (add `GADApplicationIdentifier` if missing).

### 2. **Privacy policy (required by both stores)**
- [ ] Publish your privacy policy at a **public URL** (e.g. GitHub Pages, your site, or a policy generator).
- [x] Put the **final** URL in `lib/config/app_urls.dart` → `privacyPolicyUrl`.
- [ ] Use that same URL in **App Store Connect** and **Google Play Console** (store listing → Privacy policy).
- [ ] Optional: add a “Privacy Policy” row in Profile that opens this URL (e.g. with `url_launcher`).

A starter template is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md). Edit it for your app and host it.

### 3. **Android release signing**
- [x] Create a **release keystore** (see PRODUCTION_CHECKLIST.md §6).
- [x] Create `android/key.properties` (do **not** commit it; add to `.gitignore`).
- [x] In `android/app/build.gradle.kts`, configure `signingConfigs` for `release` and use it in `buildTypes.release`.
- [x] Build release AAB: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`

Without this, you can’t upload a release AAB to Play Console.

### 4. **iOS: App Store Connect & signing**
- [x] Set **Bundle ID** to production ID: `com.lucasperrusi.aquapulse` (Runner + RunnerTests in `ios/Runner.xcodeproj/project.pbxproj`).
- [ ] In Xcode: configure **Signing & Capabilities** for release (select your **Team**; automatic signing will create provisioning profiles). See [ios/README_APP_STORE.md](ios/README_APP_STORE.md).
- [x] **Deployment target**: iOS 13.0 (project) / 14.0 (Pods) — both ≥ 12.

### 5. **Store listings**
- [ ] **App name**, **short** and **long description**, **keywords** (iOS) / **short** and **full description** (Android).
- [ ] **Screenshots** for required device sizes (see PRODUCTION_CHECKLIST.md §4).
- [ ] **App icon**: 1024×1024 (iOS), 512×512 (Android). Feature graphic 1024×500 (Android).
- [ ] **Privacy policy URL** (same as in §2).
- [ ] **Support URL** (e.g. email or website); put it in `lib/config/app_urls.dart` → `supportUrl` and use in store listing.
- [ ] **Age rating** and **content rating** (complete the questionnaires in both consoles).

### 6. **Smoke test before submit**
- [x] `flutter build appbundle --release` (Android) — built ✓; upload to **Internal testing** or **Closed testing**, install and test.
- [x] `flutter build ios --release` — built ✓ (Runner.app; use Xcode to codesign & run on device or archive for TestFlight).
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

---

## Known Issues / Deferred

- Full `flutter test` suite currently has legacy flaky widget tests and long-running hangs (not release-blocking for Android publish if targeted regression tests pass).
- Android package identity is still `com.example.hydration_tracker`; keep current Firebase Android app config aligned until you intentionally migrate package ID in Firebase and Android project together.
- Weather API key handling is still source-based; move to `--dart-define` or backend proxy before broader scale/enterprise deployments.

---

## Go/No-Go checklist output

### Must complete before submit

- [x] Static checks pass (`flutter analyze`).
- [x] Regression tests for release-hardening fixes pass (`flutter test test/database_service_reminders_test.dart test/notification_service_test.dart`).
- [x] Android release artifact builds (`flutter build appbundle --release`).
- [x] iOS release artifact builds (`flutter build ios --release --no-codesign`).
- [ ] Manual smoke test on real device for critical user flows in §6 (signup/signin/profile/reminders/ads/intake).
- [ ] Play Console metadata/policy completion in all required sections.

### Can ship with mitigation

- [x] Legacy flaky `flutter test` cases mitigated by targeted regression suite for current publish hardening scope.
- [x] Production logging reduced in auth/profile flows; keep monitoring logs in internal testing.

### Post-launch improvements

- [ ] Migrate Android package identity from default-style namespace with coordinated Firebase re-registration.
- [ ] Move weather key to secure runtime config (`--dart-define`) or backend token relay.
- [ ] Stabilize and unskip/repair full widget test suite to make `flutter test` fully green in CI.
