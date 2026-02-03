/// Weather Service
///
/// Handles real-time weather data integration, location services, and weather-based hydration adjustments.
/// Integrates with OpenWeatherMap API and device location services.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/weather_config.dart';

/// Weather data model for storing current weather information
class WeatherData {
  final double temperature;
  final double humidity;
  final String description;
  final String icon;
  final DateTime timestamp;
  final String location;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.location,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: (json['main']['humidity'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      timestamp: DateTime.now(),
      location: json['name'] as String,
    );
  }

  /// Factory constructor for loading from cache (flat JSON format)
  factory WeatherData.fromCacheJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'description': description,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
  }
}

/// Service class for weather data integration and location services
class WeatherService {
  static const String _apiKey = WeatherConfig.openWeatherApiKey;
  static const String _baseUrl = WeatherConfig.baseUrl;
  static const String _weatherCacheKey = 'weather_cache';
  static const String _lastUpdateKey = 'weather_last_update';
  
  static WeatherService? _instance;
  factory WeatherService() => _instance ??= WeatherService._internal();
  WeatherService._internal();

  Timer? _backgroundTimer;
  StreamController<WeatherData>? _weatherStreamController;
  WeatherData? _lastWeatherData;

  /// Gets current weather data for the user's location
  Future<WeatherData?> getCurrentWeather() async {
    try {
      // Check cache first
      final cachedWeather = await _getCachedWeather();
      if (cachedWeather != null && _isWeatherDataRecent(cachedWeather)) {
        return cachedWeather;
      }

      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) return cachedWeather; // Return cached data if location unavailable

      // Check if API key is configured
      if (_apiKey.isEmpty) {
        debugPrint('Weather API key not configured. Weather features disabled.');
        return cachedWeather ?? _getDefaultWeatherData();
      }

      // Get weather data from API
      final response = await http.get(Uri.parse(
        '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=${WeatherConfig.units}'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = WeatherData.fromJson(data);
        
        // Cache the new weather data
        await _cacheWeatherData(weatherData);
        
        // Update stream if available
        _lastWeatherData = weatherData;
        _weatherStreamController?.add(weatherData);
        
        return weatherData;
      } else if (response.statusCode == 401) {
        debugPrint('Weather API error: 401 - Invalid API key. Please configure a valid OpenWeatherMap API key.');
        return cachedWeather ?? _getDefaultWeatherData();
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return cachedWeather ?? _getDefaultWeatherData(); // Return cached data on API error
      }
    } catch (e) {
      debugPrint('Error getting weather data: $e');
      return await _getCachedWeather(); // Return cached data on error
    }
  }

  /// Starts background weather updates
  void startBackgroundUpdates({Duration interval = const Duration(minutes: 30)}) {
    _stopBackgroundUpdates(); // Stop any existing timer
    
    // Don't start background updates if API key is not configured
    if (_apiKey.isEmpty) {
      debugPrint('Weather API key not configured. Background weather updates disabled.');
      return;
    }
    
    _backgroundTimer = Timer.periodic(interval, (timer) async {
      try {
        await getCurrentWeather();
        debugPrint('Background weather update completed');
      } catch (e) {
        debugPrint('Background weather update failed: $e');
      }
    });
    
    debugPrint('Background weather updates started with ${interval.inMinutes} minute interval');
  }

