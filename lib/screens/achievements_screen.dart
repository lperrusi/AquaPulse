/// Achievements Screen
///
/// Displays user achievements, progress tracking, and social sharing capabilities.
/// Shows unlocked and locked achievements with progress indicators.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../services/social_sharing_service.dart';
import '../providers/app_providers.dart';
import 'package:uuid/uuid.dart';

/// The main AchievementsScreen widget for displaying and managing user achievements
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading achievements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = _achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareStats(),
            tooltip: 'Share achievements',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Achievement summary
                  _buildAchievementSummary(unlockedAchievements.length, _achievements.length),
                  
                  const SizedBox(height: 24),
                  
                  // Unlocked achievements
                  if (unlockedAchievements.isNotEmpty) ...[
                    Text(
                      'Unlocked Achievements',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...unlockedAchievements.map((achievement) => _buildAchievementCard(achievement, true)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Locked achievements
                  Text(
                    'Locked Achievements',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...lockedAchievements.map((achievement) => _buildAchievementCard(achievement, false)),
                ],
              ),
            ),
    );
  }

  Widget _buildAchievementSummary(int unlocked, int total) {
    final theme = Theme.of(context);
    final progress = total > 0 ? unlocked / total : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$unlocked of $total achievements unlocked',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Achievement icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? Color(int.parse(achievement.tierColor.replaceAll('#', '0xFF')))
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Achievement details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked 
                                ? theme.colorScheme.onSurface 
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(int.parse(achievement.tierColor.replaceAll('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            achievement.tierName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUnlocked 
                          ? theme.colorScheme.onSurfaceVariant 
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  if (achievement.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action buttons
            if (isUnlocked) ...[
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareAchievement(achievement),
                tooltip: 'Share achievement',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays ~/ 7} weeks ago';
    }
  }

  void _shareAchievement(Achievement achievement) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final socialService = SocialSharingService();
    final message = socialService.createAchievementShareMessage(achievement, user);
    
    // For now, we'll show a dialog with the share message
    // In a real app, you'd integrate with native sharing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Achievement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Hashtags:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: socialService.getDefaultHashtags().map((hashtag) => 
                Chip(label: Text(hashtag))
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Record the share
              final share = SocialShare(
                id: const Uuid().v4(),
                type: 'achievement',
                title: achievement.title,
                message: message,
                sharedAt: DateTime.now(),
              );
              socialService.recordShare(share);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Achievement shared!')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showShareStats() async {
    final socialService = SocialSharingService();
    final stats = await socialService.getShareStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sharing Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total shares: ${stats['totalShares']}'),
            Text('Total likes: ${stats['totalLikes']}'),
            Text('Total re-shares: ${stats['totalSharesCount']}'),
            const SizedBox(height: 16),
            Text(
              'Shares by type:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...(stats['sharesByType'] as Map<String, int>).entries.map((entry) =>
              Text('${entry.key}: ${entry.value}')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 