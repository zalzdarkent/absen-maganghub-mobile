import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:absen_maganghub/data/services/sqlite_database_service.dart';
import 'package:absen_maganghub/domain/models/logbook_entry_model.dart';
import 'package:absen_maganghub/domain/models/repository_model.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
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
  });

  group('Auth & Multi-User SQLite Tests', () {
    test('Register user hashes password and allows login with username or email', () async {
      final dbName = 'test_auth_${DateTime.now().microsecondsSinceEpoch}.db';
      final service = SqliteDatabaseService(dbName: dbName);

      // Register user 1
      final user1 = await service.registerUser(
        username: 'zalzdarkent',
        email: 'zalz@example.com',
        password: 'password123',
        name: 'Zalz',
      );

      expect(user1.username, 'zalzdarkent');
      expect(user1.email, 'zalz@example.com');
      expect(user1.name, 'Zalz');

      // Login with username
      final loggedInByUsername = await service.loginUser(
        usernameOrEmail: 'zalzdarkent',
        password: 'password123',
      );
      expect(loggedInByUsername.id, user1.id);

      // Login with email
      final loggedInByEmail = await service.loginUser(
        usernameOrEmail: 'zalz@example.com',
        password: 'password123',
      );
      expect(loggedInByEmail.id, user1.id);

      // Wrong password fails
      expect(
        () => service.loginUser(
          usernameOrEmail: 'zalzdarkent',
          password: 'wrongpassword',
        ),
        throwsException,
      );

      // Duplicate registration fails
      expect(
        () => service.registerUser(
          username: 'zalzdarkent',
          email: 'different@example.com',
          password: 'password123',
        ),
        throwsException,
      );

      // Register user 2
      final user2 = await service.registerUser(
        username: 'userdua',
        email: 'dua@example.com',
        password: 'password456',
        name: 'User Dua',
      );
      expect(user2.id, isNot(user1.id));

      // Test data isolation: user 1 and user 2 can both have entry on same date!
      await service.addEntry(
        const DraftFields(
          aktivitas: 'Aktivitas user A hari ini mencatat progres fitur autentikasi.',
          pembelajaran: 'Pembelajaran user A hari ini...',
          kendala: 'Tidak ada kendala untuk user A.',
        ),
        userId: user1.id,
      );

      await service.addEntry(
        const DraftFields(
          aktivitas: 'Aktivitas user B hari ini mandiri dan terpisah dari catatan lain.',
          pembelajaran: 'Pembelajaran user B hari ini...',
          kendala: 'Tidak ada kendala untuk user B.',
        ),
        userId: user2.id,
      );

      final user1Entries = await service.loadEntries(userId: user1.id);
      final user2Entries = await service.loadEntries(userId: user2.id);

      expect(user1Entries.any((e) => e.aktivitas.contains('user A')), isTrue);
      expect(user2Entries.any((e) => e.aktivitas.contains('user B')), isTrue);
      expect(user1Entries.any((e) => e.aktivitas.contains('user B')), isFalse);
      expect(user2Entries.any((e) => e.aktivitas.contains('user A')), isFalse);
    });

    test('User with username alif automatically gets seeded with Logbook_MagangHub.xlsx entries', () async {
      final dbName = 'test_alif_${DateTime.now().microsecondsSinceEpoch}.db';
      final service = SqliteDatabaseService(dbName: dbName);

      // Register 'alif'
      final alifUser = await service.registerUser(
        username: 'alif',
        email: 'alif@example.com',
        password: 'password123',
        name: 'Alif',
      );

      // Should automatically have all 13 entries from Logbook_MagangHub.xlsx
      final entries = await service.loadEntries(userId: alifUser.id);
      expect(entries.length, 13);
      expect(entries.first.aktivitas, isNotEmpty);
      expect(entries.last.aktivitas, isNotEmpty);

      // Login as 'alif' also preserves and ensures the entries
      final loggedIn = await service.loginUser(
        usernameOrEmail: 'alif',
        password: 'password123',
      );
      final loggedInEntries = await service.loadEntries(userId: loggedIn.id);
      expect(loggedInEntries.length, 13);
    });

    test('New user starts with completely empty repositories and can save repos to SQLite', () async {
      final dbName = 'test_settings_${DateTime.now().microsecondsSinceEpoch}.db';
      final service = SqliteDatabaseService(dbName: dbName);

      // Register a new user
      final user = await service.registerUser(
        username: 'budisantoso',
        email: 'budi@example.com',
        password: 'password123',
        name: 'Budi Santoso',
      );

      // Load settings for fresh user -> must be completely empty repositories
      final settings = await service.loadSettings(userId: user.id);
      expect(settings.repositories, isEmpty);
      expect(settings.activeRepoId, isNull);
      expect(settings.defaultRepoIds, isEmpty);

      // Save custom repository for this user
      final customRepo = Repository(
        id: 'repo-12345',
        label: 'My Custom Repo',
        url: 'https://github.com/budisantoso/my-custom-project.git',
      );
      final updatedSettings = settings.copyWith(
        repositories: [customRepo],
        activeRepoId: customRepo.id,
        defaultRepoIds: [customRepo.id],
      );
      await service.saveSettings(updatedSettings, userId: user.id);

      // Reload settings for this user
      final reloaded = await service.loadSettings(userId: user.id);
      expect(reloaded.repositories.length, 1);
      expect(reloaded.repositories.first.label, 'My Custom Repo');
      expect(reloaded.repositories.first.url, 'https://github.com/budisantoso/my-custom-project.git');
      expect(reloaded.activeRepoId, 'repo-12345');
      expect(reloaded.defaultRepoIds, ['repo-12345']);

      // Register another user
      final user2 = await service.registerUser(
        username: 'dewi',
        email: 'dewi@example.com',
        password: 'password123',
        name: 'Dewi',
      );
      // User 2 must start with empty repositories as well
      final user2Settings = await service.loadSettings(userId: user2.id);
      expect(user2Settings.repositories, isEmpty);
    });

    test('User can register repository with zalzdarkent project url without being filtered out', () async {
      final dbName = 'test_zalz_repo_${DateTime.now().microsecondsSinceEpoch}.db';
      final service = SqliteDatabaseService(dbName: dbName);

      final user = await service.registerUser(
        username: 'zalzdarkent',
        email: 'zalz@example.com',
        password: 'password123',
      );

      final settings = await service.loadSettings(userId: user.id);
      expect(settings.repositories, isEmpty);

      final newRepo = Repository(
        id: 'repo-${DateTime.now().millisecondsSinceEpoch}',
        label: 'Absen MagangHub Mobile',
        url: 'https://github.com/zalzdarkent/absen-maganghub-mobile.git',
      );

      await service.saveSettings(
        settings.copyWith(
          repositories: [newRepo],
          activeRepoId: newRepo.id,
          defaultRepoIds: [newRepo.id],
        ),
        userId: user.id,
      );

      final loaded = await service.loadSettings(userId: user.id);
      expect(loaded.repositories.length, 1);
      expect(loaded.repositories.first.url, 'https://github.com/zalzdarkent/absen-maganghub-mobile.git');
      expect(loaded.repositories.first.label, 'Absen MagangHub Mobile');
      expect(loaded.activeRepoId, newRepo.id);
    });
  });
}
