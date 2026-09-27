// ignore_for_file: avoid_print
import 'dart:ffi';
import 'dart:io';
import 'package:absen_maganghub/data/datasources/initial_logbook_data.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

void main(List<String> args) async {
  // Override for Linux SQLite Dynamic Library if needed
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
  final databaseFactory = databaseFactoryFfiNoIsolate;

  String dbPath;
  if (args.isNotEmpty) {
    dbPath = args[0];
  } else {
    // Check known default paths
    final defaultDartToolDb = p.join(
      Directory.current.path,
      '.dart_tool',
      'sqflite_common_ffi',
      'databases',
      'maganghub_logbook.db',
    );

    if (File(defaultDartToolDb).existsSync()) {
      dbPath = defaultDartToolDb;
    } else {
      final dbDir = await databaseFactory.getDatabasesPath();
      dbPath = p.join(dbDir, 'maganghub_logbook.db');
    }
  }

  print('\n=======================================================');
  print('🚀 Menjalankan Seeding Logbook untuk username == \'alif\'');
  print('📁 Database Path: $dbPath');
  print('=======================================================');

  final db = await databaseFactory.openDatabase(dbPath);

  // Pastikan tabel users ada
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

  // Pastikan tabel logbook_entries ada
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

  final nowIso = DateTime.now().toIso8601String();

  // Cari user 'alif'
  final users = await db.query(
    'users',
    where: 'LOWER(username) = ?',
    whereArgs: ['alif'],
  );

  int alifUserId;
  if (users.isEmpty) {
    print('👤 User \'alif\' belum ada, membuat user baru...');
    alifUserId = await db.insert('users', {
      'username': 'alif',
      'email': 'alif@maganghub.local',
      'password_hash': 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', // '123'
      'name': 'Alif',
      'created_at': nowIso,
    });
    print('✅ User \'alif\' berhasil dibuat dengan ID: $alifUserId');
  } else {
    alifUserId = users.first['id'] as int;
    print('👤 User \'alif\' ditemukan dengan ID: $alifUserId');
  }

  // Masukkan 13 entri dari Logbook_MagangHub.xlsx (initialLogbookData)
  final batch = db.batch();
  for (final entry in initialLogbookData) {
    batch.insert(
      'logbook_entries',
      {
        'user_id': alifUserId,
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

  final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM logbook_entries WHERE user_id = ?', [alifUserId]);
  final count = (countResult.first['cnt'] as int?) ?? 0;

  print('🎉 Selesai! Sebanyak ${initialLogbookData.length} entri dari Logbook_MagangHub.xlsx');
  print('   berhasil dimasukkan untuk user \'alif\' (ID: $alifUserId).');
  print('📊 Total entri logbook aktif untuk user \'alif\': $count entri.');
  print('=======================================================\n');

  await db.close();
}
