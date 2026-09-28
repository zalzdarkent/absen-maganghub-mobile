import '../services/api_service.dart';
import '../services/llm_service.dart';
import '../services/local_storage_service.dart';
import '../services/standalone_storage_service.dart';
import '../../domain/models/repository_model.dart';
import '../../domain/models/settings_model.dart';

class SettingsRepository {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  final StandaloneStorageService standaloneStorageService;
  final LlmService llmService;

  SettingsRepository({
    required this.apiService,
    required this.localStorageService,
    required this.standaloneStorageService,
    required this.llmService,
  });

  Future<bool> isStandalone() => standaloneStorageService.isStandalone();
  Future<void> setStandalone(bool value) => standaloneStorageService.setStandalone(value);

  Future<int> reimportVercelData() => standaloneStorageService.reimportFromVercelDataset();

  Future<int> getLogbookCount() async {
    final entries = await standaloneStorageService.loadEntries();
    return entries.length;
  }

  Future<SettingsModel> fetchSettings() async {
    final standalone = await isStandalone();
    if (standalone) {
      return standaloneStorageService.loadSettings();
    }
    return apiService.getSettings();
  }

  Future<void> saveSettings(Map<String, dynamic> payload) async {
    final standalone = await isStandalone();
    if (standalone) {
      final current = await standaloneStorageService.loadSettings();

      List<Repository>? repos;
      if (payload['repositories'] != null) {
        final list = payload['repositories'] as List;
        repos = list.map((item) {
          if (item is Repository) return item;
          return Repository.fromJson(item as Map<String, dynamic>);
        }).toList();
      }

      final updated = current.copyWith(
        llmProvider: payload['llmProvider'] as String?,
        localLlmUrl: payload['localLlmUrl'] as String?,
        localLlmModel: payload['localLlmModel'] as String?,
        localLlmApiKey: payload['localLlmApiKey'] as String?,
        geminiApiKey: payload['apiKey'] as String? ?? payload['geminiApiKey'] as String?,
        geminiModel: payload['geminiModel'] as String?,
        repositories: repos,
        activeRepoId: payload.containsKey('activeRepoId')
            ? payload['activeRepoId'] as String?
            : current.activeRepoId,
        defaultRepoIds: payload.containsKey('defaultRepoIds')
            ? (payload['defaultRepoIds'] != null ? List<String>.from(payload['defaultRepoIds']) : [])
            : current.defaultRepoIds,
      );

      await standaloneStorageService.saveSettings(updated);
      return;
    }

    return apiService.saveSettings(payload);
  }

  Future<Map<String, dynamic>> testLlm(Map<String, dynamic> payload) async {
    final standalone = await isStandalone();
    if (standalone) {
      final settings = await fetchSettings();
      // Apply override from payload if any
      final testConfig = settings.copyWith(
        llmProvider: payload['llmProvider'] as String?,
        localLlmUrl: payload['localLlmUrl'] as String?,
        localLlmModel: payload['localLlmModel'] as String?,
        localLlmApiKey: payload['localLlmApiKey'] as String?,
        geminiApiKey: payload['apiKey'] as String? ?? payload['geminiApiKey'] as String?,
        geminiModel: payload['geminiModel'] as String?,
      );
      return llmService.testConnection(testConfig);
    }

    return apiService.testLlm(payload);
  }

  Future<String?> getSavedServerUrl() {
    return localStorageService.getServerUrl();
  }

  Future<void> setSavedServerUrl(String url) {
    apiService.updateBaseUrl(url);
    return localStorageService.setServerUrl(url);
  }

  Future<List<String>> getSelectedRepoIds() {
    return localStorageService.getSelectedRepoIds();
  }

  Future<void> setSelectedRepoIds(List<String> ids) {
    return localStorageService.setSelectedRepoIds(ids);
  }

  Future<void> triggerAutoDraft({List<String>? repoIds}) async {
    final standalone = await isStandalone();
    if (!standalone) {
      return apiService.triggerAutoDraft(repoIds: repoIds);
    }
  }
}
