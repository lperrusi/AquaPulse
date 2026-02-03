/// App Providers
///
/// Defines all Riverpod providers for state management, including user, water intake, hydration goal, reminders, cup sizes, streaks, and combined hydration state.
/// Centralizes state logic for the entire app.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/user.dart';
import '../models/water_intake.dart';
import '../models/reminder.dart';
import '../models/cup_size.dart';
import '../models/streak.dart';
import '../models/friend.dart';
import '../models/challenge.dart';
import '../models/leaderboard.dart';
import '../services/database_service.dart';
import '../services/hydration_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../services/friend_service.dart';
import '../services/challenge_service.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
// import '../services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Services
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService();
  // Inject database service for user profile management
  authService.setDatabaseService(ref.read(databaseServiceProvider));
  return authService;
});

/// Provides authentication state and handles authentication operations
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});

/// Provides the current user and handles user CRUD operations.
final currentUserProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(
    ref.read(databaseServiceProvider),
    ref.read(firebaseServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;
  StreamSubscription? _authStateSubscription;

  AuthNotifier(this._authService, this._ref) : super(AuthState.initial) {
    _initializeAuth();
    _setupAuthStateListener();
  }

  Future<void> _initializeAuth() async {
    try {
      state = AuthState.loading;
      await _authService.initialize();

      if (_authService.isAuthenticated) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      state = AuthState.error;
      debugPrint('Auth initialization error: $e');
    }
  }

  /// Sets up Firebase Auth state listener for automatic session management
  void _setupAuthStateListener() {
    final firebaseService = _ref.read(firebaseServiceProvider);
    _authStateSubscription = firebaseService.authStateChanges.listen(
      (firebaseUser) async {
        if (firebaseUser != null) {
          debugPrint(
              '[ProfilePersistence] AuthState: signed in, loading profile into provider');
          // User is signed in: load profile and sync to provider so profile shows correct user (e.g. Google)
          if (_authService.currentUser == null) {
            await _authService.initialize();
          }
          final user = _authService.currentUser;
          if (user != null) {
            await _ref.read(currentUserProvider.notifier).setUserFromAuth(user);
          }
          state = AuthState.authenticated;
        } else {
          // User is signed out
          if (state != AuthState.unauthenticated) {
            state = AuthState.unauthenticated;
            // Clear user from provider
            _ref.read(currentUserProvider.notifier).clearUser();
          }
        }
      },
      onError: (error) {
        debugPrint('Auth state listener error: $error');
        state = AuthState.error;
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      state = AuthState.loading;
      final result = await _authService.login(email: email, password: password);

      if (result.success && result.user != null) {
        // User is already saved to database in AuthService.login
        // Just update the current user provider
        final userNotifier = _ref.read(currentUserProvider.notifier);
        await userNotifier.createUser(result.user!);
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }

      return result;
    } catch (e) {
      state = AuthState.error;
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    try {
      state = AuthState.loading;
      final result = await _authService.loginWithGoogle();
      if (result.success && result.user != null) {
        final userNotifier = _ref.read(currentUserProvider.notifier);
        await userNotifier.createUser(result.user!);
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
      return result;
    } catch (e) {
      state = AuthState.error;
      return AuthResult(
        success: false,
        message: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    int? age,
    double? weight,
    String? gender,
    String? activityLevel,
  }) async {
    try {
      state = AuthState.loading;
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        age: age,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
      );

      if (result.success && result.user != null) {
        // User is already saved to database in AuthService.register
        // Just update the current user provider
        final userNotifier = _ref.read(currentUserProvider.notifier);
        await userNotifier.createUser(result.user!);
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }

      return result;
    } catch (e) {
      state = AuthState.error;
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('AuthNotifier: Starting logout...');

      // Get user ID before clearing (for database deletion)
      final currentUser = _ref.read(currentUserProvider);
      final userId = currentUser?.id;

      // Set state to loading briefly, then immediately clear user and set to unauthenticated
      // This ensures UI updates immediately
      state = AuthState.loading;

      // Clear the current user from the UserNotifier IMMEDIATELY (synchronous, fast)
      final userNotifier = _ref.read(currentUserProvider.notifier);
      userNotifier.clearUser();

      // Delete user from database (non-blocking, with timeout)
      if (userId != null) {
        try {
          await userNotifier.deleteUser(userId).timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              debugPrint('Warning: deleteUser timed out, continuing logout');
            },
          );
        } catch (e) {
          debugPrint('Error deleting user from database (non-critical): $e');
        }
      }

      // Set state to unauthenticated IMMEDIATELY so navigation happens right away
      state = AuthState.unauthenticated;
      debugPrint(
          'AuthNotifier: State set to unauthenticated, navigation should happen now');

      // Now do cleanup in the background (non-blocking)
      _performLogoutCleanup();

      debugPrint('AuthNotifier: Logout initiated successfully');
    } catch (e) {
      debugPrint('AuthNotifier: Logout error: $e');
      // Set to unauthenticated even on error to allow user to continue
      state = AuthState.unauthenticated;
    }
  }

  /// Performs cleanup operations in the background (non-blocking)
  Future<void> _performLogoutCleanup() async {
    try {
      // Sign out from Firebase (non-blocking)
      try {
        final firebaseService = FirebaseService();
        await firebaseService.signOut().timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('Firebase signOut timed out, continuing cleanup');
          },
        ).catchError((e) {
          debugPrint('Firebase signOut error (non-blocking): $e');
        });
      } catch (e) {
        debugPrint('Firebase signOut failed (non-blocking): $e');
      }

      // Clear auth service (with timeout protection)
      await _authService.logout().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Warning: AuthService.logout timed out during cleanup');
        },
      );

      debugPrint('AuthNotifier: Background cleanup completed');
    } catch (e) {
      debugPrint('AuthNotifier: Background cleanup error (non-critical): $e');
    }
  }

  Future<AuthResult> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return result;
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Password change failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      final result = await _authService.forgotPassword(email);
      return result;
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Forgot password failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> updateProfile({
    String? name,
    int? age,
    double? weight,
    String? gender,
    String? activityLevel,
  }) async {
    try {
      final result = await _authService.updateProfile(
        name: name,
        age: age,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
      );
      return result;
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Profile update failed: ${e.toString()}',
      );
    }
  }

  User? get currentUser => _authService.currentUser;
  String? get currentToken => _authService.currentToken;
  DateTime? get lastLogin => _authService.lastLogin;
  bool get isAuthenticated => _authService.isAuthenticated;
}

