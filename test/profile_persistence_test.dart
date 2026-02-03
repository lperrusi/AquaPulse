/// Profile persistence tests
///
/// Tests that age and gender (and other profile fields) persist across app restarts:
/// - UserNotifier.updateUser writes to local DB and syncs to Firestore when signed in
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydration_tracker/models/user.dart';
import 'package:hydration_tracker/providers/app_providers.dart';
import 'package:hydration_tracker/services/database_service.dart';
import 'package:hydration_tracker/services/firebase_service.dart';
import 'package:mockito/mockito.dart';
import 'test_helpers.dart';
import 'test_helpers.mocks.dart';

void main() {
  group('Profile persistence (age/gender)', () {
    late ProviderContainer container;
    late MockDatabaseService mockDb;
    late MockFirebaseService mockFirebase;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockDb = TestHelpers.createMockDatabaseService();
      mockFirebase = TestHelpers.createMockFirebaseService();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateUser persists user with age and gender to database', () async {
      final testUser = User(
        id: 'user_1',
        email: 'test@gmail.com',
        name: 'Test User',
        age: 35,
        weight: 72.0,
        gender: 'female',
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockDb.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockDb.updateUser(any)).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
          firebaseServiceProvider.overrideWithValue(mockFirebase),
        ],
      );

      final notifier = container.read(currentUserProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final updatedUser = testUser.copyWith(
        age: 40,
        gender: 'male',
        updatedAt: DateTime.now(),
      );
      await notifier.updateUser(updatedUser);

      final captured = verify(mockDb.updateUser(captureAny)).captured;
      expect(captured.length, 1);
      final savedUser = captured.single as User;
      expect(savedUser.id, updatedUser.id);
      expect(savedUser.age, 40);
      expect(savedUser.gender, 'male');
      expect(savedUser.email, testUser.email);
    });

    test('updateUser does not call createOrUpdateUser when not signed in',
        () async {
      final testUser = User(
        id: 'firebase_uid_123',
        email: 'user@gmail.com',
        name: 'Google User',
        age: 28,
        weight: 70.0,
        gender: 'male',
        activityLevel: ActivityLevel.lightlyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockDb.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockDb.updateUser(any)).thenAnswer((_) async {});
      when(mockFirebase.currentUser).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
          firebaseServiceProvider.overrideWithValue(mockFirebase),
        ],
      );

      final notifier = container.read(currentUserProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final updatedUser = testUser.copyWith(
        age: 30,
        gender: 'female',
        updatedAt: DateTime.now(),
      );
      await notifier.updateUser(updatedUser);

      verify(mockDb.updateUser(any)).called(1);
      verifyNever(mockFirebase.createOrUpdateUser(any));
    });

    test('save profile then reload from DB preserves age and gender', () async {
      final initialUser = User(
        id: 'user_roundtrip',
        email: 'roundtrip@test.com',
        name: 'Roundtrip User',
        age: 25,
        weight: 68.0,
        gender: 'male',
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      User? savedUser;
      when(mockDb.getCurrentUser())
          .thenAnswer((_) async => savedUser ?? initialUser);
      when(mockDb.updateUser(any)).thenAnswer((i) async {
        savedUser = i.positionalArguments[0] as User;
      });
      when(mockDb.setCurrentUserId(any)).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
          firebaseServiceProvider.overrideWithValue(mockFirebase),
        ],
      );

      final notifier = container.read(currentUserProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 80));

      final updatedUser = initialUser.copyWith(
        age: 33,
        gender: 'female',
        updatedAt: DateTime.now(),
      );
      await notifier.updateUser(updatedUser);
      expect(savedUser, isNotNull);
      expect(savedUser!.age, 33);
      expect(savedUser!.gender, 'female');

      container.dispose();
      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
          firebaseServiceProvider.overrideWithValue(mockFirebase),
        ],
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 100));

      User? current = container.read(currentUserProvider);
      for (int i = 0; i < 10 && current == null; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        current = container.read(currentUserProvider);
      }
      expect(current, isNotNull, reason: 'User should be loaded after reload');
      expect(current!.id, 'user_roundtrip');
      expect(current.age, 33, reason: 'Age should persist after reload');
      expect(current.gender, 'female',
          reason: 'Gender should persist after reload');
    });
  });
}
