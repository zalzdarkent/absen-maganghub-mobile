import 'package:flutter/foundation.dart';
import '../../core/theme/app_accent_theme.dart';
import '../../core/theme/ios_colors.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/repository_model.dart';
import '../../domain/models/settings_model.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository settingsRepository;

  SettingsViewModel({required this.settingsRepository});

  SettingsModel _settings = const SettingsModel();
  String _serverUrl = '';
  bool _isStandalone = true;
  bool _isLoading = false;
  bool _isSavingLlm = false;
  bool _isTestingLlm = false;
  bool _isAddingRepo = false;
  Map<String, dynamic>? _testResult;
  String? _errorMessage;

  int _sqliteEntryCount = 0;
  bool _isReimporting = false;

  AccentColorTheme _accentTheme = AccentColorTheme.emerald;

  bool _isDailyReminderEnabled = true;
  int _reminderHour = 15;
  int _reminderMinute = 0;
  bool _isSendingTestNotif = false;
  String? _testNotifStatus;

  SettingsModel get settings => _settings;
  String get serverUrl => _serverUrl;
  bool get isStandalone => _isStandalone;
  bool get isLoading => _isLoading;
  bool get isSavingLlm => _isSavingLlm;
  bool get isTestingLlm => _isTestingLlm;
  bool get isAddingRepo => _isAddingRepo;
  bool get isReimporting => _isReimporting;
  int get sqliteEntryCount => _sqliteEntryCount;
  Map<String, dynamic>? get testResult => _testResult;
  String? get errorMessage => _errorMessage;

  AccentColorTheme get accentTheme => _accentTheme;
  bool get isSusanooTheme => _accentTheme == AccentColorTheme.susanoo;

  bool get isDailyReminderEnabled => _isDailyReminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get isSendingTestNotif => _isSendingTestNotif;
  String? get testNotifStatus => _testNotifStatus;

  Future<void> init() async {
    _isStandalone = await settingsRepository.isStandalone();
    _serverUrl = await settingsRepository.getSavedServerUrl() ?? '';
    final savedThemeStr = await settingsRepository.getAccentTheme();
    _accentTheme = AccentColorThemeExtension.fromString(savedThemeStr);
    IosColors.setAccentTheme(_accentTheme);
    _isDailyReminderEnabled = await settingsRepository.isDailyReminderEnabled();
    _reminderHour = await settingsRepository.getReminderHour();
    _reminderMinute = await settingsRepository.getReminderMinute();
    await loadSettings();
  }

  Future<void> setAccentTheme(AccentColorTheme theme) async {
    if (_accentTheme == theme) return;
    _accentTheme = theme;
    IosColors.setAccentTheme(theme);
    await settingsRepository.setAccentTheme(theme.name);
    notifyListeners();
  }

  Future<void> toggleAccentTheme() async {
    final next = _accentTheme == AccentColorTheme.emerald
        ? AccentColorTheme.susanoo
        : AccentColorTheme.emerald;
    await setAccentTheme(next);
  }

  Future<void> toggleStandalone(bool value) async {
    _isStandalone = value;
    await settingsRepository.setStandalone(value);
    notifyListeners();
    await loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await settingsRepository.fetchSettings();
      _sqliteEntryCount = await settingsRepository.getLogbookCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> reimportFromVercel() async {
    _isReimporting = true;
    notifyListeners();
    try {
      final count = await settingsRepository.reimportVercelData();
      _sqliteEntryCount = count;
      return count;
    } finally {
      _isReimporting = false;
      notifyListeners();
    }
  }

  Future<void> updateServerUrl(String newUrl) async {
    _serverUrl = newUrl;
    await settingsRepository.setSavedServerUrl(newUrl);
    notifyListeners();
    await loadSettings();
  }

  Future<void> saveLlmSettings({
    required String provider,
    required String localLlmUrl,
    required String localLlmModel,
    required String localLlmApiKey,
    required String geminiModel,
    String? geminiApiKey,
  }) async {
    _isSavingLlm = true;
    _testResult = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'llmProvider': provider,
        'localLlmUrl': localLlmUrl,
        'localLlmModel': localLlmModel,
        'localLlmApiKey': localLlmApiKey,
        'geminiModel': geminiModel,
      };
      if (geminiApiKey != null && geminiApiKey.trim().isNotEmpty) {
        payload['apiKey'] = geminiApiKey.trim();
      }
      await settingsRepository.saveSettings(payload);
      await loadSettings();
    } finally {
      _isSavingLlm = false;
      notifyListeners();
    }
  }

  Future<void> testLlm({
    required String provider,
    required String localLlmUrl,
    required String localLlmModel,
    required String localLlmApiKey,
    required String geminiModel,
    String? geminiApiKey,
  }) async {
    _isTestingLlm = true;
    _testResult = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'provider': provider,
        'llmProvider': provider,
        'localLlmUrl': localLlmUrl,
        'localLlmModel': localLlmModel,
        'localLlmApiKey': localLlmApiKey,
        'geminiModel': geminiModel,
      };
      if (geminiApiKey != null && geminiApiKey.trim().isNotEmpty) {
        payload['apiKey'] = geminiApiKey.trim();
        payload['geminiApiKey'] = geminiApiKey.trim();
      }
      final res = await settingsRepository.testLlm(payload);
      _testResult = res;
    } catch (e) {
      _testResult = {'ok': false, 'message': e.toString()};
    } finally {
      _isTestingLlm = false;
      notifyListeners();
    }
  }

  Future<void> addRepository(String label, String url) async {
    _isAddingRepo = true;
    notifyListeners();

    try {
      final current = _settings.repositories;
      final newRepo = Repository(
        id: 'repo-${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        url: url,
      );
      final updated = [...current, newRepo];
      final activeId = _settings.activeRepoId ?? newRepo.id;
      final defaultIds = _settings.defaultRepoIds.isNotEmpty
          ? (_settings.defaultRepoIds.contains(newRepo.id)
              ? _settings.defaultRepoIds
              : [..._settings.defaultRepoIds, newRepo.id])
          : [newRepo.id];

      await settingsRepository.saveSettings({
        'repositories': updated.map((r) => r.toJson()).toList(),
        'activeRepoId': activeId,
        'defaultRepoIds': defaultIds,
      });
      await loadSettings();
    } finally {
      _isAddingRepo = false;
      notifyListeners();
    }
  }

  Future<void> deleteRepository(String id) async {
    final updated = _settings.repositories.where((r) => r.id != id).toList();
    final activeId = _settings.activeRepoId == id
        ? (updated.isNotEmpty ? updated.first.id : null)
        : _settings.activeRepoId;
    final defaultIds = _settings.defaultRepoIds.where((x) => x != id).toList();

    await settingsRepository.saveSettings({
      'repositories': updated.map((r) => r.toJson()).toList(),
      'activeRepoId': activeId,
      'defaultRepoIds': defaultIds,
    });
    await loadSettings();
  }

  Future<void> triggerAutoDraft() async {
    await settingsRepository.triggerAutoDraft();
  }

  Future<void> toggleDailyReminder(bool value) async {
    _isDailyReminderEnabled = value;
    await settingsRepository.setDailyReminderEnabled(value);
    final notifService = NotificationService();
    if (value) {
      await notifService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
      );
    } else {
      await notifService.cancelDailyReminder();
    }
    notifyListeners();
  }

  Future<void> sendTestNotification() async {
    _isSendingTestNotif = true;
    _testNotifStatus = null;
    notifyListeners();

    try {
      final notifService = NotificationService();
      await notifService.requestPermissions();
      await notifService.showTestNotification();
      _testNotifStatus = 'Notifikasi tes berhasil dikirim! Silakan periksa bilah notifikasi HP Anda.';
    } catch (e) {
      _testNotifStatus = 'Gagal mengirim notifikasi tes: $e';
    } finally {
      _isSendingTestNotif = false;
      notifyListeners();
    }
  }
}