class UserNotifier extends StateNotifier<User?> {
  final DatabaseService _databaseService;
  final FirebaseService _firebaseService;

  UserNotifier(this._databaseService, this._firebaseService) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _databaseService.getCurrentUser();
    debugPrint(
        '[ProfilePersistence] _loadUser: got user from DB (id=${user?.id}, age=${user?.age}, gender=${user?.gender})');
    state = user;
  }

  Future<void> createUser(User user) async {
    await _databaseService.createUser(user);
    state = user;

    // Initialize default data for new user
    await _initializeDefaultData(user);
  }

  /// Sets the current user from auth (e.g. after app start when Firebase is already signed in).
  /// Persists current user id so getCurrentUser() returns this user next time.
  Future<void> setUserFromAuth(User user) async {
    debugPrint(
        '[ProfilePersistence] setUserFromAuth: loading user from auth (id=${user.id}, age=${user.age}, gender=${user.gender})');
    await _databaseService.setCurrentUserId(user.id);
    state = user;
  }

  Future<void> _initializeDefaultData(User user) async {
    try {
      // Add default cup sizes if none exist
      final cupSizes = await _databaseService.getAllCupSizes();
      if (cupSizes.isEmpty) {
        await _databaseService.addCupSize(CupSize(
          id: const Uuid().v4(),
          name: 'Small Glass',
          amount: 200,
          icon: '🥤',
          isDefault: true,
          createdAt: DateTime.now(),
        ));
        await _databaseService.addCupSize(CupSize(
          id: const Uuid().v4(),
          name: 'Large Glass',
          amount: 350,
          icon: '🥛',
          isDefault: true,
          createdAt: DateTime.now(),
        ));
        await _databaseService.addCupSize(CupSize(
          id: const Uuid().v4(),
          name: 'Water Bottle',
          amount: 500,
          icon: '💧',
          isDefault: true,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Error initializing default data: $e');
    }
  }

  Future<void> updateUser(User user) async {
    debugPrint(
        '[ProfilePersistence] updateUser: saving to local DB (id=${user.id}, age=${user.age}, gender=${user.gender})');
    await _databaseService.updateUser(user);
    // Sync to Firestore when signed in so age/gender etc. persist across app restarts
    if (_firebaseService.currentUser != null) {
      debugPrint(
          '[ProfilePersistence] updateUser: syncing to Firestore (age=${user.age}, gender=${user.gender})');
      await _firebaseService.createOrUpdateUser(user);
      debugPrint('[ProfilePersistence] updateUser: Firestore sync done');
    } else {
      debugPrint(
          '[ProfilePersistence] updateUser: skipped Firestore (not signed in)');
    }
    state = user;
  }

  Future<void> deleteUser(String userId) async {
    await _databaseService.deleteUser(userId);
    state = null;
  }

  Future<void> clearUser() async {
    await _databaseService.clearCurrentUserId();
    state = null;
  }
}

/// Provides the list of water intakes and handles intake CRUD operations.
final waterIntakeProvider =
    StateNotifierProvider<WaterIntakeNotifier, List<WaterIntake>>((ref) {
  return WaterIntakeNotifier(ref.read(databaseServiceProvider), ref);
});

/// Notifier for managing water intake state. Automatically resets the tracked intake to zero at the start of a new day
/// by checking the last opened date (persisted with shared_preferences). This ensures the user always starts with zero
/// intake for the new day, and only today's intakes are shown/tracked.
class WaterIntakeNotifier extends StateNotifier<List<WaterIntake>> {
  final DatabaseService _databaseService;
  final Ref _ref;

  WaterIntakeNotifier(this._databaseService, this._ref) : super([]) {
    _checkAndResetForNewDay();
  }

  /// Checks if a new day has started and resets the tracked intake if so.
  Future<void> _checkAndResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenedDateStr = prefs.getString('lastOpenedDate');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? lastOpenedDate;
    if (lastOpenedDateStr != null) {
      lastOpenedDate = DateTime.tryParse(lastOpenedDateStr);
    }
    // Always load today's intakes (not all intakes)
    // If it's a new day, the data will be empty anyway
    await _loadTodaysIntakes();
    await prefs.setString('lastOpenedDate', today.toIso8601String());
  }

  /// Checks if a new day has started and refreshes data if needed.
  /// This can be called periodically to detect day changes while the app is running.
  Future<bool> checkForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenedDateStr = prefs.getString('lastOpenedDate');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? lastOpenedDate;
    if (lastOpenedDateStr != null) {
      lastOpenedDate = DateTime.tryParse(lastOpenedDateStr);
    }

    final isNewDay = lastOpenedDate == null ||
        lastOpenedDate.year != today.year ||
        lastOpenedDate.month != today.month ||
        lastOpenedDate.day != today.day;

    if (isNewDay) {
      // New day detected, reload today's intakes
      await _loadTodaysIntakes();
      await prefs.setString('lastOpenedDate', today.toIso8601String());
      return true;
    }

    return false;
  }

  /// Manually triggers a daily reset (for testing or future use).
  Future<void> manualDailyReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();
    await _loadTodaysIntakes();
    await prefs.setString('lastOpenedDate', today.toIso8601String());
  }

  Future<void> _loadIntakes() async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      final intakes = await _databaseService.getAllWaterIntakesForUser(user.id);
      state = intakes;
    } else {
      state = [];
    }
  }

  Future<void> _loadTodaysIntakes() async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      final today = DateTime.now();
      final todaysIntakes =
          await _databaseService.getWaterIntakeForDateAndUser(today, user.id);
      state = todaysIntakes;
    } else {
      state = [];
    }
  }

  Future<void> addWaterIntake(WaterIntake intake) async {
    await _databaseService.addWaterIntake(intake);
    await _loadTodaysIntakes(); // Load only today's intakes to ensure correct calculation
  }

  Future<void> updateWaterIntake(WaterIntake intake) async {
    await _databaseService.updateWaterIntake(intake);
    await _loadTodaysIntakes(); // Load only today's intakes to ensure correct calculation
  }

  Future<void> deleteWaterIntake(String intakeId) async {
    await _databaseService.deleteWaterIntake(intakeId);
    await _loadTodaysIntakes(); // Load only today's intakes to ensure correct calculation
  }

  Future<List<WaterIntake>> getIntakesForDate(DateTime date) async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      return await _databaseService.getWaterIntakeForDateAndUser(date, user.id);
    }
    return [];
  }

  /// Loads today's intakes and updates the provider state
  Future<void> loadTodaysIntakes() async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      final today = DateTime.now();
      final todaysIntakes =
          await _databaseService.getWaterIntakeForDateAndUser(today, user.id);
      state = todaysIntakes;
    } else {
      state = [];
    }
  }

  Future<double> getTotalIntakeForDate(DateTime date) async {
    return await _databaseService.getTotalIntakeForDate(date);
  }
}

