/// Statistics Screen
///
/// Displays weekly and daily hydration statistics, charts, and achievement progress for the user.
/// Uses Riverpod for state management and fl_chart for visualizations.
// ignore_for_file: deprecated_member_use, unused_field, unused_local_variable, unused_element, dead_null_aware_expression
library;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';
import '../models/water_intake.dart';
import '../models/achievement.dart';
import '../utils/neumorphic_style.dart';

/// The main StatsScreen widget, which is a stateful consumer widget for hydration statistics and analytics.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

/// State class for StatsScreen. Handles week selection, data loading, and chart rendering.
class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  int _selectedWeekIndex = 0;
  final List<String> _weekLabels = ['This Week', 'Last Week', '2 Weeks Ago'];
  
  late TabController _tabController;
  List<Achievement> _achievements = [];
  bool _isLoadingAchievements = true;
  List<WaterIntake> _allHistoricalIntakes = []; // Store all historical intakes
  bool _isLoadingHistoricalData = true;
  int _lastSyncedWaterIntakeCount = -1;
  String _lastStatsDebugSignature = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeekData();
    _loadAchievements();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAchievements() async {
    setState(() => _isLoadingAchievements = true);
    
    try {
      // Load all achievements and check unlock status
      final allAchievements = AchievementDefinitions.allAchievements;
      final user = ref.read(currentUserProvider);
      final hydrationState = ref.read(hydrationStateProvider);
      
      // Check which achievements are unlocked
      final updatedAchievements = allAchievements.map((achievement) {
        bool isUnlocked = false;
        DateTime? unlockedAt;
        
        switch (achievement.type) {
          case AchievementType.streak:
            final currentStreak = hydrationState.currentStreak ?? 0;
            isUnlocked = currentStreak >= achievement.requirement;
            if (isUnlocked && achievement.unlockedAt == null) {
              unlockedAt = DateTime.now();
            }
            break;
            
          case AchievementType.goal:
            // Check if user has met their daily goal consistently
            final goalAchievements = [7, 30]; // Days in a row
            final currentGoal = hydrationState.dailyGoal;
            final todayIntake = hydrationState.todayIntake;
            
            // Check if today's goal was met
            if (todayIntake >= currentGoal) {
              // For demo purposes, unlock based on current streak
              isUnlocked = hydrationState.currentStreak >= achievement.requirement;
              if (isUnlocked && achievement.unlockedAt == null) {
                unlockedAt = DateTime.now();
              }
            }
            break;

          case AchievementType.milestone:
            // Calculate total intake from all water intakes
            final totalIntake = hydrationState.totalIntake ?? 0;
            isUnlocked = totalIntake >= achievement.requirement;
            if (isUnlocked && achievement.unlockedAt == null) {
              unlockedAt = DateTime.now();
            }
            break;
            
          case AchievementType.social:
            isUnlocked = false;
            break;
            
          case AchievementType.special:
            isUnlocked = false;
            break;
        }
        
        return achievement.copyWith(
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAt ?? achievement.unlockedAt,
        );
      }).toList();
      
      setState(() {
        _achievements = updatedAchievements;
        _isLoadingAchievements = false;
      });
    } catch (e) {
      setState(() => _isLoadingAchievements = false);
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _loadWeekData() async {
    if (!mounted) return;
    setState(() => _isLoadingHistoricalData = true);
    final user = ref.read(currentUserProvider);
    final databaseService = ref.read(databaseServiceProvider);
    
    if (user != null) {
      try {
        // Load all intakes for the user (historical data) - only once
        final allIntakes = await databaseService.getAllWaterIntakesForUser(user.id);
        
        if (mounted) {
          setState(() {
            _allHistoricalIntakes = allIntakes;
            _isLoadingHistoricalData = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading historical data: $e');
        if (mounted) {
          setState(() {
            _allHistoricalIntakes = [];
            _isLoadingHistoricalData = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _allHistoricalIntakes = [];
          _isLoadingHistoricalData = false;
        });
      }
    }
  }

  void _showWeekSelectionMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: NeumorphicStyle.backgroundBlue,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NeumorphicStyle.primaryBlue.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: NeumorphicStyle.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Week',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a week to view',
                            style: NeumorphicStyle.neumorphicText(
                              fontSize: 12,
                              color: NeumorphicStyle.lightText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeumorphicStyle.surfaceBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: NeumorphicStyle.lightText,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Week options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: List.generate(_weekLabels.length, (index) {
                    final isSelected = index == _selectedWeekIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  NeumorphicStyle.primaryBlue.withOpacity(0.15),
                                  NeumorphicStyle.primaryBlue.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : NeumorphicStyle.surfaceBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? NeumorphicStyle.primaryBlue.withOpacity(0.3)
                              : NeumorphicStyle.softBorder.withOpacity(0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedWeekIndex = index;
                            });
                            Navigator.pop(context);
                            // No need to reload - we filter from already loaded historical data
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected ? null : NeumorphicStyle.surfaceBlue.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_view_week,
                                    color: isSelected ? Colors.white : NeumorphicStyle.lightText,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _weekLabels[index],
                                    style: NeumorphicStyle.neumorphicText(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? NeumorphicStyle.primaryBlue : NeumorphicStyle.darkText,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hydrationState = ref.watch(hydrationStateProvider);
    // Watch water intake provider to refresh stats when intake count changes.
    final waterIntakes = ref.watch(waterIntakeProvider);
    final weekRange = _getSelectedWeekRange();

    final currentWaterIntakeCount = waterIntakes.length;
    if (currentWaterIntakeCount != _lastSyncedWaterIntakeCount) {
      _lastSyncedWaterIntakeCount = currentWaterIntakeCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadWeekData();
        }
      });
    }
    
    // Filter all historical intakes for the selected week range
    final weeklyIntakes = _filterIntakesByDateRange(_allHistoricalIntakes, weekRange.start, weekRange.end);
    
    // Debug logs only when selected stats snapshot changes.
    if (kDebugMode) {
      final signature =
          '${_allHistoricalIntakes.length}|${weeklyIntakes.length}|${weekRange.start.millisecondsSinceEpoch}|${weekRange.end.millisecondsSinceEpoch}';
      if (signature != _lastStatsDebugSignature) {
        _lastStatsDebugSignature = signature;
        debugPrint(
            'Stats Screen - Total historical intakes: ${_allHistoricalIntakes.length}');
        debugPrint(
            'Stats Screen - Weekly intakes for selected week: ${weeklyIntakes.length}');
        if (weeklyIntakes.isNotEmpty) {
          debugPrint(
              'Stats Screen - First intake: ${weeklyIntakes.first.amount}ml at ${weeklyIntakes.first.timestamp}');
          debugPrint('Stats Screen - Week range: ${weekRange.start} to ${weekRange.end}');
        }
      }
    }

    // Calculate stats
    final currentStreak = hydrationState.currentStreak ?? 0;
    final goalsAchieved = _calculateGoalsAchieved(weeklyIntakes, hydrationState.dailyGoal);
    final averageDaily = _calculateAverageDaily(weeklyIntakes);
    final totalThisWeek = _calculateTotalThisWeek(weeklyIntakes);

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue, // #FAFCFF
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // pb-24 = 96px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header - matches Figma: px-6 py-6
              Padding(
                padding: const EdgeInsets.all(24), // px-6 py-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 24, // text-2xl = 24px
                        fontWeight: FontWeight.bold,
                        color: NeumorphicStyle.darkText,
                      ),
                    ),
                    const SizedBox(height: 4), // mt-1 = 4px
                    Text(
                      'Track your hydration progress',
                      style: TextStyle(
                        fontSize: 14, // text-sm = 14px
                        color: NeumorphicStyle.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content - matches Figma: px-6 space-y-6 max-w-2xl mx-auto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24), // px-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Cards - matches Figma: grid grid-cols-2 gap-4
                    _buildStatsCards(
                      currentStreak: currentStreak,
                      goalsAchieved: goalsAchieved,
                      averageDaily: averageDaily,
                      totalThisWeek: totalThisWeek,
                    ),
                    const SizedBox(height: 24), // space-y-6 = 24px
                    
                    // Weekly Chart - matches Figma
                    _buildWeeklyChart(weeklyIntakes.cast<WaterIntake>(), weekRange.start),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards({
    required int currentStreak,
    required int goalsAchieved,
    required double averageDaily,
    required double totalThisWeek,
  }) {
    final stats = [
      {
        'icon': Icons.local_fire_department,
        'label': 'Current Streak',
        'value': '$currentStreak days',
        'color': const Color(0xFFFF6B35), // Flame color
      },
      {
        'icon': Icons.flag,
        'label': 'Goals Achieved',
        'value': '$goalsAchieved/7 days',
        'color': NeumorphicStyle.primaryBlue,
      },
      {
        'icon': Icons.trending_up,
        'label': 'Average Daily',
        'value': '${averageDaily.toInt()} ml',
        'color': const Color(0xFF10B981), // success-green
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Total This Week',
        'value': '${totalThisWeek.toInt()} ml',
        'color': NeumorphicStyle.golden,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16, // gap-4 = 16px
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final icon = stat['icon'] as IconData;
        final label = stat['label'] as String;
        final value = stat['value'] as String;
        final color = stat['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(16), // p-4 = 16px
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // rounded-2xl
            boxShadow: [
              BoxShadow(
                color: NeumorphicStyle.primaryBlue.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon - matches Figma: w-10 h-10 rounded-full
              Container(
                width: 40, // w-10 = 40px
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2), // color20 = 20% opacity
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20, // w-5 h-5 = 20px
                ),
              ),
              const SizedBox(height: 12), // mb-3 = 12px
              // Value - matches Figma: text-2xl font-bold
              Text(
                value,
                style: TextStyle(
                  fontSize: 24, // text-2xl = 24px
                  fontWeight: FontWeight.bold,
                  color: NeumorphicStyle.darkText,
                ),
              ),
              const SizedBox(height: 4), // mb-1 = 4px
              // Label - matches Figma: text-sm
              Text(
                label,
                style: TextStyle(
                  fontSize: 14, // text-sm = 14px
                  color: NeumorphicStyle.lightText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart(List<WaterIntake> weeklyIntakes, DateTime weekStart) {
    // Prepare data for the week
    final dailyData = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayIntakes = weeklyIntakes.where((intake) {
        return intake.timestamp.year == date.year &&
            intake.timestamp.month == date.month &&
            intake.timestamp.day == date.day;
      }).toList();
      final total = dayIntakes.fold<double>(0, (sum, intake) => sum + intake.amount);
      return {'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index], 'amount': total};
    });

    // Calculate maxY with proper handling for zero values
    final maxAmount = dailyData.map((d) => d['amount'] as double).reduce((a, b) => a > b ? a : b);
    
    // Calculate maxY with smart rounding based on the value range
    double maxY;
    if (maxAmount == 0) {
      maxY = 100.0; // Default scale when no data
    } else {
      final rawMax = maxAmount * 1.2; // Add 20% padding
      // Round up to a nice number based on the magnitude
      if (rawMax <= 50) {
        maxY = (rawMax / 10).ceil() * 10.0; // Round to nearest 10
      } else if (rawMax <= 200) {
        maxY = (rawMax / 20).ceil() * 20.0; // Round to nearest 20
      } else if (rawMax <= 500) {
        maxY = (rawMax / 50).ceil() * 50.0; // Round to nearest 50
      } else {
        maxY = (rawMax / 100).ceil() * 100.0; // Round to nearest 100
      }
    }
    
    // Calculate interval for Y-axis labels (show 5 intervals)
    final yInterval = maxY / 5;

    return Container(
      padding: const EdgeInsets.all(20), // p-5 = 20px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title - matches Figma: text-lg font-semibold
          Text(
            'This Week\'s Progress',
            style: TextStyle(
              fontSize: 18, // text-lg = 18px
              fontWeight: FontWeight.w600, // font-semibold
              color: NeumorphicStyle.darkText,
            ),
          ),
          const SizedBox(height: 16), // mb-4 = 16px
          
          // Chart - matches Figma
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < 7) {
                          return Text(
                            dailyData[value.toInt()]['day'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: NeumorphicStyle.lightText,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40, // Reserve space for Y-axis labels
                      interval: yInterval, // Use calculated interval
                      getTitlesWidget: (value, meta) {
                        // Only show labels at clean intervals (0, 20, 40, 60, etc.)
                        // Check if value is close to an integer multiple of interval
                        final roundedValue = (value / yInterval).round() * yInterval;
                        if ((value - roundedValue).abs() < 0.1) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${roundedValue.toInt()}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: NeumorphicStyle.lightText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval, // Use calculated interval
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: NeumorphicStyle.softBorder.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final data = dailyData[index];
                  final amount = data['amount'] as double;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        gradient: NeumorphicStyle.primaryGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16), // mt-4 = 16px
          
          // Legend - matches Figma
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12, // w-3 = 12px
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: NeumorphicStyle.primaryGradient(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8), // gap-2 = 8px
                Text(
                  'Daily Intake (ml)',
                  style: TextStyle(
                    fontSize: 14, // text-sm = 14px
                    color: NeumorphicStyle.lightText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateGoalsAchieved(List<WaterIntake> weeklyIntakes, double dailyGoal) {
    if (dailyGoal == 0) return 0;
    
    final dailyTotals = <DateTime, double>{};
    for (final intake in weeklyIntakes) {
      final date = DateTime(intake.timestamp.year, intake.timestamp.month, intake.timestamp.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + intake.amount;
    }
    
    return dailyTotals.values.where((total) => total >= dailyGoal).length;
  }

  double _calculateAverageDaily(List<WaterIntake> weeklyIntakes) {
    if (weeklyIntakes.isEmpty) return 0;
    final total = weeklyIntakes.fold<double>(0, (sum, intake) => sum + intake.amount);
    return total / 7;
  }

  double _calculateTotalThisWeek(List<WaterIntake> weeklyIntakes) {
    return weeklyIntakes.fold<double>(0, (sum, intake) => sum + intake.amount);
  }

  // Helper methods for date filtering and calculations
  _WeekRange _getSelectedWeekRange() {
    final now = DateTime.now();
    // Calculate the start of the current week (Monday)
    final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfCurrentWeekDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
    
    // Calculate the start date based on selected week index
    // 0 = This Week, 1 = Last Week, 2 = 2 Weeks Ago
    final weeksToSubtract = _selectedWeekIndex;
    final start = startOfCurrentWeekDate.subtract(Duration(days: 7 * weeksToSubtract));
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return _WeekRange(start, end);
  }

  List<WaterIntake> _filterIntakesByDateRange(List<WaterIntake> intakes, DateTime start, DateTime end) {
    return intakes.where((intake) {
      // Normalize intake timestamp to just the date (remove time component)
      final intakeDate = DateTime(intake.timestamp.year, intake.timestamp.month, intake.timestamp.day);
      // Normalize start and end to just dates
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      
      // Check if intake date is within range (inclusive)
      // Compare using millisecondsSinceEpoch for accurate comparison
      final intakeMs = intakeDate.millisecondsSinceEpoch;
      final startMs = startDate.millisecondsSinceEpoch;
      final endMs = endDate.millisecondsSinceEpoch;
      
      return intakeMs >= startMs && intakeMs <= endMs;
    }).toList();
  }
}

class DailyData {
  final double amount;
  final double goal;

  DailyData(this.amount, this.goal);
}

// Simple struct for week range
class _WeekRange {
  final DateTime start;
  final DateTime end;
  _WeekRange(this.start, this.end);
}
