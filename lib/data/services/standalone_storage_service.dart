import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/settings_model.dart';
import 'sqlite_database_service.dart';

/// Standalone storage layer backed by SQLite (`maganghub_logbook.db`).
/// Initialized with all 13 entries parsed directly from `Logbook_MagangHub.xlsx` (Vercel).
class StandaloneStorageService {
  final SqliteDatabaseService _sqlite;

  StandaloneStorageService({SqliteDatabaseService? sqlite})
      : _sqlite = sqlite ?? SqliteDatabaseService();

  SqliteDatabaseService get sqlite => _sqlite;

  static const SettingsModel defaultSettings = SqliteDatabaseService.defaultSettings;

  Future<bool> isStandalone() => _sqlite.isStandalone();

  Future<void> setStandalone(bool value) => _sqlite.setStandalone(value);

  Future<SettingsModel> loadSettings() => _sqlite.loadSettings();

  Future<void> saveSettings(SettingsModel settings) => _sqlite.saveSettings(settings);

  Future<List<LogbookEntry>> loadEntries() => _sqlite.loadEntries();

  Future<void> addEntry(DraftFields draft, {String? gitLogs}) =>
      _sqlite.addEntry(draft, gitLogs: gitLogs);

  Future<void> updateEntry(int rowNumber, DraftFields draft) =>
      _sqlite.updateEntry(rowNumber, draft);

  Future<void> deleteEntry(int rowNumber) => _sqlite.deleteEntry(rowNumber);

  Future<void> exportAndShare() => _sqlite.exportAndShare();

  Future<int> reimportFromVercelDataset() => _sqlite.reimportFromVercelDataset();
}
