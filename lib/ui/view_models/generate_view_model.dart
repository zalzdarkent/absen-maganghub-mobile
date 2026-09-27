import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/logbook_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/api_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../domain/models/commit_model.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/repository_model.dart';
import '../../domain/models/status_model.dart';

class GenerateViewModel extends ChangeNotifier {
  final LogbookRepository logbookRepository;
  final SettingsRepository settingsRepository;
  final LocalStorageService localStorageService;

  GenerateViewModel({
    required this.logbookRepository,
    required this.settingsRepository,
    required this.localStorageService,
  });

  // State
  String _gitLogs = '';
  List<Commit> _commits = const [];
  String _detailed = '';
  StatusKind _statusKind = StatusKind.idle;
  String _statusText = 'memeriksa…';
  String? _errorMessage;
  bool _isLoadingCommits = false;

  List<Repository> _repositories = const [];
  List<String> _selectedRepoIds = [];

  DraftFields? _draft;
  bool _manualMode = false;
  String _lastMode = 'commit'; // 'commit' | 'manual' | 'combined'
  String _lastCombinedNotes = '';
  String _lastManualNotes = '';

  bool _isGenerating = false;
  String _generateLabel = 'Menyusun draft...';
  double _elapsedSeconds = 0.0;
  Timer? _timer;
  int _startTime = 0;

  bool _isSaving = false;
  int? _autoSavedAt;
  String _activeProvider = 'local'; // 'local' | 'gemini'

  // Getters
  String get gitLogs => _gitLogs;
  List<Commit> get commits => _commits;
  String get detailed => _detailed;
  StatusKind get statusKind => _statusKind;
  String get statusText => _statusText;
  String? get errorMessage => _errorMessage;
  bool get isLoadingCommits => _isLoadingCommits;

  List<Repository> get repositories => _repositories;
  List<String> get selectedRepoIds => _selectedRepoIds;

  DraftFields? get draft => _draft;
  bool get manualMode => _manualMode;
  String get lastMode => _lastMode;
  bool get isGenerating => _isGenerating;
  String get generateLabel => _generateLabel;
  double get elapsedSeconds => _elapsedSeconds;
  bool get isSaving => _isSaving;
  int? get autoSavedAt => _autoSavedAt;
  String get activeProvider => _activeProvider;

  int get commitCount =>
      _commits.isNotEmpty ? _commits.length : _gitLogs.trim().split('\n').where((s) => s.isNotEmpty).length;

  Future<void> init() async {
    await _loadSavedDraft();
    await _loadSettingsAndRepos();
    await loadStatus();
    _checkAutoDraft();
  }

