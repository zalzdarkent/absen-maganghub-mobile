import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/repository_model.dart';
import '../../domain/models/settings_model.dart';
import '../datasources/initial_logbook_data.dart';

class SqliteDatabaseService {
  static const String _dbName = 'maganghub_logbook.db';
  static const int _dbVersion = 1;

  Database? _db;

  static const SettingsModel defaultSettings = SettingsModel(
    llmProvider: 'local',
    localLlmUrl: 'http://192.168.13.155:3000',
    localLlmModel: 'gpt-oss-20b',
    localLlmApiKey: '',
    geminiModel: 'gemini-3.6-flash',
    geminiApiKey: '',
    activeRepoId: 'tmp-1788745953894',
    defaultRepoIds: ['tmp-1788745953894'],
    repositories: [
      Repository(
        id: 'tmp-1788745953894',
        label: 'Absen Monev',
        url: 'https://github.com/zalzdarkent/absen-maganghub.git',
      ),
      Repository(
        id: 'zalzdarkent-stockmon-suqc',
        label: 'StockMonitoring',
        url: 'https://github.com/zalzdarkent/StockMonitoring-React.git',
      ),
      Repository(
        id: 'tmp-1789550473623',
        label: 'Django',
        url: 'https://github.com/zalzdarkent/ERDJANGO.git',
      ),
    ],
  );

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI for unit tests on desktop/Linux host
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
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
      onOpen: (db) async {
        // Verify tables and seed if empty
        await _createTables(db);
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM logbook_entries'),
        ) ?? 0;
        if (count == 0) {
          await _seedInitialData(db);
        }
      },
    );

    return db;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS logbook_entries (
        no INTEGER PRIMARY KEY,
        tanggal TEXT NOT NULL UNIQUE,
        row_number INTEGER NOT NULL,
        aktivitas TEXT NOT NULL,
        pembelajaran TEXT NOT NULL,
        kendala TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();
    final nowIso = DateTime.now().toIso8601String();

    for (final entry in initialLogbookData) {
      batch.insert(
        'logbook_entries',
        {
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

  /// Memaksa import/sinkronisasi ulang dari dataset Vercel Excel
  Future<int> reimportFromVercelDataset() async {
    final db = await database;
    final batch = db.batch();
    final nowIso = DateTime.now().toIso8601String();

    for (final entry in initialLogbookData) {
      batch.insert(
        'logbook_entries',
        {
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

  // -------------------------------------------------------------
  // Logbook Entries CRUD
  // -------------------------------------------------------------

  Future<List<LogbookEntry>> loadEntries() async {
    final db = await database;
    final rows = await db.query('logbook_entries', orderBy: 'no DESC');

    return rows.map((row) {
      return LogbookEntry(
        no: row['no'] as int,
        tanggal: row['tanggal'] as String,
        rowNumber: row['row_number'] as int,
        aktivitas: row['aktivitas'] as String,
        pembelajaran: row['pembelajaran'] as String,
        kendala: row['kendala'] as String,
      );
    }).toList();
  }

  Future<void> addEntry(DraftFields draft, {String? gitLogs}) async {
    final db = await database;
    final now = DateTime.now();
    final tanggalStr = DateFormat('dd/MM/yyyy').format(now);

    final existing = await db.query(
      'logbook_entries',
      where: 'tanggal = ?',
      whereArgs: [tanggalStr],
    );

    if (existing.isNotEmpty) {
      // Update existing entry for today
      final existingNo = existing.first['no'] as int;
      await db.update(
        'logbook_entries',
        {
          'aktivitas': draft.aktivitas,
          'pembelajaran': draft.pembelajaran,
          'kendala': draft.kendala,
        },
        where: 'no = ?',
        whereArgs: [existingNo],
      );
    } else {
      // Insert new entry with incremented no
      final maxResult = await db.rawQuery('SELECT MAX(no) as max_no FROM logbook_entries');
      final currentMax = (maxResult.first['max_no'] as int?) ?? 0;
      final nextNo = currentMax + 1;

      await db.insert(
        'logbook_entries',
        {
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

  Future<void> updateEntry(int rowNumber, DraftFields draft) async {
    final db = await database;
    await db.update(
      'logbook_entries',
      {
        'aktivitas': draft.aktivitas,
        'pembelajaran': draft.pembelajaran,
        'kendala': draft.kendala,
      },
      where: 'row_number = ? OR no = ?',
      whereArgs: [rowNumber, rowNumber],
    );
  }

  Future<void> deleteEntry(int rowNumber) async {
    final db = await database;
    await db.delete(
      'logbook_entries',
      where: 'row_number = ? OR no = ?',
      whereArgs: [rowNumber, rowNumber],
    );
  }

  Future<void> exportAndShare() async {
    final entries = await loadEntries();
    // Sort chronological for export
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
  // Settings Management (SQLite)
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

  Future<SettingsModel> loadSettings() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['settings_json'],
    );
    if (rows.isEmpty) return defaultSettings;
    try {
      final json = jsonDecode(rows.first['value'] as String);
      return SettingsModel.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return defaultSettings;
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'settings_json',
        'value': jsonEncode(settings.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