  /// Stops background weather updates
  void stopBackgroundUpdates() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    debugPrint('Background weather updates stopped');
  }

  /// Gets weather data stream for real-time updates
  Stream<WeatherData> get weatherStream {
    _weatherStreamController ??= StreamController<WeatherData>.broadcast();
    
    // If we have cached data, emit it immediately
    if (_lastWeatherData != null) {
      _weatherStreamController!.add(_lastWeatherData!);
    }
    
    return _weatherStreamController!.stream;
  }

  /// Forces a weather refresh
  Future<WeatherData?> forceRefresh() async {
    // Clear cache to force fresh data
    await _clearWeatherCache();
    return await getCurrentWeather();
  }

  /// Gets weather data with automatic refresh if needed
  Future<WeatherData?> getWeatherWithAutoRefresh() async {
    final weather = await getCurrentWeather();
    
    // If data is stale, refresh in background
    if (weather != null && !_isWeatherDataRecent(weather)) {
      _refreshInBackground();
    }
    
    return weather;
  }

  /// Gets current position with proper permissions
  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Calculates weather-based hydration adjustment factor
  double calculateWeatherAdjustment(WeatherData weather) {
    double adjustment = 1.0;

    // Temperature adjustments
    if (weather.temperature > 25) {
      adjustment += 0.1; // 10% increase for temperatures above 25°C
    }
    if (weather.temperature >= 30) {
      adjustment += 0.15; // Additional 15% for temperatures at or above 30°C
    }
    if (weather.temperature >= 35) {
      adjustment += 0.2; // Additional 20% for very high temperatures
    }

    // Humidity adjustments
    if (weather.humidity > 70) {
      adjustment += 0.05; // 5% increase for humidity above 70%
    }
    if (weather.humidity > 80) {
      adjustment += 0.1; // Additional 10% for very high humidity
    }

    // Activity level adjustments based on weather
    if (weather.description.toLowerCase().contains('sunny') || 
        weather.description.toLowerCase().contains('clear')) {
      adjustment += 0.05; // 5% increase for sunny weather
    }

    return adjustment.clamp(1.0, 2.0); // Limit adjustment between 100% and 200%
  }

  /// Gets location name from coordinates
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}'.trim();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting location name: $e');
      return null;
    }
  }

  /// Checks if weather data is recent (within last hour)
  bool isWeatherDataRecent(WeatherData weather) {
    final now = DateTime.now();
    final difference = now.difference(weather.timestamp);
    return difference.inHours < 1;
  }

  /// Private method to check if weather data is recent
  bool _isWeatherDataRecent(WeatherData weather) {
    return isWeatherDataRecent(weather);
  }

  /// Stops background updates
  void _stopBackgroundUpdates() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  /// Caches weather data locally
  Future<void> _cacheWeatherData(WeatherData weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weatherCacheKey, json.encode(weather.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  /// Gets cached weather data
  Future<WeatherData?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_weatherCacheKey);
      
      if (cachedData != null) {
        final weatherJson = json.decode(cachedData) as Map<String, dynamic>;
        // Use fromCacheJson for cached data (flat format) instead of fromJson (API format)
        return WeatherData.fromCacheJson(weatherJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached weather: $e');
      return null;
    }
  }

  /// Clears weather cache
  Future<void> _clearWeatherCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weatherCacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing weather cache: $e');
    }
  }

  /// Refreshes weather data in background
  void _refreshInBackground() {
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await getCurrentWeather();
      } catch (e) {
        debugPrint('Background refresh failed: $e');
      }
    });
  }

  /// Gets last update time
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
    } catch (e) {
      debugPrint('Error getting last update time: $e');
      return null;
    }
  }

  /// Gets weather update frequency settings
  Future<Duration> getUpdateFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final frequencyMinutes = prefs.getInt('weather_update_frequency') ?? 30;
      return Duration(minutes: frequencyMinutes);
    } catch (e) {
      debugPrint('Error getting update frequency: $e');
      return const Duration(minutes: 30);
    }
  }

  /// Sets weather update frequency
  Future<void> setUpdateFrequency(Duration frequency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weather_update_frequency', frequency.inMinutes);
      
      // Restart background updates with new frequency
      if (_backgroundTimer != null) {
        startBackgroundUpdates(interval: frequency);
      }
    } catch (e) {
      debugPrint('Error setting update frequency: $e');
    }
  }

  /// Gets default weather data when API is unavailable
  WeatherData _getDefaultWeatherData() {
    return WeatherData(
      temperature: 22.0, // Default room temperature
      humidity: 50.0,    // Default moderate humidity
      description: 'Weather data unavailable',
      icon: '01d',       // Default clear sky icon
      timestamp: DateTime.now(),
      location: 'Unknown',
    );
  }

  /// Disposes of resources
  void dispose() {
    stopBackgroundUpdates();
    _weatherStreamController?.close();
    _weatherStreamController = null;
  }

  /// Gets weather-based hydration tip
  String getWeatherHydrationTip(WeatherData weather) {
    if (weather.temperature >= 30) {
      return '🌡️ High temperature detected! Increase your water intake to stay hydrated.';
    } else if (weather.humidity > 80) {
      return '💧 High humidity! You may need more water than usual.';
    } else if (weather.temperature > 25) {
      return '☀️ Warm weather! Remember to drink water regularly.';
    } else {
      return '💧 Stay hydrated! Even in mild weather, water is essential.';
    }
  }
} 