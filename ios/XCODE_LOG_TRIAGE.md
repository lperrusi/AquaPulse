# Xcode device logs — benign vs investigate

Use this when triaging iOS console output from **Runner** / Flutter debug builds. Most recurring lines are **system or framework noise**, not AquaPulse defects.

## Usually safe to ignore (no app code change)

| Pattern | Source |
|--------|--------|
| `FlutterView implements focusItemsInRect` | Flutter engine / UIKit focus |
| `Failed to send CA Event for app launch measurements` | Apple Client Analytics (launch metrics) |
| `SKPaymentQueue` + `SKInternalErrorDomain Code=12` | StoreKit sandbox / remote queue (unless you ship IAP and see real purchase failures) |
| `Could not create a sandbox extension for ... Runner.app` | System sandbox |
| `WebContent` + `Unable to hide query parameters from script` | WebKit (common with ad WebViews) |
| `quic_crypto_queue_append` | QUIC stack internals |
| `nw_connection_copy_* on unconnected nw_connection` | Network framework verbose diagnostics |
| `nw_protocol_instance_set_output_handler` + `udp` | Same |
| CoreMotion + `com.apple.CoreMotion.plist` + permission / `Operation not permitted` | OS managed preferences path |
| `WebProcess::markAllLayersVolatile` | WebKit lifecycle |

## Worth investigating (real problems)

- **Crashes** with Flutter or native stack traces pointing at your code or a plugin.
- **Firebase** errors after startup that repeat on every cold start (e.g. configuration failed, invalid plist).
- **AdMob** load failures with non-recoverable codes in your own `AdService` logs (track separately from `nw_*` noise).
- **User-visible** breakage: blank screen, stuck splash, data not saving.

## Firebase startup note

`[FirebaseCore][I-COR000005] No app has been configured yet` can appear **before** Dart runs `Firebase.initializeApp`. Runner configures Firebase early in `AppDelegate` (`FirebaseApp.configure()`) to reduce that race; Dart still calls `Firebase.initializeApp(options: ...)` for FlutterFire consistency—smoke-test after native changes if anything logs duplicate configuration.
