# iOS: App Store Connect & signing

This project is configured for AquaPulse with a production Bundle ID and deployment target. Follow these steps to sign and submit to the App Store.

---

## Current configuration

| Setting | Value |
|--------|--------|
| **Bundle ID** | `com.lucasperrusi.aquapulse` |
| **Deployment target** | iOS 13.0 (project) / 14.0 (Pods) |
| **Version** | From `pubspec.yaml` (`version: 1.0.0+1` → 1.0.0 build 1) |
| **Development team** | Set in Xcode (e.g. your Apple Developer team ID) |

---

## 1. Apple Developer account

- Enroll at [developer.apple.com](https://developer.apple.com/programs/) if you haven’t.
- You need a **Team** (personal or organization) to sign and distribute the app.

---

## 2. Firebase / Google Sign-In (bundle ID)

The app uses Firebase and Google Sign-In. After changing the Bundle ID to `com.lucasperrusi.aquapulse`:

1. Go to [Firebase Console](https://console.firebase.google.com/) → your project (**hydration-tracker-app-2024**).
2. **Project settings** (gear) → **Your apps**.
3. Either **Add app** → iOS → Bundle ID `com.lucasperrusi.aquapulse`, or edit the existing iOS app and set its Bundle ID to `com.lucasperrusi.aquapulse`.
4. Download the new **GoogleService-Info.plist** and replace `ios/Runner/GoogleService-Info.plist` (the one in the repo is already updated to `com.lucasperrusi.aquapulse`; if you use a new plist from Firebase, ensure the Bundle ID in it is `com.lucasperrusi.aquapulse`).
5. In **Google Cloud Console** (APIs & Services → Credentials), ensure the **OAuth 2.0 Client ID** for iOS has the new bundle ID if required for Google Sign-In.

---

## 3. Register the App ID (if needed)

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. **Identifiers** → **+** → **App IDs** → **App**.
3. Description: e.g. **AquaPulse**.
4. Bundle ID: **Explicit** → `com.lucasperrusi.aquapulse`.
5. Enable any capabilities you use (e.g. **Sign in with Apple** if you add it; push if you use it). For AquaPulse (Google Sign-In, no push), the default is usually enough.
6. **Register**.

---

## 4. Xcode: Signing & Capabilities

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select the **Runner** project in the left sidebar, then the **Runner** target.
3. Open the **Signing & Capabilities** tab.
4. **Automatically manage signing**: leave **on**.
5. **Team**: choose your Apple Developer team (your account or organization).  
   - If you see “Failed to register bundle identifier”, the App ID may not exist yet; create it in step 2 with Bundle ID `com.lucasperrusi.aquapulse`.
6. Xcode will create/use a **Provisioning Profile** for `com.lucasperrusi.aquapulse` (Development for running on device, Distribution for App Store).
7. Repeat for the **RunnerTests** target if you run tests on device (same team).

---

## 5. Run on a real device (smoke test)

1. Connect an iPhone (or iPad) and unlock it.
2. In Xcode, select your device as the run destination.
3. **Product** → **Run** (or ⌘R).
4. If prompted, trust the developer on the device: **Settings** → **General** → **VPN & Device Management** → your developer certificate → **Trust**.

---

## 6. App Store Connect: create the app

1. Go to [App Store Connect](https://appstoreconnect.apple.com/) → **My Apps**.
2. **+** → **New App**.
3. **Platforms**: iOS.
4. **Name**: AquaPulse (or your store name).
5. **Primary Language**: e.g. English (U.S.).
6. **Bundle ID**: choose **com.lucasperrusi.aquapulse** (must match Xcode; it appears after the App ID is registered).
7. **SKU**: e.g. `aquapulse-ios-1` (internal identifier, not shown to users).
8. **User Access**: Full Access (or limit if you use a team).
9. **Create**.

---

## 7. Archive and upload

1. In Xcode, set the run destination to **Any iOS Device (arm64)** (not a simulator).
2. **Product** → **Archive**.
3. When the Organizer opens, select the new archive → **Distribute App**.
4. **App Store Connect** → **Upload** → follow the prompts (sign with your distribution certificate / let Xcode manage signing).
5. After upload, go to App Store Connect → your app → **TestFlight** (for beta) or **App Store** tab to attach the build to a version and submit for review.

---

## 8. Fill store listing and submit

In App Store Connect, complete at least:

- **App Information**: name, subtitle, privacy policy URL (e.g. `https://lperrusi.github.io/AquaPulse/privacy-policy.html`), category, etc.
- **Pricing and Availability**.
- **App Privacy**: privacy practices, data collection (e.g. if you use analytics/ads).
- **Version information**: description, keywords, screenshots (required sizes), support URL (e.g. `mailto:lucasperrusi@gmail.com`).
- **Build**: select the build you uploaded.
- **Content rights / Age rating** etc. as required.

Then submit the version for **App Review**.

---

## Optional: change Bundle ID

If you want a different Bundle ID (e.g. `com.yourcompany.aquapulse`):

1. In Xcode: **Runner** target → **General** → **Bundle Identifier**.
2. In `ios/Runner.xcodeproj/project.pbxproj`: replace `com.lucasperrusi.aquapulse` with your new ID (Runner and RunnerTests).
3. Register the new App ID in the Apple Developer portal and create the app in App Store Connect with that Bundle ID.

---

## Deployment target

- **Project**: iOS 13.0 (in `project.pbxproj`).
- **Pods**: 14.0 (in `Podfile`).

Both are ≥ 12. To change the project minimum: **Runner** target → **General** → **Minimum Deployments**, and align the Podfile `platform :ios` / `IPHONEOS_DEPLOYMENT_TARGET` if needed.
