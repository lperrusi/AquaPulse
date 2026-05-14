/// Social Screen
///
/// Comprehensive social hub displaying friends, challenges, and leaderboards.
/// Provides access to all social features including friend management, challenges, and competitive rankings.
// ignore_for_file: use_build_context_synchronously, unused_local_variable
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/friend.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';
import '../models/user.dart';
import '../config/app_capabilities.dart';
import '../utils/neumorphic_style.dart';

/// The main SocialScreen widget for displaying social features
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppCapabilities.cloudSocialEnabled) {
      return Scaffold(
        backgroundColor: NeumorphicStyle.backgroundBlue,
        appBar: AppBar(
          title: Text(
            'Social',
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: NeumorphicStyle.primaryBlue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: NeumorphicStyle.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Account features are temporarily disabled.',
                    textAlign: TextAlign.center,
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Friends, challenges, and leaderboards will return when cloud mode is enabled.',
                    textAlign: TextAlign.center,
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 14,
                      color: NeumorphicStyle.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final friends = ref.watch(friendsProvider);
    final challenges = ref.watch(challengesProvider);
    final leaderboards = ref.watch(leaderboardsProvider);

    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Social',
          style: NeumorphicStyle.neumorphicText(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: NeumorphicStyle.darkText,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Friends'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Challenges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(friends),
          _buildChallengesTab(challenges),
          _buildLeaderboardsTab(leaderboards),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFriendsTab(List<Friend> friends) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Friend requests section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have 2 pending friend requests',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _showFriendRequests,
                  child: const Text('View'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Friends list
          Text(
            'Your Friends (${friends.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (friends.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add friends to start competing and sharing achievements!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child:
                          Text(friend.friendName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(friend.friendName),
                    subtitle: Text(friend.friendEmail ?? ''),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _handleFriendAction(value, friend),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view_profile',
                          child: Row(
                            children: [
                              Icon(Icons.person),
                              SizedBox(width: 8),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'challenge',
                          child: Row(
                            children: [
                              Icon(Icons.emoji_events),
                              SizedBox(width: 8),
                              Text('Challenge'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove Friend',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(List<Challenge> challenges) {
    final theme = Theme.of(context);
    final activeChallenges =
        challenges.where((c) => c.status == ChallengeStatus.active).toList();
    final completedChallenges =
        challenges.where((c) => c.status == ChallengeStatus.completed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active challenges
          Text(
            'Active Challenges (${activeChallenges.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (activeChallenges.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active challenges',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a challenge with friends to start competing!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeChallenges.length,
              itemBuilder: (context, index) {
                final challenge = activeChallenges[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getChallengeColor(challenge.type),
                      child: Icon(Icons.emoji_events, color: Colors.white),
                    ),
                    title: Text(challenge.title),
                    subtitle: Text(challenge.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleChallengeAction(value, challenge),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view_progress',
                          child: Row(
                            children: [
                              Icon(Icons.trending_up),
                              SizedBox(width: 8),
                              Text('View Progress'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'invite_friend',
                          child: Row(
                            children: [
                              Icon(Icons.person_add),
                              SizedBox(width: 8),
                              Text('Invite Friend'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Completed challenges
          Text(
            'Completed Challenges (${completedChallenges.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (completedChallenges.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedChallenges.length,
              itemBuilder: (context, index) {
                final challenge = completedChallenges[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(challenge.title),
                    subtitle: Text(
                        'Completed on ${challenge.endDate.toString().split(' ')[0]}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardsTab(Map<String, Leaderboard> leaderboards) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Global leaderboard
          if (leaderboards.containsKey('global'))
            _buildLeaderboardCard(
              'Global Hydration',
              leaderboards['global']!,
              Icons.public,
              const Color(0xFF2196F3),
            ),

          const SizedBox(height: 16),

          // Streak leaderboard
          if (leaderboards.containsKey('streak'))
            _buildLeaderboardCard(
              'Streak Champions',
              leaderboards['streak']!,
              Icons.local_fire_department,
              Colors.orange,
            ),

          const SizedBox(height: 16),

          // View all leaderboards button
          ElevatedButton.icon(
            onPressed: _showAllLeaderboards,
            icon: const Icon(Icons.leaderboard),
            label: const Text('View All Leaderboards'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(
      String title, Leaderboard leaderboard, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${leaderboard.entries.length} participants',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Top 3 entries
            ...leaderboard.entries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: entry.rank == 1 ? Colors.amber : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.userName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      entry.score.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_selectedTabIndex) {
      case 0: // Friends tab
        return FloatingActionButton(
          onPressed: _showAddFriendsDialog,
          child: const Icon(Icons.person_add),
        );
      case 1: // Challenges tab
        return FloatingActionButton(
          onPressed: () => _showCreateChallengeDialog(),
          child: const Icon(Icons.add),
        );
      case 2: // Leaderboards tab
        return FloatingActionButton(
          onPressed: _showAllLeaderboards,
          child: const Icon(Icons.leaderboard),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.dailyGoal:
        return const Color(0xFF2196F3);
      case ChallengeType.streak:
        return Colors.orange;
      case ChallengeType.totalIntake:
        return Colors.green;
      case ChallengeType.consistency:
        return Colors.purple;
      case ChallengeType.custom:
        return Colors.grey;
    }
  }

  void _handleFriendAction(String action, Friend friend) {
    switch (action) {
      case 'view_profile':
        // TODO: Navigate to friend profile
        break;
      case 'challenge':
        _showCreateChallengeDialog(friendId: friend.friendId);
        break;
      case 'remove':
        _showRemoveFriendDialog(friend);
        break;
    }
  }

  void _handleChallengeAction(String action, Challenge challenge) {
    switch (action) {
      case 'view_progress':
        // TODO: Navigate to challenge progress screen
        break;
      case 'invite_friend':
        _showCreateChallengeDialog();
        break;
    }
  }

  void _showAddFriendsDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddFriendsDialog(),
    );
  }

  void _showFriendRequests() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Friend Requests'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<FriendRequest>>(
            future: _loadFriendRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading requests: ${snapshot.error}'),
                );
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return const Center(
                  child: Text('No pending friend requests'),
                );
              }

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                          request.fromUserName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(request.fromUserName),
                    subtitle: Text(request.message),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _acceptFriendRequest(request.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _declineFriendRequest(request.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
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

  Future<List<FriendRequest>> _loadFriendRequests() async {
    try {
      // Simulate loading friend requests - in a real app, this would call the backend
      await Future.delayed(const Duration(milliseconds: 500));

      return [
        FriendRequest(
          id: 'request_1',
          fromUserId: 'user_1',
          fromUserName: 'John Doe',
          toUserId: 'current_user',
          message: 'Hi! I\'d like to be your friend on AquaPulse.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        FriendRequest(
          id: 'request_2',
          fromUserId: 'user_2',
          fromUserName: 'Jane Smith',
          toUserId: 'current_user',
          message: 'Let\'s stay hydrated together!',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  void _acceptFriendRequest(String requestId) async {
    try {
      await ref.read(friendsProvider.notifier).acceptFriendRequest(requestId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _declineFriendRequest(String requestId) async {
    try {
      await ref.read(friendsProvider.notifier).declineFriendRequest(requestId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateChallengeDialog({String? friendId}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    ChallengeType selectedType = ChallengeType.dailyGoal;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Challenge'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Challenge Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ChallengeType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Challenge Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ChallengeType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child:
                            Text(type.name.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                startDate = date;
                              });
                            }
                          },
                          child: Text(
                              'Start: ${startDate.toString().split(' ')[0]}'),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                endDate = date;
                              });
                            }
                          },
                          child:
                              Text('End: ${endDate.toString().split(' ')[0]}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createChallenge(
                  title: titleController.text,
                  description: descriptionController.text,
                  type: selectedType,
                  startDate: startDate,
                  endDate: endDate,
                  friendId: friendId,
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    String? friendId,
  }) async {
    try {
      final participants = <String>[];
      if (friendId != null) {
        participants.add(friendId);
      }

      final challenge =
          await ref.read(challengesProvider.notifier).createChallenge(
                title: title,
                description: description,
                type: type,
                startDate: startDate,
                endDate: endDate,
                rules: _getChallengeRules(type),
                participants: participants,
              );

      if (challenge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Challenge "${challenge.title}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create challenge'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getChallengeRules(ChallengeType type) {
    switch (type) {
      case ChallengeType.dailyGoal:
        return {
          'goal': 'Reach daily hydration goal',
          'points': 10,
        };
      case ChallengeType.streak:
        return {
          'goal': 'Maintain hydration streak',
          'points': 20,
        };
      case ChallengeType.totalIntake:
        return {
          'goal': 'Achieve highest total intake',
          'points': 15,
        };
      case ChallengeType.consistency:
        return {
          'goal': 'Most consistent daily intake',
          'points': 25,
        };
      case ChallengeType.custom:
        return {
          'goal': 'Custom challenge',
          'points': 30,
        };
    }
  }

  void _showRemoveFriendDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.friendName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friend);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeFriend(Friend friend) async {
    try {
      // In a real app, this would call the backend to remove the friend
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, we'll just show a success message
      // In a real implementation, you would call the friend service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${friend.friendName} removed from friends'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove friend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAllLeaderboards() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Leaderboards'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<Map<String, Leaderboard>>(
            future: _loadAllLeaderboards(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading leaderboards: ${snapshot.error}'),
                );
              }

              final leaderboards = snapshot.data ?? {};

              if (leaderboards.isEmpty) {
                return const Center(
                  child: Text('No leaderboards available'),
                );
              }

              return ListView.builder(
                itemCount: leaderboards.length,
                itemBuilder: (context, index) {
                  final key = leaderboards.keys.elementAt(index);
                  final leaderboard = leaderboards[key]!;

                  return ExpansionTile(
                    title: Text(key.toUpperCase()),
                    subtitle:
                        Text('${leaderboard.entries.length} participants'),
                    children: [
                      ...leaderboard.entries.take(10).map((entry) {
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${entry.rank}'),
                          ),
                          title: Text(entry.userName),
                          subtitle:
                              Text('Score: ${entry.score.toStringAsFixed(1)}'),
                          trailing: entry.rank <= 3
                              ? Icon(
                                  entry.rank == 1
                                      ? Icons.emoji_events
                                      : Icons.star,
                                  color: entry.rank == 1
                                      ? Colors.amber
                                      : Colors.grey,
                                )
                              : null,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
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

  Future<Map<String, Leaderboard>> _loadAllLeaderboards() async {
    try {
      // Simulate loading leaderboards - in a real app, this would call the backend
      await Future.delayed(const Duration(milliseconds: 500));

      final globalEntries = [
        LeaderboardEntry(
          id: 'entry_1',
          userId: 'user_1',
          userName: 'John Doe',
          score: 95.5,
          rank: 1,
          stats: {'totalIntake': 2500.0, 'streak': 15},
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now().subtract(const Duration(days: 7)),
          periodEnd: DateTime.now(),
        ),
        LeaderboardEntry(
          id: 'entry_2',
          userId: 'user_2',
          userName: 'Jane Smith',
          score: 88.2,
          rank: 2,
          stats: {'totalIntake': 2300.0, 'streak': 12},
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now().subtract(const Duration(days: 7)),
          periodEnd: DateTime.now(),
        ),
        LeaderboardEntry(
          id: 'entry_3',
          userId: 'user_3',
          userName: 'Mike Johnson',
          score: 82.1,
          rank: 3,
          stats: {'totalIntake': 2100.0, 'streak': 10},
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now().subtract(const Duration(days: 7)),
          periodEnd: DateTime.now(),
        ),
      ];

      final streakEntries = [
        LeaderboardEntry(
          id: 'streak_entry_1',
          userId: 'user_1',
          userName: 'John Doe',
          score: 15.0,
          rank: 1,
          stats: {'currentStreak': 15, 'longestStreak': 20},
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now().subtract(const Duration(days: 7)),
          periodEnd: DateTime.now(),
        ),
        LeaderboardEntry(
          id: 'streak_entry_2',
          userId: 'user_2',
          userName: 'Jane Smith',
          score: 12.0,
          rank: 2,
          stats: {'currentStreak': 12, 'longestStreak': 18},
          lastUpdated: DateTime.now(),
          periodStart: DateTime.now().subtract(const Duration(days: 7)),
          periodEnd: DateTime.now(),
        ),
      ];

      return {
        'global': Leaderboard(
          id: 'global_1',
          title: 'Global Hydration',
          description: 'Top performers in daily hydration goals',
          type: LeaderboardType.global,
          period: LeaderboardPeriod.weekly,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          entries: globalEntries,
          totalParticipants: globalEntries.length,
          lastUpdated: DateTime.now(),
        ),
        'streak': Leaderboard(
          id: 'streak_1',
          title: 'Streak Champions',
          description: 'Longest hydration streaks',
          type: LeaderboardType.streak,
          period: LeaderboardPeriod.weekly,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          entries: streakEntries,
          totalParticipants: streakEntries.length,
          lastUpdated: DateTime.now(),
        ),
      };
    } catch (e) {
      return {};
    }
  }
}

class _AddFriendsDialog extends StatefulWidget {
  @override
  State<_AddFriendsDialog> createState() => _AddFriendsDialogState();
}

class _AddFriendsDialogState extends State<_AddFriendsDialog> {
  final searchController = TextEditingController();
  bool isSearching = false;
  List<User> searchResults = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Friends'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search by email or username',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _performFriendSearch(value);
                } else {
                  setState(() {
                    searchResults.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Search Results',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            user.name?.substring(0, 1).toUpperCase() ?? 'U'),
                      ),
                      title: Text(user.name ?? 'Unknown User'),
                      subtitle: Text(user.email),
                      trailing: ElevatedButton(
                        onPressed: () => _sendFriendRequest(user),
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _performFriendSearch(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      // Simulate search results - in a real app, this would call the backend
      await Future.delayed(const Duration(milliseconds: 500));

      final mockResults = [
        User(
          id: 'user_1',
          email: 'john.doe@example.com',
          name: 'John Doe',
          weight: 70.0,
          activityLevel: ActivityLevel.moderatelyActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        User(
          id: 'user_2',
          email: 'jane.smith@example.com',
          name: 'Jane Smith',
          weight: 65.0,
          activityLevel: ActivityLevel.veryActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]
          .where((user) =>
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              (user.name?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      setState(() {
        searchResults = mockResults;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _sendFriendRequest(User user) async {
    try {
      // In a real app, this would call the friend service
      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${user.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
