/// Weather Settings Screen
///
/// Allows users to configure weather update frequency and other weather-related settings.
/// Provides options for background updates, update intervals, and weather preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/weather_service.dart';
import '../utils/neumorphic_style.dart';

/// The main WeatherSettingsScreen widget for configuring weather settings
class WeatherSettingsScreen extends ConsumerStatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  ConsumerState<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends ConsumerState<WeatherSettingsScreen> {
  Duration _selectedFrequency = const Duration(minutes: 30);
  bool _backgroundUpdatesEnabled = true;
  bool _autoRefreshEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final weatherService = WeatherService();
      final frequency = await weatherService.getUpdateFrequency();
      
      setState(() {
        _selectedFrequency = frequency;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading weather settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherData = ref.watch(weatherProvider);
    final lastUpdateTime = ref.watch(weatherProvider.notifier).lastUpdateTime;

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Weather Settings',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: NeumorphicStyle.darkText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current weather status
                  _buildWeatherStatusCard(weatherData, lastUpdateTime, theme),
                  
                  const SizedBox(height: 24),
                  
                  // Update frequency settings
                  _buildUpdateFrequencyCard(theme),
                  
                  const SizedBox(height: 16),
                  
                  // Background updates settings
                  _buildBackgroundUpdatesCard(theme),
                  
                  const SizedBox(height: 16),
                  
                  // Auto refresh settings
                  _buildAutoRefreshCard(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Weather information
                  _buildWeatherInfoCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherStatusCard(weatherData, lastUpdateTime, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Current Weather Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (weatherData != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherData.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${weatherData.temperature.toInt()}°C, ${weatherData.humidity.toInt()}% humidity',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      weatherData.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Weather data unavailable',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            if (lastUpdateTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${_formatLastUpdate(lastUpdateTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateFrequencyCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Update Frequency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._getFrequencyOptions().map((option) => RadioListTile<Duration>(
              title: Text(option['title'] as String),
              subtitle: Text(option['subtitle'] as String),
              value: option['duration'] as Duration,
              groupValue: _selectedFrequency,
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
                _updateFrequency(value!);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundUpdatesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Background Updates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Enable background updates'),
              subtitle: const Text('Automatically update weather data in the background'),
              value: _backgroundUpdatesEnabled,
              onChanged: (value) {
                setState(() {
                  _backgroundUpdatesEnabled = value;
                });
                _toggleBackgroundUpdates(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoRefreshCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.refresh, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Auto Refresh',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Auto refresh when data is stale'),
              subtitle: const Text('Automatically refresh weather data when it becomes outdated'),
              value: _autoRefreshEnabled,
              onChanged: (value) {
                setState(() {
                  _autoRefreshEnabled = value;
                });
                _toggleAutoRefresh(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Weather Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Data Source', 'OpenWeatherMap API'),
            _buildInfoRow('Location Services', 'GPS-based location'),
            _buildInfoRow('Cache Duration', '1 hour'),
            _buildInfoRow('Update Interval', '${_selectedFrequency.inMinutes} minutes'),
            _buildInfoRow('Background Updates', _backgroundUpdatesEnabled ? 'Enabled' : 'Disabled'),
            _buildInfoRow('Auto Refresh', _autoRefreshEnabled ? 'Enabled' : 'Disabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFrequencyOptions() {
    return [
      {
        'title': 'Every 15 minutes',
        'subtitle': 'Frequent updates for accurate data',
        'duration': const Duration(minutes: 15),
      },
      {
        'title': 'Every 30 minutes',
        'subtitle': 'Balanced updates (recommended)',
        'duration': const Duration(minutes: 30),
      },
      {
        'title': 'Every hour',
        'subtitle': 'Less frequent updates to save battery',
        'duration': const Duration(hours: 1),
      },
      {
        'title': 'Every 2 hours',
        'subtitle': 'Minimal updates for battery saving',
        'duration': const Duration(hours: 2),
      },
    ];
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

  Future<void> _updateFrequency(Duration frequency) async {
    try {
      await ref.read(weatherProvider.notifier).setUpdateFrequency(frequency);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update frequency set to ${frequency.inMinutes} minutes')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update frequency')),
      );
    }
  }

  void _toggleBackgroundUpdates(bool enabled) {
    if (enabled) {
      ref.read(weatherProvider.notifier).setUpdateFrequency(_selectedFrequency);
    } else {
      // Stop background updates
      // This would be handled by the weather service
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Background updates ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  void _toggleAutoRefresh(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto refresh ${enabled ? 'enabled' : 'disabled'}')),
    );
  }
} 