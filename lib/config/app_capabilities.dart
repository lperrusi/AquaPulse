library;

/// Centralized feature toggles used to keep auth/cloud code in place while
/// running the app in temporary offline-first mode.
class AppCapabilities {
  static const bool authEnabled = false;
  static const bool cloudSocialEnabled = false;
}
