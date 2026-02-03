/// Database Service
///
/// Handles all SQLite database operations for the app, including user, water intake, reminders, streaks, and cup sizes.
/// Provides CRUD methods and manages database initialization and migrations.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/water_intake.dart';
import '../models/reminder.dart';
import '../models/cup_size.dart';
import '../models/streak.dart';

/// Service class for managing all database operations and schema for the hydration tracker app.
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'hydration_tracker.db';
  static const int _databaseVersion = 3;
  static const String _currentUserIdKey = 'db_current_user_id';

  /// Returns the singleton database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database and creates tables if needed.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all tables and inserts default data on first database creation.
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT,
        age INTEGER,
        weight REAL NOT NULL,
        gender TEXT,
        activityLevel INTEGER NOT NULL,
        location TEXT,
        latitude REAL,
        longitude REAL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        customGoal REAL
      )
    ''');

    // Water intake table
    await db.execute('''
      CREATE TABLE water_intake (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Daily water goals table
    await db.execute('''
      CREATE TABLE daily_water_goals (
        userId TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        date TEXT NOT NULL,
        weatherAdjustment REAL,
        PRIMARY KEY (userId, date),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        time_hour INTEGER NOT NULL,
        time_minute INTEGER NOT NULL,
        days_of_week TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        is_interval INTEGER,
        interval_minutes INTEGER,
        start_time_hour INTEGER,
        start_time_minute INTEGER,
        end_time_hour INTEGER,
        end_time_minute INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Streaks table
    await db.execute('''
      CREATE TABLE streaks (
        userId TEXT PRIMARY KEY,
        currentStreak INTEGER NOT NULL,
        longestStreak INTEGER NOT NULL,
        lastGoalMet TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Cup sizes table
    await db.execute('''
      CREATE TABLE cup_sizes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        icon TEXT,
        is_default INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Insert default cup sizes
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('cup_sizes', {
      'id': 'small',
      'name': 'Small Glass',
      'amount': 250.0,
      'icon': '🥤',
      'is_default': 1,
      'created_at': now,
    });
    await db.insert('cup_sizes', {
      'id': 'large',
      'name': 'Large Glass',
      'amount': 500.0,
      'icon': '🥤',
      'is_default': 1,
      'created_at': now,
    });
    await db.insert('cup_sizes', {
      'id': 'bottle',
      'name': 'Water Bottle',
      'amount': 750.0,
      'icon': '💧',
      'is_default': 1,
      'created_at': now,
    });
  }

  /// Handles database schema upgrades between versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add columns safely by checking if they exist first
      await _addColumnIfNotExists(db, 'users', 'customGoal', 'REAL');
      await _addColumnIfNotExists(db, 'users', 'age', 'INTEGER');
      await _addColumnIfNotExists(db, 'users', 'gender', 'TEXT');

      // Update reminders table schema if needed
      await _updateRemindersTableSchema(db);
    }

    if (oldVersion < 3) {
      // Force recreate reminders table with new schema
      await _recreateRemindersTable(db);
    }
    // Handle database upgrades here
  }

  /// Updates the reminders table schema to match the new structure.
  Future<void> _updateRemindersTableSchema(Database db) async {
    try {
      // Check if the old columns exist
      final columns = await db.rawQuery('PRAGMA table_info(reminders)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      // If the old 'time' column exists, we need to migrate the data
      if (columnNames.contains('time') && !columnNames.contains('time_hour')) {
        // Create a temporary table with the new schema
        await db.execute('''
          CREATE TABLE reminders_new (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            time_hour INTEGER NOT NULL,
            time_minute INTEGER NOT NULL,
            days_of_week TEXT NOT NULL,
            is_active INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            is_interval INTEGER,
            interval_minutes INTEGER,
            start_time_hour INTEGER,
            start_time_minute INTEGER,
            end_time_hour INTEGER,
            end_time_minute INTEGER,
            FOREIGN KEY (userId) REFERENCES users (id)
          )
        ''');

        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO reminders_new (id, userId, title, message, time_hour, time_minute, days_of_week, is_active, createdAt, is_interval, interval_minutes, start_time_hour, start_time_minute, end_time_hour, end_time_minute)
          SELECT id, userId, title, message, 
                 CAST(substr(time, 1, instr(time, ':') - 1) AS INTEGER) as time_hour,
                 CAST(substr(time, instr(time, ':') + 1) AS INTEGER) as time_minute,
                 daysOfWeek as days_of_week,
                 isActive as is_active,
                 createdAt,
                 is_interval,
                 interval_minutes,
                 start_time_hour,
                 start_time_minute,
                 end_time_hour,
                 end_time_minute
          FROM reminders
        ''');

        // Drop old table and rename new table
        await db.execute('DROP TABLE reminders');
        await db.execute('ALTER TABLE reminders_new RENAME TO reminders');
      }
    } catch (e) {
      debugPrint('Warning: Could not update reminders table schema: $e');
    }
  }

  /// Recreates the reminders table with the new schema.
  Future<void> _recreateRemindersTable(Database db) async {
    try {
      // Drop the existing reminders table if it exists
      await db.execute('DROP TABLE IF EXISTS reminders');

      // Create the reminders table with the new schema
      await db.execute('''
        CREATE TABLE reminders (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          time_hour INTEGER NOT NULL,
          time_minute INTEGER NOT NULL,
          days_of_week TEXT NOT NULL,
          is_active INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          is_interval INTEGER,
          interval_minutes INTEGER,
          start_time_hour INTEGER,
          start_time_minute INTEGER,
          end_time_hour INTEGER,
          end_time_minute INTEGER,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
    } catch (e) {
      debugPrint('Warning: Could not recreate reminders table: $e');
    }
  }

  /// Safely adds a column to a table if it doesn't already exist.
  Future<void> _addColumnIfNotExists(Database db, String tableName,
      String columnName, String columnType) async {
    try {
      // Check if the column exists by querying the table info
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists =
          columns.any((column) => column['name'] == columnName);

      if (!columnExists) {
        await db.execute(
            'ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
      }
    } catch (e) {
      // If there's an error, log it but don't crash the app
      debugPrint(
          'Warning: Could not add column $columnName to table $tableName: $e');
    }
  }

  /// Inserts a new user into the database.
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson());
  }

  /// Retrieves a user by ID from the database.
  /// Returns the User if found, or null if not found.
  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  /// Updates an existing user in the database.
  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Inserts a new water intake record into the database.
  Future<void> insertWaterIntake(WaterIntake intake) async {
    final db = await database;
    await db.insert('water_intake', intake.toJson());
  }

  /// Retrieves all water intake records for a specific date.
  /// Returns a list of WaterIntake objects.
  Future<List<WaterIntake>> getWaterIntakeForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'water_intake',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => WaterIntake.fromJson(maps[i]));
  }

  /// Retrieves all water intake records for a specific date and user.
  /// Returns a list of WaterIntake objects.
  Future<List<WaterIntake>> getWaterIntakeForDateAndUser(
      DateTime date, String userId) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'water_intake',
      where: 'userId = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String()
      ],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => WaterIntake.fromJson(maps[i]));
  }

  Future<List<WaterIntake>> getWaterIntakeForWeek(
      String userId, DateTime startDate) async {
    final db = await database;
    final endDate = startDate.add(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.query(
      'water_intake',
      where: 'userId = ? AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String()
      ],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => WaterIntake.fromJson(map)).toList();
  }

  // Daily water goal operations
  Future<void> insertDailyWaterGoal(DailyWaterGoal goal) async {
    final db = await database;
    await db.insert('daily_water_goals', goal.toJson());
  }

  Future<DailyWaterGoal?> getDailyWaterGoal(
      String userId, DateTime date) async {
    final db = await database;
    final dateString =
        DateTime(date.year, date.month, date.day).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_water_goals',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, dateString],
    );

    if (maps.isEmpty) return null;
    return DailyWaterGoal.fromJson(maps.first);
  }

  // Reminder operations
  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;

    // Ensure default user exists
    final defaultUser = await getUser('default_user');
    if (defaultUser == null) {
      await insertUser(User(
        id: 'default_user',
        email: 'default@example.com',
        name: 'Default User',
        weight: 70.0,
        activityLevel: ActivityLevel.moderatelyActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    final json = reminder.toJson();
    debugPrint('Inserting reminder JSON: $json');
    await db.insert('reminders', json);
  }

  Future<List<Reminder>> getReminders(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'time ASC',
    );

    return maps.map((map) => Reminder.fromJson(map)).toList();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update(
      'reminders',
      reminder.toJson(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cup size operations
  Future<List<CupSize>> getCupSizes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cup_sizes');
    return maps.map((map) => CupSize.fromJson(map)).toList();
  }

  Future<void> insertCupSize(CupSize cupSize) async {
    final db = await database;
    await db.insert('cup_sizes', cupSize.toJson());
  }

  // Streak operations
  Future<void> insertStreak(Streak streak) async {
    final db = await database;
    await db.insert('streaks', streak.toJson());
  }

  Future<Streak?> getStreak(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'streaks',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    return Streak.fromJson(maps.first);
  }

  Future<void> updateStreak(Streak streak) async {
    final db = await database;
    await db.update(
      'streaks',
      streak.toJson(),
      where: 'userId = ?',
      whereArgs: [streak.userId],
    );
  }

  // Calculate total intake for a specific date
  Future<double> getTotalIntakeForDate(DateTime date) async {
    final intakes = await getWaterIntakeForDate(date);
    return intakes.fold<double>(0.0, (sum, intake) => sum + intake.amount);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // User methods

  /// Persisted current user id so we load the correct user after login (e.g. Google) instead of the first row.
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  Future<User?> getCurrentUser() async {
    final id = await getCurrentUserId();
    if (id != null && id.isNotEmpty) {
      final user = await getUser(id);
      if (user != null) return user;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<void> createUser(User user) async {
    await insertUser(user);
    await setCurrentUserId(user.id);
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Water intake methods
  Future<List<WaterIntake>> getAllWaterIntakes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('water_intake', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => WaterIntake.fromJson(maps[i]));
  }

  /// Retrieves all water intake records for a specific user.
  /// Returns a list of WaterIntake objects.
  Future<List<WaterIntake>> getAllWaterIntakesForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'water_intake',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => WaterIntake.fromJson(maps[i]));
  }

  Future<void> addWaterIntake(WaterIntake intake) async {
    await insertWaterIntake(intake);
  }

  Future<void> updateWaterIntake(WaterIntake intake) async {
    final db = await database;
    await db.update(
      'water_intake',
      intake.toJson(),
      where: 'id = ?',
      whereArgs: [intake.id],
    );
  }

  Future<void> deleteWaterIntake(String intakeId) async {
    final db = await database;
    await db.delete('water_intake', where: 'id = ?', whereArgs: [intakeId]);
  }

  // Reminder methods
  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('reminders', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Reminder.fromJson(maps[i]));
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      debugPrint('Adding reminder to database: ${reminder.title}');
      debugPrint('Reminder JSON: ${reminder.toJson()}');
      await insertReminder(reminder);
      debugPrint('Reminder added successfully');
    } catch (e) {
      debugPrint('Error adding reminder to database: $e');
      rethrow;
    }
  }

  // Cup size methods
  Future<List<CupSize>> getAllCupSizes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('cup_sizes', orderBy: 'amount ASC');
    return List.generate(maps.length, (i) => CupSize.fromJson(maps[i]));
  }

  Future<void> addCupSize(CupSize cupSize) async {
    await insertCupSize(cupSize);
  }

  Future<void> updateCupSize(CupSize cupSize) async {
    final db = await database;
    await db.update(
      'cup_sizes',
      cupSize.toJson(),
      where: 'id = ?',
      whereArgs: [cupSize.id],
    );
  }

  Future<void> deleteCupSize(String cupSizeId) async {
    final db = await database;
    await db.delete('cup_sizes', where: 'id = ?', whereArgs: [cupSizeId]);
  }

  // Streak methods
  Future<List<Streak>> getAllStreaks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('streaks', orderBy: 'updated_at DESC');
    return List.generate(maps.length, (i) => Streak.fromJson(maps[i]));
  }

  Future<void> addStreak(Streak streak) async {
    await insertStreak(streak);
  }

  Future<void> deleteStreak(String streakId) async {
    final db = await database;
    await db.delete('streaks', where: 'id = ?', whereArgs: [streakId]);
  }
}
