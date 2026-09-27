import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/settings_model.dart';
import 'sqlite_database_service.dart';

/// Standalone storage layer backed by SQLite (`maganghub_logbook.db`).
/// Initialized with all 13 entries parsed directly from `Logbook_MagangHub.xlsx` (Vercel).
class StandaloneStorageService {
  final SqliteDatabaseService _sqlite;
  int? activeUserId;

  StandaloneStorageService({SqliteDatabaseService? sqlite, this.activeUserId, String? dbName})
      : _sqlite = sqlite ?? SqliteDatabaseService(dbName: dbName);

  void setActiveUserId(int? userId) {
    activeUserId = userId;
  }

  SqliteDatabaseService get sqlite => _sqlite;

  static const SettingsModel defaultSettings = SqliteDatabaseService.defaultSettings;

  Future<bool> isStandalone() => _sqlite.isStandalone();

  Future<void> setStandalone(bool value) => _sqlite.setStandalone(value);

  Future<SettingsModel> loadSettings({int? userId}) =>
      _sqlite.loadSettings(userId: userId ?? activeUserId);

  Future<void> saveSettings(SettingsModel settings, {int? userId}) =>
      _sqlite.saveSettings(settings, userId: userId ?? activeUserId);

  Future<List<LogbookEntry>> loadEntries({int? userId}) =>
      _sqlite.loadEntries(userId: userId ?? activeUserId);

  Future<void> addEntry(DraftFields draft, {String? gitLogs, int? userId}) =>
      _sqlite.addEntry(draft, gitLogs: gitLogs, userId: userId ?? activeUserId);

  Future<void> updateEntry(int rowNumber, DraftFields draft, {int? userId}) =>
      _sqlite.updateEntry(rowNumber, draft, userId: userId ?? activeUserId);

  Future<void> deleteEntry(int rowNumber, {int? userId}) =>
      _sqlite.deleteEntry(rowNumber, userId: userId ?? activeUserId);

  Future<void> exportAndShare({int? userId}) =>
      _sqlite.exportAndShare(userId: userId ?? activeUserId);

  Future<int> reimportFromVercelDataset({int? userId}) =>
      _sqlite.reimportFromVercelDataset(userId: userId ?? activeUserId);
}
