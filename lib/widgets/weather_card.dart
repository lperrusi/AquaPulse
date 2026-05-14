/// Weather Card Widget
///
/// Displays current weather information and weather-based hydration adjustments.
/// Shows temperature, humidity, location, and weather-based hydration tips.
// ignore_for_file: deprecated_member_use, unused_element
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/weather_service.dart';
import '../utils/neumorphic_style.dart';
import '../screens/weather_settings_screen.dart';

/// Widget that displays current weather information and weather-based hydration adjustments
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherData = ref.watch(weatherProvider);
    final weatherService = WeatherService();

    // Weather Card - matches Figma exactly
    return Container(
      padding: const EdgeInsets.all(20), // p-5 = 20px
      decoration: BoxDecoration(
        gradient: NeumorphicStyle.primaryGradient(),
        borderRadius: BorderRadius.circular(16), // rounded-2xl = 16px
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: weatherData == null
          ? Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.white,
                  size: 20, // w-5 h-5 = 20px
                ),
                const SizedBox(width: 12), // gap-2 = 12px
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weather Recommendation',
                        style: TextStyle(
                          fontSize: 16, // font-semibold
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enable location for personalized hydration recommendations based on weather',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9), // opacity-90
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(weatherProvider.notifier).refreshWeather(),
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Retry weather',
                ),
                IconButton(
                  onPressed: () => _openWeatherSettings(context),
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - matches Figma
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // p-1.5 = 8px
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // bg-white/20
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2 = 8px
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather Recommendation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            weatherData.location,
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: Colors.white.withOpacity(0.9), // opacity-90
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(weatherProvider.notifier).refreshWeather(),
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16, // w-4 h-4 = 16px
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // mb-3 = 12px
                // Weather info - matches Figma
                Row(
                  children: [
                    // Temperature and humidity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${weatherData.temperature.toInt()}°C',
                              style: const TextStyle(
                                fontSize: 24, // text-2xl
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${weatherData.humidity.toInt()}%',
                              style: TextStyle(
                                fontSize: 18, // text-lg
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24), // gap-6 = 24px
                    // Recommendation text
                    Expanded(
                      child: Text(
                        weatherService.getWeatherHydrationTip(weatherData),
                        style: TextStyle(
                          fontSize: 14, // text-sm
                          color: Colors.white.withOpacity(0.95), // opacity-95
                          height: 1.4, // leading-relaxed
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _openWeatherSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeatherSettingsScreen(),
      ),
    );
  }
} 