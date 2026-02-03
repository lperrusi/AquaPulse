/// Authentication Service
///
/// Handles user authentication, registration, password management, and secure token storage.
/// Provides secure login/logout functionality and user session management.
/// Uses Firebase Auth for production-ready authentication.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'firebase_service.dart';
import 'database_service.dart';

/// Authentication states
enum AuthState {
  initial, // App just started
  loading, // Authentication in progress
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
  error, // Authentication error
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
  });
}

/// Service class for user authentication and session management
class AuthService {
  static const String _userKey = 'current_user';
  static const String _lastLoginKey = 'last_login';

  static AuthService? _instance;
  factory AuthService() => _instance ??= AuthService._internal();
  AuthService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  DatabaseService? _databaseService;
  User? _currentUser;
  DateTime? _lastLogin;

  // Set database service (injected from providers)
  void setDatabaseService(DatabaseService databaseService) {
    _databaseService = databaseService;
  }

  /// Gets the current authentication token (Firebase ID token)
  String? get currentToken => _firebaseService.currentUser?.uid;

  /// Gets the current authenticated user
  User? get currentUser => _currentUser;

  /// Gets the last login time
  DateTime? get lastLogin => _lastLogin;

  /// Checks if user is currently authenticated
  bool get isAuthenticated =>
      _firebaseService.currentUser != null && _currentUser != null;

  /// Initializes the authentication service
  Future<void> initialize() async {
    try {
      // Initialize Firebase service
      await _firebaseService.initialize();

      // Check if Firebase user is authenticated
      final firebaseUser = _firebaseService.currentUser;
      if (firebaseUser != null) {
        // Load user profile from database
        await _loadUserProfile(firebaseUser.uid);
      } else {
        // Load stored user data as fallback
        await _loadStoredAuth();
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      await _clearStoredAuth();
    }
  }

  /// Loads user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      debugPrint(
          '[ProfilePersistence] Auth._loadUserProfile: loading for userId=$userId');
      // Try Firestore first
      User? user = await _firebaseService.getUser(userId);

      // If not in Firestore, try local database
      if (user == null && _databaseService != null) {
        debugPrint(
            '[ProfilePersistence] Auth._loadUserProfile: Firestore null, trying local DB');
        user = await _databaseService!.getUser(userId);
      }

