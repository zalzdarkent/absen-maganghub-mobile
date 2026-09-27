import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/github_service.dart';
import '../services/llm_service.dart';
import '../services/standalone_storage_service.dart';
import 'settings_repository.dart';
import '../../domain/models/commit_model.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/recap_model.dart';
import '../../domain/models/status_model.dart';

class LogbookRepository {
  final ApiService apiService;
  final GithubService githubService;
  final LlmService llmService;
  final StandaloneStorageService standaloneStorageService;
  final SettingsRepository settingsRepository;

  LogbookRepository({
    required this.apiService,
    required this.githubService,
    required this.llmService,
    required this.standaloneStorageService,
    required this.settingsRepository,
  });

  Future<bool> _isStandalone() => settingsRepository.isStandalone();

  Future<StatusResponse> fetchStatus({List<String>? repoIds}) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final settings = await settingsRepository.fetchSettings();
      final selected = repoIds ?? (settings.defaultRepoIds.isNotEmpty ? settings.defaultRepoIds : [settings.repositories.first.id]);
      return githubService.fetchCombinedStatus(
        repositories: settings.repositories,
        selectedRepoIds: selected,
        token: settings.githubToken,
      );
    }
    return apiService.getStatus(repoIds: repoIds);
  }

  Future<CommitDiffResponse> fetchCommitDiff(String sha) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final settings = await settingsRepository.fetchSettings();
      final repo = settings.repositories.isNotEmpty ? settings.repositories.first : null;
      if (repo == null) {
        return CommitDiffResponse(sha: sha, patch: 'Tidak ada repository terdaftar');
      }
      return githubService.fetchCommitDiff(repo.url, sha, token: settings.githubToken);
    }
    return apiService.getCommitDiff(sha);
  }

  Future<Map<String, dynamic>> generateDraft({List<String>? repoIds}) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final status = await fetchStatus(repoIds: repoIds);
      final settings = await settingsRepository.fetchSettings();
      final draft = await llmService.generateDraft(
        gitLogs: status.gitLogs,
        diffSection: status.detailed,
        settings: settings,
      );
      return {
        'draft': draft.toJson(),
        'gitLogs': status.gitLogs,
        'detailed': status.detailed,
        'commits': status.commits.map((c) => c.toJson()).toList(),
      };
    }
    return apiService.generateDraft(repoIds: repoIds);
  }

  Future<DraftFields> generateManualDraft(String description) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final settings = await settingsRepository.fetchSettings();
      return llmService.generateManualDraft(
        description: description,
        settings: settings,
      );
    }
    return apiService.generateManualDraft(description);
  }

  Future<Map<String, dynamic>> generateCombinedDraft({
    required String manualNotes,
    String? gitLogs,
    String? diffSection,
    List<String>? repoIds,
  }) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final settings = await settingsRepository.fetchSettings();
      final draft = await llmService.generateCombinedDraft(
        gitLogs: gitLogs ?? '',
        manualNotes: manualNotes,
        diffSection: diffSection ?? '',
        settings: settings,
      );
      return {
        'draft': draft.toJson(),
        'gitLogs': gitLogs,
        'detailed': diffSection,
      };
    }
    return apiService.generateCombinedDraft(
      manualNotes: manualNotes,
      gitLogs: gitLogs,
      diffSection: diffSection,
      repoIds: repoIds,
    );
  }

  Future<RecapModel> generateRecap(String period) async {
    final standalone = await _isStandalone();
    if (standalone) {
      final entries = await standaloneStorageService.loadEntries();
      final settings = await settingsRepository.fetchSettings();
      return llmService.generateRecap(
        entries: entries,
        period: period,
        settings: settings,
      );
    }
    return apiService.generateRecap(period);
  }

  Future<List<LogbookEntry>> fetchEntries() async {
    final standalone = await _isStandalone();
    if (standalone) {
      return standaloneStorageService.loadEntries();
    }
    return apiService.getEntries();
  }

  Future<void> saveEntry(DraftFields draft, {String? gitLogs}) async {
    final standalone = await _isStandalone();
    if (standalone) {
      return standaloneStorageService.addEntry(draft, gitLogs: gitLogs);
    }
    return apiService.saveEntry(draft, gitLogs: gitLogs);
  }

  Future<void> updateEntry(int rowNumber, DraftFields draft) async {
    final standalone = await _isStandalone();
    if (standalone) {
      return standaloneStorageService.updateEntry(rowNumber, draft);
    }
    return apiService.updateEntry(rowNumber, draft);
  }

  Future<void> deleteEntry(int rowNumber) async {
    final standalone = await _isStandalone();
    if (standalone) {
      return standaloneStorageService.deleteEntry(rowNumber);
    }
    return apiService.deleteEntry(rowNumber);
  }

  Future<Uint8List> exportExcel() async {
    final standalone = await _isStandalone();
    if (standalone) {
      await standaloneStorageService.exportAndShare();
      return Uint8List(0);
    }
    return apiService.downloadExcelBytes();
  }

  Future<Map<String, dynamic>?> checkAutoDraft({List<String>? repoIds}) async {
    final standalone = await _isStandalone();
    if (standalone) {
      return null;
    }
    return apiService.getAutoDraft(repoIds: repoIds);
  }

  Future<void> clearAutoDraft() async {
    final standalone = await _isStandalone();
    if (standalone) {
      return;
    }
    return apiService.deleteAutoDraft();
  }
}
