/// Weather Configuration
///
/// Production weather uses a **Firebase Callable** proxy; the OpenWeather key
/// lives in Cloud Functions secrets (`OPENWEATHER_API_KEY`), not in the app.
///
/// Optional compile-time key for **local/dev direct API** fallback only:
/// `--dart-define=OPEN_WEATHER_API_KEY=your_key`
library;

class WeatherConfig {
  /// Optional dev-only OpenWeather key (direct HTTP from the app).
  /// Release builds can omit this when `getCurrentWeatherProxy` is deployed.
  static const String openWeatherApiKey =
      String.fromEnvironment('OPEN_WEATHER_API_KEY', defaultValue: '');
  
  /// Weather update frequency in minutes
  static const int defaultUpdateFrequencyMinutes = 30;
  
  /// Weather cache duration in minutes
  static const int cacheDurationMinutes = 15;
  
  /// Base URL for OpenWeatherMap API
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  /// Units for temperature (metric = Celsius, imperial = Fahrenheit)
  static const String units = 'metric';
  
  /// True when a direct client API key is compiled in (dev fallback).
  /// Signed-in users can still use weather via the server proxy without this.
  static bool get isEnabled => openWeatherApiKey.isNotEmpty;
  
  /// Get configuration status message
  static String get statusMessage {
    if (isEnabled) {
      return 'Direct weather API key configured (dev fallback)';
    }
    return 'Using server weather proxy when signed in (no client API key)';
  }
}