/// Provides the user's daily hydration goal (custom or calculated).
final dailyGoalProvider = Provider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  if (user.customGoal != null && user.customGoal! > 0) {
    return user.customGoal!;
  }
  return HydrationService.calculateDailyGoal(user);
});

/// Provides the list of reminders and handles reminder CRUD operations.
final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>((ref) {
  return RemindersNotifier(ref.read(databaseServiceProvider));
});

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  final DatabaseService _databaseService;
  String? error;

  RemindersNotifier(this._databaseService) : super([]) {
    _loadReminders();
    _rescheduleActiveReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await _databaseService.getAllReminders();
      state = reminders;
      error = null;
    } catch (e) {
      state = [];
      error = e.toString();
    }
  }

  Future<void> _rescheduleActiveReminders() async {
    try {
      final notificationService = NotificationService();
      for (final reminder in state) {
        if (reminder.isActive) {
          try {
            await notificationService.scheduleReminder(reminder);
            debugPrint(
                'Provider: Rescheduled active reminder: ${reminder.title}');
          } catch (e) {
            debugPrint(
                'Provider: Failed to reschedule reminder ${reminder.title}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Provider: Error rescheduling reminders: $e');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      debugPrint('Provider: Adding reminder to database...');
      await _databaseService.addReminder(reminder);
      debugPrint('Provider: Reminder added to database, loading reminders...');
      await _loadReminders();
      debugPrint('Provider: Reminders loaded successfully');

      // Try to schedule notification, but don't fail if it doesn't work
      try {
        final notificationService = NotificationService();
        await notificationService.scheduleReminder(reminder);
        debugPrint('Provider: Notification scheduled successfully');
      } catch (notificationError) {
        debugPrint(
            'Provider: Failed to schedule notification: $notificationError');
        // Don't rethrow notification errors as they shouldn't prevent reminder creation
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Provider: Error adding reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      // First, cancel the old notification if it exists
      final notificationService = NotificationService();
      await notificationService.cancelReminder(reminder);

      // Update in database
      await _databaseService.updateReminder(reminder);
      await _loadReminders();

      // Schedule the new notification if the reminder is active
      if (reminder.isActive) {
        try {
          await notificationService.scheduleReminder(reminder);
          debugPrint(
              'Provider: Updated reminder notification scheduled successfully');
        } catch (notificationError) {
          debugPrint(
              'Provider: Failed to schedule updated notification: $notificationError');
        }
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Provider: Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    await _databaseService.deleteReminder(reminderId);
    await _loadReminders();
  }

  Future<void> toggleReminder(String reminderId) async {
    try {
      final reminder = state.firstWhere((r) => r.id == reminderId);
      final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);

      final notificationService = NotificationService();

      if (updatedReminder.isActive) {
        // If turning on, schedule the notification
        try {
          await notificationService.scheduleReminder(updatedReminder);
          debugPrint(
              'Provider: Toggled reminder notification scheduled successfully');
        } catch (notificationError) {
          debugPrint(
              'Provider: Failed to schedule toggled notification: $notificationError');
        }
      } else {
        // If turning off, cancel the notification
        try {
          await notificationService.cancelReminder(reminder);
          debugPrint(
              'Provider: Toggled reminder notification cancelled successfully');
        } catch (notificationError) {
          debugPrint(
              'Provider: Failed to cancel toggled notification: $notificationError');
        }
      }

      await updateReminder(updatedReminder);
    } catch (e) {
      error = e.toString();
      debugPrint('Provider: Error toggling reminder: $e');
      rethrow;
    }
  }
}

final remindersErrorProvider = Provider<String?>((ref) {
  final notifier = ref.watch(remindersProvider.notifier);
  return notifier.error;
});

/// Provides weather data and handles weather-related operations
final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherData?>((ref) {
  return WeatherNotifier();
});

class WeatherNotifier extends StateNotifier<WeatherData?> {
  final WeatherService _weatherService = WeatherService();
  String? error;
  StreamSubscription<WeatherData>? _weatherSubscription;
  DateTime? _lastUpdateTime;

  WeatherNotifier() : super(null) {
    _initializeWeatherService();
  }

  Future<void> _initializeWeatherService() async {
    try {
      // Start background updates
      final frequency = await _weatherService.getUpdateFrequency();
      _weatherService.startBackgroundUpdates(interval: frequency);

      // Subscribe to weather stream
      _weatherSubscription = _weatherService.weatherStream.listen(
        (weather) {
          state = weather;
          _lastUpdateTime = DateTime.now();
          error = null;
        },
        onError: (e) {
          error = e.toString();
          debugPrint('Weather stream error: $e');
        },
      );

      // Load initial weather data
      await _loadWeatherData();
    } catch (e) {
      error = e.toString();
      debugPrint('Weather provider initialization error: $e');
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await _weatherService.getWeatherWithAutoRefresh();
      state = weather;
      _lastUpdateTime = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Weather provider error: $e');
    }
  }

  Future<void> refreshWeather() async {
    try {
      final weather = await _weatherService.forceRefresh();
      state = weather;
      _lastUpdateTime = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Weather refresh error: $e');
    }
  }

  Future<void> setUpdateFrequency(Duration frequency) async {
    try {
      await _weatherService.setUpdateFrequency(frequency);
    } catch (e) {
      error = e.toString();
      debugPrint('Error setting update frequency: $e');
    }
  }

  DateTime? get lastUpdateTime => _lastUpdateTime;

  String? get errorState => error;

  @override
  void dispose() {
    _weatherSubscription?.cancel();
    _weatherService.dispose();
    super.dispose();
  }
}

/// Provides friend data and handles friend-related operations
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, List<Friend>>((ref) {
  return FriendsNotifier(ref.read(authServiceProvider));
});

class FriendsNotifier extends StateNotifier<List<Friend>> {
  final FriendService _friendService = FriendService();
  final AuthService _authService;
  String? error;

  FriendsNotifier(this._authService) : super([]) {
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      // Get authenticated user ID
      final userId = _authService.currentUser?.id ?? 'default_user';
      final friends = await _friendService.getFriends(userId);
      state = friends;
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Friends provider error: $e');
    }
  }

  Future<void> sendFriendRequest({
    required String toUserId,
    required String message,
  }) async {
    try {
      final userId = _authService.currentUser?.id ?? 'default_user';
      final userName = _authService.currentUser?.name ?? 'Current User';

      final success = await _friendService.sendFriendRequest(
        fromUserId: userId,
        fromUserName: userName,
        toUserId: toUserId,
        message: message,
      );

      if (success) {
        // Refresh friends list
        await _loadFriends();
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Error sending friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final success = await _friendService.acceptFriendRequest(requestId);
      if (success) {
        await _loadFriends();
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Error accepting friend request: $e');
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      final success = await _friendService.declineFriendRequest(requestId);
      if (success) {
        await _loadFriends();
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Error declining friend request: $e');
    }
  }

  String? get errorState => error;
}

/// Provides challenge data and handles challenge-related operations
final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<Challenge>>((ref) {
  return ChallengesNotifier(ref.read(authServiceProvider));
});

class ChallengesNotifier extends StateNotifier<List<Challenge>> {
  final ChallengeService _challengeService = ChallengeService();
  final AuthService _authService;
  String? error;

  ChallengesNotifier(this._authService) : super([]) {
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      final userId = _authService.currentUser?.id ?? 'default_user';
      final challenges = await _challengeService.getUserChallenges(userId);
      state = challenges;
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Challenges provider error: $e');
    }
  }

  Future<Challenge?> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> rules,
    required List<String> participants,
  }) async {
    try {
      final userId = _authService.currentUser?.id ?? 'default_user';
      final userName = _authService.currentUser?.name ?? 'Current User';

      final challenge = await _challengeService.createChallenge(
        title: title,
        description: description,
        type: type,
        startDate: startDate,
        endDate: endDate,
        rules: rules,
        participants: participants,
        createdBy: userId,
        createdByName: userName,
      );

      if (challenge != null) {
        await _loadChallenges();
      }

      return challenge;
    } catch (e) {
      error = e.toString();
      debugPrint('Error creating challenge: $e');
      return null;
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    try {
      final userId = _authService.currentUser?.id ?? 'default_user';
      final userName = _authService.currentUser?.name ?? 'Current User';

      final success =
          await _challengeService.joinChallenge(challengeId, userId, userName);
      if (success) {
        await _loadChallenges();
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Error joining challenge: $e');
    }
  }

  String? get errorState => error;
}

/// Provides leaderboard data and handles leaderboard-related operations
final leaderboardsProvider =
    StateNotifierProvider<LeaderboardsNotifier, Map<String, Leaderboard>>(
        (ref) {
  return LeaderboardsNotifier(ref.read(authServiceProvider));
});

class LeaderboardsNotifier extends StateNotifier<Map<String, Leaderboard>> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthService _authService;
  String? error;

  LeaderboardsNotifier(this._authService) : super({}) {
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    try {
      final globalLeaderboard =
          await _leaderboardService.getGlobalLeaderboard();
      final streakLeaderboard =
          await _leaderboardService.getStreakLeaderboard();

      final leaderboards = <String, Leaderboard>{};
      if (globalLeaderboard != null) {
        leaderboards['global'] = globalLeaderboard;
      }
      if (streakLeaderboard != null) {
        leaderboards['streak'] = streakLeaderboard;
      }

      state = leaderboards;
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Leaderboards provider error: $e');
    }
  }

  Future<void> updateUserScore({
    required double score,
    required Map<String, dynamic> stats,
    LeaderboardType type = LeaderboardType.global,
  }) async {
    try {
      final userId = _authService.currentUser?.id ?? 'default_user';

      final success = await _leaderboardService.updateUserScore(
        userId: userId,
        score: score,
        stats: stats,
        type: type,
      );

      if (success) {
        await _loadLeaderboards();
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Error updating user score: $e');
    }
  }

  String? get errorState => error;
}

/// Provides the list of cup sizes and handles cup size CRUD operations.
final cupSizesProvider =
    StateNotifierProvider<CupSizesNotifier, List<CupSize>>((ref) {
  return CupSizesNotifier(ref.read(databaseServiceProvider));
});

class CupSizesNotifier extends StateNotifier<List<CupSize>> {
  final DatabaseService _databaseService;

  CupSizesNotifier(this._databaseService) : super([]) {
    _loadCupSizes();
  }

  Future<void> _loadCupSizes() async {
    // Force remove any cup size with amount 350ml
    final db = await _databaseService.database;
    await db.delete('cup_sizes', where: 'amount = ?', whereArgs: [350.0]);
    final cupSizes = await _databaseService.getAllCupSizes();
    state = cupSizes;
  }

  Future<void> addCupSize(CupSize cupSize) async {
    await _databaseService.addCupSize(cupSize);
    await _loadCupSizes();
  }

  Future<void> updateCupSize(CupSize cupSize) async {
    await _databaseService.updateCupSize(cupSize);
    await _loadCupSizes();
  }

  Future<void> deleteCupSize(String cupSizeId) async {
    await _databaseService.deleteCupSize(cupSizeId);
    await _loadCupSizes();
  }
}

/// Provides the user's streak data and handles streak updates.
final streakProvider = StateNotifierProvider<StreakNotifier, Streak?>((ref) {
  return StreakNotifier(ref.read(databaseServiceProvider));
});

class StreakNotifier extends StateNotifier<Streak?> {
  final DatabaseService _databaseService;

  StreakNotifier(this._databaseService) : super(null);

  Future<void> loadStreak(String userId) async {
    final streak = await _databaseService.getStreak(userId);
    state = streak;
  }

  Future<void> updateStreak(String userId, bool goalMet) async {
    if (!goalMet) {
      // If goal not met, reset streak
      final currentStreak = state;
      final streak = Streak(
        id: userId,
        userId: userId,
        currentStreak: 0,
        longestStreak: currentStreak?.longestStreak ?? 0,
        lastGoalMet: currentStreak?.lastGoalMet ?? DateTime.now(),
        createdAt: currentStreak?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (currentStreak == null) {
        await _databaseService.insertStreak(streak);
      } else {
        await _databaseService.updateStreak(streak);
      }
      state = streak;
      return;
    }

    final currentStreak = state;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if goal was already met today
    if (currentStreak != null) {
      final lastGoalMetDate = DateTime(
        currentStreak.lastGoalMet.year,
        currentStreak.lastGoalMet.month,
        currentStreak.lastGoalMet.day,
      );

      // If goal was already met today, don't update streak again
      if (lastGoalMetDate == today) {
        return;
      }

      // Check if goal was met yesterday (consecutive day)
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastGoalMetDate == yesterday) {
        // Consecutive day - increment streak
        final newStreakCount = currentStreak.currentStreak + 1;
        final streak = Streak(
          id: userId,
          userId: userId,
          currentStreak: newStreakCount,
          longestStreak: newStreakCount > currentStreak.longestStreak
              ? newStreakCount
              : currentStreak.longestStreak,
          lastGoalMet: now,
          createdAt: currentStreak.createdAt,
          updatedAt: now,
        );
        await _databaseService.updateStreak(streak);
        state = streak;
      } else {
        // More than 1 day gap - reset streak to 1
        final streak = Streak(
          id: userId,
          userId: userId,
          currentStreak: 1,
          longestStreak:
              currentStreak.longestStreak > 1 ? currentStreak.longestStreak : 1,
          lastGoalMet: now,
          createdAt: currentStreak.createdAt,
          updatedAt: now,
        );
        await _databaseService.updateStreak(streak);
        state = streak;
      }
    } else {
      // No existing streak - start with 1
      final streak = Streak(
        id: userId,
        userId: userId,
        currentStreak: 1,
        longestStreak: 1,
        lastGoalMet: now,
        createdAt: now,
        updatedAt: now,
      );
      await _databaseService.insertStreak(streak);
      state = streak;
    }
  }
}

/// Provides the combined hydration state for the UI, including intake, goal, progress, streak, and achievements.
final hydrationStateProvider = Provider<HydrationState>((ref) {
  final user = ref.watch(currentUserProvider);
  final intakes = ref.watch(waterIntakeProvider);
  final goal = ref.watch(dailyGoalProvider);
  final streaks = ref.watch(streakProvider);

  if (user == null) {
    return HydrationState(
      currentIntake: 0.0,
      goal: 0.0,
      progress: 0.0,
      remaining: 0.0,
      status: 'No user data',
      currentStreak: 0,
      achievementLevel: 'Newcomer',
      todayIntakes: [],
      isGoalMet: false,
      totalIntake: 0.0,
      dailyGoal: 0.0,
      todayIntake: 0.0,
    );
  }

  // Since waterIntakeProvider should already contain only today's data,
  // we don't need to filter again. Use all intakes from the provider.
  final currentIntake = intakes.fold(0.0, (sum, intake) => sum + intake.amount);
  final progress = HydrationService.calculateProgress(currentIntake, goal);
  final remaining = HydrationService.calculateRemaining(currentIntake, goal);
  final status = HydrationService.getHydrationStatus(progress);

  // Get current streak
  final currentStreak = streaks?.currentStreak ?? 0;
  final achievementLevel = HydrationService.getAchievementLevel(currentStreak);

  // Calculate total intake from all intakes
  final totalIntake = intakes.fold(0.0, (sum, intake) => sum + intake.amount);

  return HydrationState(
    currentIntake: currentIntake,
    goal: goal,
    progress: progress,
    remaining: remaining,
    status: status,
    currentStreak: currentStreak,
    achievementLevel: achievementLevel,
    todayIntakes:
        intakes, // Use all intakes since they should already be today's data
    isGoalMet: currentIntake >= goal,
    totalIntake: totalIntake,
    dailyGoal: goal,
    todayIntake: currentIntake,
  );
});

class HydrationState {
  final double currentIntake;
  final double goal;
  final double progress;
  final double remaining;
  final String status;
  final int currentStreak;
  final String achievementLevel;
  final List<WaterIntake> todayIntakes;
  final bool isGoalMet;
  final double totalIntake;
  final double dailyGoal;
  final double todayIntake;

  const HydrationState({
    required this.currentIntake,
    required this.goal,
    required this.progress,
    required this.remaining,
    required this.status,
    required this.currentStreak,
    required this.achievementLevel,
    required this.todayIntakes,
    required this.isGoalMet,
    required this.totalIntake,
    required this.dailyGoal,
    required this.todayIntake,
  });
}

// ==================== INTRODUCTION SCREEN PROVIDER ====================

/// Provider to track whether the user has seen the introduction screen
final introductionSeenProvider =
    StateNotifierProvider<IntroductionSeenNotifier, bool>((ref) {
  return IntroductionSeenNotifier();
});

/// State notifier for introduction screen tracking
class IntroductionSeenNotifier extends StateNotifier<bool> {
  IntroductionSeenNotifier() : super(false) {
    _loadIntroductionSeen();
  }

  static const String _key = 'introduction_seen';

  Future<void> _loadIntroductionSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('Error loading introduction seen status: $e');
      state = false;
    }
  }

  Future<void> markAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      state = true;
    } catch (e) {
      debugPrint('Error saving introduction seen status: $e');
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      state = false;
    } catch (e) {
      debugPrint('Error resetting introduction seen status: $e');
    }
  }
} 

// ==================== PREMIUM PROVIDER ====================

// TEMPORARILY DISABLED: Premium functionality
// /// Provider for premium service
// final premiumServiceProvider = Provider<PremiumService>((ref) => PremiumService());

// /// Provider for premium status
// final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
//   return PremiumNotifier(ref.read(premiumServiceProvider));
// });

// /// State notifier for premium status
// class PremiumNotifier extends StateNotifier<bool> {
//   final PremiumService _premiumService;

//   PremiumNotifier(this._premiumService) : super(false) {
//     _loadPremiumStatus();
//   }

//   Future<void> _loadPremiumStatus() async {
//     try {
//       final isPremium = await _premiumService.isPremium();
//       state = isPremium;
//     } catch (e) {
//       debugPrint('Error loading premium status: $e');
//       state = false;
//     }
//   }

//   Future<void> refreshPremiumStatus() async {
//     await _loadPremiumStatus();
//   }
// }