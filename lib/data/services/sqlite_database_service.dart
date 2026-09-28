import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/user_model.dart';
import '../datasources/initial_logbook_data.dart';

class SqliteDatabaseService {
  static const String _defaultDbName = 'maganghub_logbook.db';
  final String _dbName;
  static const int _dbVersion = 2;

  Database? _db;

  SqliteDatabaseService({String? dbName}) : _dbName = dbName ?? _defaultDbName;

  static const SettingsModel defaultSettings = SettingsModel(
    llmProvider: 'local',
    localLlmUrl: 'http://192.168.13.155:3000',
    localLlmModel: 'gpt-oss-20b',
    localLlmApiKey: '',
    geminiModel: 'gemini-3.6-flash',
    geminiApiKey: '',
    activeRepoId: null,
    defaultRepoIds: [],
    repositories: [],
  );

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI for unit tests on desktop/Linux host
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      if (Platform.isLinux) {
        try {
          open.overrideFor(OperatingSystem.linux, () {
            try {
              return DynamicLibrary.open('libsqlite3.so');
            } catch (_) {
              return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
            }
          });
        } catch (_) {}
      }
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateDatabase(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        await _createTables(db);
        await _checkAndUpgradeIfRequired(db);
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM logbook_entries'),
        ) ?? 0;
        if (count == 0) {
          await _seedInitialData(db);
        }
        await _ensureAlifDataSeeded(db);
      },
    );

    return db;
  }

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Logbook entries table (v2 with user_id and composite UNIQUE)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS logbook_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        no INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        row_number INTEGER NOT NULL,
        aktivitas TEXT NOT NULL,
        pembelajaran TEXT NOT NULL,
        kendala TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, tanggal)
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _upgradeToV2(db);
    }
  }

  Future<void> _checkAndUpgradeIfRequired(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(logbook_entries)');
    final hasUserId = tableInfo.any((col) => col['name'] == 'user_id');
    if (!hasUserId) {
      await _upgradeToV2(db);
    }
  }

  Future<void> _upgradeToV2(Database db) async {
    // 1. Ensure users table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Check if logbook_entries has user_id
    final tableInfo = await db.rawQuery('PRAGMA table_info(logbook_entries)');
    final hasUserId = tableInfo.any((col) => col['name'] == 'user_id');

    if (!hasUserId) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS logbook_entries_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          no INTEGER NOT NULL,
          tanggal TEXT NOT NULL,
          row_number INTEGER NOT NULL,
          aktivitas TEXT NOT NULL,
          pembelajaran TEXT NOT NULL,
          kendala TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(user_id, tanggal)
        )
      ''');

      // Preserve existing entries assigning user_id = 1
      await db.execute('''
        INSERT INTO logbook_entries_v2 (user_id, no, tanggal, row_number, aktivitas, pembelajaran, kendala, created_at)
        SELECT 1, no, tanggal, row_number, aktivitas, pembelajaran, kendala, created_at
        FROM logbook_entries
      ''');

      await db.execute('DROP TABLE logbook_entries');
      await db.execute('ALTER TABLE logbook_entries_v2 RENAME TO logbook_entries');
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();
    final nowIso = DateTime.now().toIso8601String();

    for (final entry in initialLogbookData) {
      batch.insert(
        'logbook_entries',
        {
          'user_id': 1,
          'no': entry.no,
          'tanggal': entry.tanggal,
          'row_number': entry.rowNumber,
          'aktivitas': entry.aktivitas,
          'pembelajaran': entry.pembelajaran,
          'kendala': entry.kendala,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Default settings
    batch.insert(
      'app_settings',
      {
        'key': 'settings_json',
        'value': jsonEncode(defaultSettings.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_settings',
      {
        'key': 'is_standalone',
        'value': 'true',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }

  // -------------------------------------------------------------
  // Data Seeding Helpers (Logbook_MagangHub.xlsx)
  // -------------------------------------------------------------

  Future<void> _ensureAlifDataSeeded(Database db) async {
    final alifUsers = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: ['alif'],
    );
    if (alifUsers.isNotEmpty) {
      for (final u in alifUsers) {
        final uId = u['id'] as int;
        await _seedLogbookForUserWithDb(db, uId);
      }
    }
  }

  Future<void> _seedLogbookForUserWithDb(Database db, int userId) async {
    final batch = db.batch();
    final nowIso = DateTime.now().toIso8601String();

    for (final entry in initialLogbookData) {
      batch.insert(
        'logbook_entries',
        {
          'user_id': userId,
          'no': entry.no,
          'tanggal': entry.tanggal,
          'row_number': entry.rowNumber,
          'aktivitas': entry.aktivitas,
          'pembelajaran': entry.pembelajaran,
          'kendala': entry.kendala,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> seedLogbookForUser(int userId) async {
    final db = await database;
    await _seedLogbookForUserWithDb(db, userId);
  }

  Future<void> ensureAlifDataSeeded() async {
    final db = await database;
    await _ensureAlifDataSeeded(db);
  }

  // -------------------------------------------------------------
  // Password & User Authentication (SQLite)
  // -------------------------------------------------------------

  String _hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  Future<UserModel> registerUser({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    final db = await database;
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanUsername.isEmpty || cleanEmail.isEmpty || password.trim().isEmpty) {
      throw Exception('Semua kolom wajib diisi.');
    }

    final existing = await db.query(
      'users',
      where: 'LOWER(username) = ? OR LOWER(email) = ?',
      whereArgs: [cleanUsername, cleanEmail],
    );

    final hash = _hashPassword(password);
    final nowIso = DateTime.now().toIso8601String();

    // If username is 'alif' and user already exists, update and seed data
    if (cleanUsername == 'alif' && existing.isNotEmpty) {
      final existingUser = existing.first;
      final existingId = existingUser['id'] as int;
      await db.update(
        'users',
        {
          'password_hash': hash,
          'email': cleanEmail,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
      await _seedLogbookForUserWithDb(db, existingId);
      return UserModel(
        id: existingId,
        username: cleanUsername,
        email: cleanEmail,
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : (existingUser['name'] as String? ?? cleanUsername),
        createdAt: existingUser['created_at'] as String,
      );
    }

    if (existing.isNotEmpty) {
      throw Exception('Username atau email sudah digunakan.');
    }

    final totalUsersBefore = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    ) ?? 0;

    final id = await db.insert('users', {
      'username': cleanUsername,
      'email': cleanEmail,
      'password_hash': hash,
      'name': (name != null && name.trim().isNotEmpty) ? name.trim() : cleanUsername,
      'created_at': nowIso,
    });

    // If username is 'alif', ALWAYS seed all entries from Logbook_MagangHub.xlsx
    if (cleanUsername == 'alif') {
      await _seedLogbookForUserWithDb(db, id);
    } else if (totalUsersBefore == 0 && id != 1) {
      await db.update(
        'logbook_entries',
        {'user_id': id},
        where: 'user_id = 1',
      );
    }

    return UserModel(
      id: id,
      username: cleanUsername,
      email: cleanEmail,
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : cleanUsername,
      createdAt: nowIso,
    );
  }

  Future<UserModel> loginUser({
    required String usernameOrEmail,
    required String password,
  }) async {
    final db = await database;
    final clean = usernameOrEmail.trim().toLowerCase();
    final hash = _hashPassword(password);

    // If username == 'alif', guarantee login and seed data from Logbook_MagangHub.xlsx
    if (clean == 'alif') {
      final alifUsers = await db.query(
        'users',
        where: 'LOWER(username) = ? OR LOWER(email) = ?',
        whereArgs: ['alif', 'alif@maganghub.local'],
      );

      if (alifUsers.isNotEmpty) {
        final row = alifUsers.first;
        final uId = row['id'] as int;
        // Update password to match and seed data
        await db.update(
          'users',
          {'password_hash': hash},
          where: 'id = ?',
          whereArgs: [uId],
        );
        await _seedLogbookForUserWithDb(db, uId);
        return UserModel(
          id: uId,
          username: row['username'] as String,
          email: row['email'] as String,
          name: row['name'] as String?,
          createdAt: row['created_at'] as String,
        );
      } else {
        // Auto-register user alif and seed data
        return await registerUser(
          username: 'alif',
          email: 'alif@maganghub.local',
          password: password,
          name: 'Alif',
        );
      }
    }

    final rows = await db.query(
      'users',
      where: '(LOWER(username) = ? OR LOWER(email) = ?) AND password_hash = ?',
      whereArgs: [clean, clean, hash],
    );

    if (rows.isEmpty) {
      throw Exception('Username/email atau kata sandi tidak cocok.');
    }

    final row = rows.first;
    final user = UserModel(
      id: row['id'] as int,
      username: row['username'] as String,
      email: row['email'] as String,
      name: row['name'] as String?,
      createdAt: row['created_at'] as String,
    );

    if (user.username.toLowerCase() == 'alif') {
      await _seedLogbookForUserWithDb(db, user.id);
    }

    return user;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserModel(
      id: row['id'] as int,
      username: row['username'] as String,
      email: row['email'] as String,
      name: row['name'] as String?,
      createdAt: row['created_at'] as String,
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'id ASC');
    return rows.map((r) => UserModel(
      id: r['id'] as int,
      username: r['username'] as String,
      email: r['email'] as String,
      name: r['name'] as String?,
      createdAt: r['created_at'] as String,
    )).toList();
  }

  // -------------------------------------------------------------
  // Logbook Entries CRUD (Scoped by userId)
  // -------------------------------------------------------------

  Future<int> reimportFromVercelDataset({int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? 1;
    final batch = db.batch();
    final nowIso = DateTime.now().toIso8601String();

    for (final entry in initialLogbookData) {
      batch.insert(
        'logbook_entries',
        {
          'user_id': targetUserId,
          'no': entry.no,
          'tanggal': entry.tanggal,
          'row_number': entry.rowNumber,
          'aktivitas': entry.aktivitas,
          'pembelajaran': entry.pembelajaran,
          'kendala': entry.kendala,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return initialLogbookData.length;
  }

  Future<List<LogbookEntry>> loadEntries({int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? 1;

    // If target user is 'alif', ensure 13 entries from Logbook_MagangHub.xlsx are present
    final userRow = await db.query(
      'users',
      columns: ['username'],
      where: 'id = ?',
      whereArgs: [targetUserId],
    );
    if (userRow.isNotEmpty) {
      final uname = (userRow.first['username'] as String?)?.toLowerCase();
      if (uname == 'alif') {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM logbook_entries WHERE user_id = ?', [targetUserId]),
        ) ?? 0;
        if (count < 13) {
          await _seedLogbookForUserWithDb(db, targetUserId);
        }
      }
    }

    final rows = await db.query(
      'logbook_entries',
      where: 'user_id = ?',
      whereArgs: [targetUserId],
      orderBy: 'no DESC',
    );

    return rows.map((row) {
      return LogbookEntry(
        no: row['no'] as int,
        tanggal: row['tanggal'] as String,
        rowNumber: row['row_number'] as int,
        userId: row['user_id'] as int?,
        aktivitas: row['aktivitas'] as String,
        pembelajaran: row['pembelajaran'] as String,
        kendala: row['kendala'] as String,
      );
    }).toList();
  }

  Future<void> addEntry(DraftFields draft, {String? gitLogs, int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? 1;
    final now = DateTime.now();
    final tanggalStr = DateFormat('dd/MM/yyyy').format(now);

    final existing = await db.query(
      'logbook_entries',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [targetUserId, tanggalStr],
    );

    if (existing.isNotEmpty) {
      final existingNo = existing.first['no'] as int;
      await db.update(
        'logbook_entries',
        {
          'aktivitas': draft.aktivitas,
          'pembelajaran': draft.pembelajaran,
          'kendala': draft.kendala,
        },
        where: 'user_id = ? AND no = ?',
        whereArgs: [targetUserId, existingNo],
      );
    } else {
      final maxResult = await db.rawQuery(
        'SELECT MAX(no) as max_no FROM logbook_entries WHERE user_id = ?',
        [targetUserId],
      );
      final currentMax = (maxResult.first['max_no'] as int?) ?? 0;
      final nextNo = currentMax + 1;

      await db.insert(
        'logbook_entries',
        {
          'user_id': targetUserId,
          'no': nextNo,
          'tanggal': tanggalStr,
          'row_number': nextNo,
          'aktivitas': draft.aktivitas,
          'pembelajaran': draft.pembelajaran,
          'kendala': draft.kendala,
          'created_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateEntry(int rowNumber, DraftFields draft, {int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? 1;
    await db.update(
      'logbook_entries',
      {
        'aktivitas': draft.aktivitas,
        'pembelajaran': draft.pembelajaran,
        'kendala': draft.kendala,
      },
      where: 'user_id = ? AND (row_number = ? OR no = ?)',
      whereArgs: [targetUserId, rowNumber, rowNumber],
    );
  }

  Future<void> deleteEntry(int rowNumber, {int? userId}) async {
    final db = await database;
    final targetUserId = userId ?? 1;
    await db.delete(
      'logbook_entries',
      where: 'user_id = ? AND (row_number = ? OR no = ?)',
      whereArgs: [targetUserId, rowNumber, rowNumber],
    );
  }

  Future<void> exportAndShare({int? userId}) async {
    final entries = await loadEntries(userId: userId);
    final sorted = [...entries]..sort((a, b) => a.no.compareTo(b.no));

    final buffer = StringBuffer();
    buffer.writeln('No,Tanggal,Aktivitas Hari Ini,Pembelajaran yang Didapat,Kendala');

    for (final e in sorted) {
      final act = '"${e.aktivitas.replaceAll('"', '""')}"';
      final lrn = '"${e.pembelajaran.replaceAll('"', '""')}"';
      final knd = '"${e.kendala.replaceAll('"', '""')}"';
      buffer.writeln('${e.no},${e.tanggal},$act,$lrn,$knd');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'Logbook_MagangHub_Export.csv'));
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export Logbook MagangHub (${sorted.length} entri)',
      subject: 'Logbook MagangHub',
    );
  }

  // -------------------------------------------------------------
  // Settings Management (SQLite Scoped by userId)
  // -------------------------------------------------------------

  Future<bool> isStandalone() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['is_standalone'],
    );
    if (rows.isEmpty) return true;
    return rows.first['value'] == 'true';
  }

  Future<void> setStandalone(bool value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'is_standalone',
        'value': value ? 'true' : 'false',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static SettingsModel _cleanLegacyDemoRepos(SettingsModel settings) {
    const demoIds = {
      'tmp-1788745953894',
      'zalzdarkent-stockmon-suqc',
      'tmp-1789550473623',
    };
    final cleanedRepos = settings.repositories.where((r) {
      if (demoIds.contains(r.id)) return false;
      final lower = r.url.toLowerCase();
      if (lower.contains('zalzdarkent/absen-maganghub-mobile') ||
          lower.contains('zalzdarkent/stockmonitoring-react') ||
          lower.contains('zalzdarkent/erdjango')) {
        return false;
      }
      return true;
    }).toList();

    final validIds = cleanedRepos.map((r) => r.id).toSet();
    final cleanedDefaultIds =
        settings.defaultRepoIds.where((id) => validIds.contains(id)).toList();
    final cleanedActiveId = (settings.activeRepoId != null &&
            validIds.contains(settings.activeRepoId!))
        ? settings.activeRepoId
        : (cleanedRepos.isNotEmpty ? cleanedRepos.first.id : null);

    return settings.copyWith(
      repositories: cleanedRepos,
      defaultRepoIds: cleanedDefaultIds,
      activeRepoId: cleanedActiveId,
    );
  }

  Future<SettingsModel> loadSettings({int? userId}) async {
    final db = await database;
    if (userId != null) {
      final userRows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['settings_json_user_$userId'],
      );
      if (userRows.isNotEmpty) {
        try {
          final json = jsonDecode(userRows.first['value'] as String);
          final loaded = SettingsModel.fromJson(json as Map<String, dynamic>);
          return _cleanLegacyDemoRepos(loaded);
        } catch (_) {}
      }
      // New user starts completely fresh with default empty repositories
      return defaultSettings;
    }

    // Fallback to legacy global settings (from v1)
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['settings_json'],
    );
    if (rows.isEmpty) return defaultSettings;
    try {
      final json = jsonDecode(rows.first['value'] as String);
      final loaded = SettingsModel.fromJson(json as Map<String, dynamic>);
      return _cleanLegacyDemoRepos(loaded);
    } catch (_) {
      return defaultSettings;
    }
  }

  Future<void> saveSettings(SettingsModel settings, {int? userId}) async {
    final db = await database;
    final jsonStr = jsonEncode(settings.toJson());

    if (userId != null) {
      await db.insert(
        'app_settings',
        {
          'key': 'settings_json_user_$userId',
          'value': jsonStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Keep legacy key updated if user 1 or no user specified
    if (userId == null || userId == 1) {
      await db.insert(
        'app_settings',
        {
          'key': 'settings_json',
          'value': jsonStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
