/// Weather Configuration
///
/// Configuration file for weather service API keys and settings.
/// To use weather features, you need to:
/// 1. Sign up at https://openweathermap.org/api
/// 2. Get your free API key
/// 3. Replace the placeholder below with your actual API key

class WeatherConfig {
  /// OpenWeatherMap API Key
  /// 
  /// Get your free API key from: https://openweathermap.org/api
  /// Replace this with your actual API key to enable weather features
  static const String openWeatherApiKey = 'a0818671fb56460bd8a7686af722a031';
  
  /// Weather update frequency in minutes
  static const int defaultUpdateFrequencyMinutes = 30;
  
  /// Weather cache duration in minutes
  static const int cacheDurationMinutes = 15;
  
  /// Base URL for OpenWeatherMap API
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  /// Units for temperature (metric = Celsius, imperial = Fahrenheit)
  static const String units = 'metric';
  
  /// Check if weather features are enabled
  static bool get isEnabled => openWeatherApiKey.isNotEmpty;
  
  /// Get configuration status message
  static String get statusMessage {
    if (isEnabled) {
      return 'Weather features enabled';
    } else {
      return 'Weather features disabled - API key not configured';
    }
  }
}
