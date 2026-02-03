/// App URLs for store listings and in-app links.
///
/// Use the same values in App Store Connect and Google Play Console.
class AppUrls {
  AppUrls._();

  /// Privacy policy – required by App Store and Google Play.
  /// Served via GitHub Pages: https://github.com/lperrusi/AquaPulse
  static const String privacyPolicyUrl =
      'https://lperrusi.github.io/AquaPulse/privacy-policy.html';

  /// Support – mailto link; use in store listing and optionally in app.
  static const String supportUrl = 'mailto:lucasperrusi@gmail.com';

  /// Terms of service – optional; add to store listing if you use it.
  static const String termsOfServiceUrl =
      'https://lperrusi.github.io/AquaPulse/terms.html';
}
