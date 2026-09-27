import 'package:flutter/foundation.dart';
import '../../data/repositories/settings_repository.dart';
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

  Future<void> init() async {
    _isStandalone = await settingsRepository.isStandalone();
    _serverUrl = await settingsRepository.getSavedServerUrl() ?? '';
    await loadSettings();
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
      await settingsRepository.saveSettings({
        'repositories': updated.map((r) => r.toJson()).toList(),
      });
      await loadSettings();
    } finally {
      _isAddingRepo = false;
      notifyListeners();
    }
  }

  Future<void> deleteRepository(String id) async {
    final updated = _settings.repositories.where((r) => r.id != id).toList();
    await settingsRepository.saveSettings({
      'repositories': updated.map((r) => r.toJson()).toList(),
    });
    await loadSettings();
  }

  Future<void> triggerAutoDraft() async {
    await settingsRepository.triggerAutoDraft();
  }
}