      if (user != null) {
        debugPrint(
            '[ProfilePersistence] Auth._loadUserProfile: loaded user id=${user.id} age=${user.age} gender=${user.gender}');
        _currentUser = user;
        await _storeUserData(user);
      } else {
        debugPrint('[ProfilePersistence] Auth._loadUserProfile: no user found');
      }
    } catch (e) {
      debugPrint('[ProfilePersistence] Auth._loadUserProfile error: $e');
    }
  }

  /// Loads stored authentication data (fallback)
  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final userJson = json.decode(userData);
        _currentUser = User.fromJson(userJson);
      }

      // Load last login
      final lastLoginStr = prefs.getString(_lastLoginKey);
      if (lastLoginStr != null) {
        _lastLogin = DateTime.parse(lastLoginStr);
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
      await _clearStoredAuth();
    }
  }

  /// Registers a new user with Firebase Auth
  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
    int? age,
    double? weight,
    String? gender,
    String? activityLevel,
  }) async {
    try {
      // Validate input
      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        return AuthResult(
          success: false,
          message: 'Password must be at least 6 characters long',
        );
      }

      // Create Firebase user account
      final userCredential =
          await _firebaseService.createUserWithEmailAndPassword(
        email.toLowerCase(),
        password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Failed to create user account',
        );
      }

      // Convert string activity level to enum
      final activityLevelEnum = _parseActivityLevel(activityLevel);

      // Create user profile
      final user = User(
        id: firebaseUser.uid, // Use Firebase UID as user ID
        email: firebaseUser.email ?? email.toLowerCase(),
        name: name,
        age: age,
        weight: weight ?? 70.0,
        gender: gender,
        activityLevel: activityLevelEnum,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user profile to Firestore
      await _firebaseService.createOrUpdateUser(user);

      // Save user profile to local database
      if (_databaseService != null) {
        await _databaseService!.createUser(user);
      }

      // Store authentication data locally
      _currentUser = user;
      await _storeUserData(user);

      return AuthResult(
        success: true,
        message: 'Registration successful!',
        user: user,
        token: firebaseUser.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Converts string activity level to ActivityLevel enum
  ActivityLevel _parseActivityLevel(String? activityLevelString) {
    switch (activityLevelString) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'lightly_active':
        return ActivityLevel.lightlyActive;
      case 'moderately_active':
        return ActivityLevel.moderatelyActive;
      case 'very_active':
        return ActivityLevel.veryActive;
      case 'extremely_active':
        return ActivityLevel.extremelyActive;
      default:
        return ActivityLevel.moderatelyActive; // Default fallback
    }
  }

  /// Logs in a user with Firebase Auth
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      if (password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Please enter your password',
        );
      }

      // Sign in with Firebase Auth
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email.toLowerCase(),
        password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'Login failed. Please try again.',
        );
      }

      // Load user profile from Firestore or local database
      User? user;
      try {
        // Try Firestore first
        user = await _firebaseService.getUser(firebaseUser.uid);

        // If not in Firestore, try local database
        if (user == null && _databaseService != null) {
          user = await _databaseService!.getUser(firebaseUser.uid);
        }

        // If still no user, create a basic profile
        if (user == null) {
          user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? email.toLowerCase(),
            name: firebaseUser.displayName,
            weight: 70.0,
            activityLevel: ActivityLevel.moderatelyActive,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Save to Firestore and local database
          await _firebaseService.createOrUpdateUser(user);
          if (_databaseService != null) {
            await _databaseService!.createUser(user);
          }
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
        // Create basic profile if loading fails
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email.toLowerCase(),
          name: firebaseUser.displayName,
          weight: 70.0,
          activityLevel: ActivityLevel.moderatelyActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Store authentication data locally
      _currentUser = user;
      await _storeUserData(user);

      return AuthResult(
        success: true,
        message: 'Login successful!',
        user: user,
        token: firebaseUser.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      debugPrint('Starting logout process...');

      // Sign out from Firebase
      await _firebaseService.signOut();

      // Clear in-memory state
      _currentUser = null;
      _lastLogin = null;

      // Clear stored auth data (run with timeout to prevent hanging)
      await _clearStoredAuth().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Warning: _clearStoredAuth timed out, continuing logout');
        },
      );

      debugPrint('Logout completed successfully');
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Even if there's an error, clear in-memory state
      _currentUser = null;
      _lastLogin = null;
    }
  }

  /// Changes user password with Firebase Auth
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!isAuthenticated) {
        return AuthResult(
          success: false,
          message: 'You must be logged in to change your password',
        );
      }

      if (newPassword.length < 6) {
        return AuthResult(
          success: false,
          message: 'New password must be at least 6 characters long',
        );
      }

      final firebaseUser = _firebaseService.currentUser;
      if (firebaseUser == null) {
        return AuthResult(
          success: false,
          message: 'No active session found',
        );
      }

      // Re-authenticate user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);

      // Update password
      await firebaseUser.updatePassword(newPassword);

      return AuthResult(
        success: true,
        message: 'Password changed successfully!',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  /// Sends password reset email via Firebase
  Future<AuthResult> forgotPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

      // Send password reset email via Firebase
      await _firebaseService.resetPassword(email.toLowerCase());

      return AuthResult(
        success: true,
        message:
            'Password reset email sent! Please check your inbox and follow the instructions.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send reset email: ${e.toString()}',
      );
    }
  }

  /// Refreshes the authentication token (Firebase handles this automatically)
  Future<AuthResult> refreshToken() async {
    try {
      if (!isAuthenticated) {
        return AuthResult(
          success: false,
          message: 'No active session to refresh',
        );
      }

      // Firebase automatically refreshes tokens, but we can refresh the ID token if needed
      final firebaseUser = _firebaseService.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.getIdToken(true); // Force refresh
        return AuthResult(
          success: true,
          message: 'Token refreshed successfully',
          token: firebaseUser.uid,
        );
      }

      return AuthResult(
        success: false,
        message: 'No active Firebase session',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to refresh token: ${e.toString()}',
      );
    }
  }

  /// Updates user profile
  Future<AuthResult> updateProfile({
    String? name,
    int? age,
    double? weight,
    String? gender,
    String? activityLevel,
  }) async {
    try {
      if (!isAuthenticated) {
        return AuthResult(
          success: false,
          message: 'You must be logged in to update your profile',
        );
      }

      // Update user data
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        age: age ?? _currentUser!.age,
        weight: weight ?? _currentUser!.weight,
        gender: gender ?? _currentUser!.gender,
        activityLevel: activityLevel != null
            ? _parseActivityLevel(activityLevel)
            : _currentUser!.activityLevel,
        updatedAt: DateTime.now(),
      );

      // Update user in Firestore
      await _firebaseService.createOrUpdateUser(updatedUser);

      // Update user in local database
      if (_databaseService != null) {
        await _databaseService!.updateUser(updatedUser);
      }

      // Update stored user data locally
      _currentUser = updatedUser;
      await _storeUserData(updatedUser);

      return AuthResult(
        success: true,
        message: 'Profile updated successfully!',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Stores user data locally (token is managed by Firebase)
  Future<void> _storeUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_userKey, json.encode(user.toJson()));
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());

      _currentUser = user;
      _lastLogin = DateTime.now();
    } catch (e) {
      debugPrint('Error storing user data: $e');
      rethrow;
    }
  }

  /// Clears stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Run all remove operations in parallel for better performance
      await Future.wait([
        prefs.remove(_userKey),
        prefs.remove(_lastLoginKey),
      ]);

      debugPrint('Stored auth data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing stored auth: $e');
      rethrow;
    }
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Converts Firebase Auth error codes to user-friendly messages
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is invalid. Please check and try again.';
      case 'user-not-found':
        return 'No account found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'internal-error':
        if (e.message != null &&
            e.message!.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Sign-in is not set up correctly. Please ensure Email/Password and Google are enabled in Firebase Console and that GoogleService-Info.plist is up to date.';
        }
        return 'We\'re having trouble connecting. Please try again in a moment.';
      default:
        if (e.message != null &&
            e.message!.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Sign-in is not set up correctly. Please ensure Email/Password and Google are enabled in Firebase Console and that GoogleService-Info.plist is up to date.';
        }
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Log in with Google (Firebase Auth + Google Sign-In)
  Future<AuthResult> loginWithGoogle() async {
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return AuthResult(
            success: false,
            message: 'Google sign-in failed. Please try again.');
      }

      User? user;
      try {
        user = await _firebaseService.getUser(firebaseUser.uid);
        if (user == null && _databaseService != null) {
          user = await _databaseService!.getUser(firebaseUser.uid);
        }
        if (user == null) {
          user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '${firebaseUser.uid}@google.user',
            name: firebaseUser.displayName,
            weight: 70.0,
            activityLevel: ActivityLevel.moderatelyActive,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firebaseService.createOrUpdateUser(user);
          if (_databaseService != null) {
            await _databaseService!.createUser(user);
          }
        }
      } catch (e) {
        debugPrint('Error loading user profile after Google sign-in: $e');
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '${firebaseUser.uid}@google.user',
          name: firebaseUser.displayName,
          weight: 70.0,
          activityLevel: ActivityLevel.moderatelyActive,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firebaseService.createOrUpdateUser(user);
        if (_databaseService != null) {
          await _databaseService!.createUser(user);
        }
      }

      _currentUser = user;
      await _storeUserData(user);
      return AuthResult(
          success: true,
          message: 'Signed in with Google!',
          user: user,
          token: firebaseUser.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == 'canceled') {
        return AuthResult(success: false, message: 'Sign-in was canceled.');
      }
      return AuthResult(success: false, message: _getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult(
          success: false, message: 'Google sign-in failed. Please try again.');
    }
  }
}