  Future<void> _loadSavedDraft() async {
    try {
      final saved = await localStorageService.getAutoSavedDraft();
      if (saved != null && saved['draft'] != null) {
        _draft = DraftFields.fromJson(saved['draft'] as Map<String, dynamic>);
        _lastMode = saved['mode'] as String? ?? 'commit';
        _lastManualNotes = saved['manualNotes'] as String? ?? '';
        _lastCombinedNotes = saved['combinedNotes'] as String? ?? '';
        _autoSavedAt = (saved['savedAt'] as num?)?.toInt();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _loadSettingsAndRepos() async {
    try {
      final settings = await settingsRepository.fetchSettings();
      _repositories = settings.repositories;
      _activeProvider = settings.llmProvider;

      final savedIds = await settingsRepository.getSelectedRepoIds();
      final validIds = _repositories.map((r) => r.id).toSet();

      final filtered = savedIds.where((id) => validIds.contains(id)).toList();
      if (filtered.isNotEmpty) {
        _selectedRepoIds = filtered;
      } else if (settings.defaultRepoIds.isNotEmpty) {
        _selectedRepoIds = settings.defaultRepoIds.where((id) => validIds.contains(id)).take(3).toList();
      } else if (settings.activeRepoId != null && validIds.contains(settings.activeRepoId!)) {
        _selectedRepoIds = [settings.activeRepoId!];
      } else if (_repositories.isNotEmpty) {
        _selectedRepoIds = [_repositories.first.id];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleRepo(String id) async {
    if (_selectedRepoIds.contains(id)) {
      if (_selectedRepoIds.length > 1) {
        _selectedRepoIds = _selectedRepoIds.where((x) => x != id).toList();
      }
    } else {
      _selectedRepoIds = [..._selectedRepoIds, id].take(5).toList();
    }
    await settingsRepository.setSelectedRepoIds(_selectedRepoIds);
    notifyListeners();
    await loadStatus();
  }

  Future<void> switchProvider(String newProvider) async {
    if (newProvider == _activeProvider) return;
    _activeProvider = newProvider;
    notifyListeners();
    try {
      await settingsRepository.saveSettings({'llmProvider': newProvider});
    } catch (_) {}
  }

  Future<void> loadStatus() async {
    _isLoadingCommits = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await logbookRepository.fetchStatus(
        repoIds: _selectedRepoIds.isNotEmpty ? _selectedRepoIds : null,
      );
      _gitLogs = data.gitLogs;
      _commits = data.commits;
      _detailed = data.detailed;

      if (!data.hasCommitsToday) {
        _statusKind = StatusKind.warn;
        _statusText = 'belum ada commit hari ini';
      } else if (data.alreadyGenerated) {
        _statusKind = StatusKind.ok;
        _statusText = 'sudah di-generate hari ini';
      } else {
        _statusKind = StatusKind.ok;
        _statusText = 'Siap!';
      }
    } on ApiException catch (e) {
      _statusKind = StatusKind.err;
      _errorMessage = e.message;
      if (e.message.toLowerCase().contains('tidak dapat dihubungi') ||
          e.message.toLowerCase().contains('timeout') ||
          e.message.toLowerCase().contains('koneksi')) {
        _statusText = 'server terputus';
      } else {
        _statusText = 'repo bermasalah';
      }
    } catch (e) {
      _statusKind = StatusKind.err;
      _errorMessage = e.toString();
      _statusText = 'repo bermasalah';
    } finally {
      _isLoadingCommits = false;
      notifyListeners();
    }
  }

  Future<void> _checkAutoDraft() async {
    if (_draft != null && !_draft!.isEmpty) return;
    try {
      final data = await logbookRepository.checkAutoDraft(
        repoIds: _selectedRepoIds.isNotEmpty ? _selectedRepoIds : null,
      );
      if (data != null && data['draft'] != null) {
        final d = DraftFields.fromJson(data['draft'] as Map<String, dynamic>);
        if (d.aktivitas.isNotEmpty && d.pembelajaran.isNotEmpty) {
          _draft = d;
          _lastMode = 'commit';
          _manualMode = false;
          _autoSavedAt = DateTime.now().millisecondsSinceEpoch;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _startTimer(String label) {
    _generateLabel = label;
    _isGenerating = true;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _elapsedSeconds = 0.0;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final sec = (DateTime.now().millisecondsSinceEpoch - _startTime) / 1000.0;
      _elapsedSeconds = sec;
      if (sec > 25) {
        _generateLabel = 'Hampir selesai...';
      } else if (sec > 15) {
        _generateLabel = 'Sedikit lagi...';
      } else if (sec > 8) {
        _generateLabel = 'Menyusun draft...';
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void _stopTimer() {
    _isGenerating = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void updateDraft({String? aktivitas, String? pembelajaran, String? kendala}) {
    if (_draft == null) {
      _draft = DraftFields(
        aktivitas: aktivitas ?? '',
        pembelajaran: pembelajaran ?? '',
        kendala: kendala ?? '',
      );
    } else {
      _draft = _draft!.copyWith(
        aktivitas: aktivitas,
        pembelajaran: pembelajaran,
        kendala: kendala,
      );
    }
    _autoSavedAt = DateTime.now().millisecondsSinceEpoch;
    _saveDraftAuto();
    notifyListeners();
  }

  void _saveDraftAuto() {
    if (_draft == null) {
      localStorageService.clearLocalDraft();
    } else {
      localStorageService.saveDraftLocally(
        draft: _draft!,
        mode: _lastMode,
        manualNotes: _lastManualNotes,
        combinedNotes: _lastCombinedNotes,
      );
    }
  }

  Future<void> generateDraft() async {
    _startTimer('Menyusun draft...');
    try {
      final data = await logbookRepository.generateDraft(
        repoIds: _selectedRepoIds.isNotEmpty ? _selectedRepoIds : null,
      );
      if (data['gitLogs'] != null) _gitLogs = data['gitLogs'].toString();
      if (data['diffSection'] != null) _detailed = data['diffSection'].toString();
      if (data['commits'] != null && data['commits'] is List) {
        _commits = (data['commits'] as List)
            .map((e) => Commit.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data['draft'] != null) {
        _draft = DraftFields.fromJson(data['draft'] as Map<String, dynamic>);
      }
      _lastMode = 'commit';
      _manualMode = false;
      _autoSavedAt = DateTime.now().millisecondsSinceEpoch;
      _saveDraftAuto();
    } finally {
      _stopTimer();
    }
  }

  Future<void> generateManualDraft(String description) async {
    _startTimer('Menyusun draft manual...');
    try {
      final res = await logbookRepository.generateManualDraft(description);
      _draft = res;
      _lastMode = 'manual';
      _lastManualNotes = description;
      _manualMode = true;
      _autoSavedAt = DateTime.now().millisecondsSinceEpoch;
      _saveDraftAuto();
    } finally {
      _stopTimer();
    }
  }

  Future<void> generateCombinedDraft(String notes) async {
    _startTimer('Menggabungkan & menyusun draft...');
    try {
      final data = await logbookRepository.generateCombinedDraft(
        manualNotes: notes,
        gitLogs: _gitLogs,
        diffSection: _detailed,
        repoIds: _selectedRepoIds.isNotEmpty ? _selectedRepoIds : null,
      );
      if (data['draft'] != null) {
        _draft = DraftFields.fromJson(data['draft'] as Map<String, dynamic>);
      }
      _lastMode = 'combined';
      _lastCombinedNotes = notes;
      _manualMode = false;
      _autoSavedAt = DateTime.now().millisecondsSinceEpoch;
      _saveDraftAuto();
    } finally {
      _stopTimer();
    }
  }

  Future<void> regenerate() async {
    if (_lastMode == 'combined' && _lastCombinedNotes.isNotEmpty) {
      await generateCombinedDraft(_lastCombinedNotes);
      return;
    }
    if (_lastMode == 'manual' && _lastManualNotes.isNotEmpty) {
      await generateManualDraft(_lastManualNotes);
      return;
    }
    await generateDraft();
  }

  void resetDraft() {
    _draft = null;
    _manualMode = false;
    _lastMode = 'commit';
    _autoSavedAt = null;
    localStorageService.clearLocalDraft();
    notifyListeners();
  }

  Future<void> saveEntry() async {
    if (_draft == null) return;
    if (!_draft!.isCompliant) {
      throw Exception('Tiap field minimal 100 karakter.');
    }

    _isSaving = true;
    notifyListeners();

    try {
      await logbookRepository.saveEntry(
        _draft!,
        gitLogs: _manualMode ? null : _gitLogs,
      );
      await logbookRepository.clearAutoDraft();
      resetDraft();
      await loadStatus();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<CommitDiffResponse> getCommitDiff(String sha) {
    return logbookRepository.fetchCommitDiff(sha);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
