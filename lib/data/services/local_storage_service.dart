import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/logbook_entry_model.dart';

class LocalStorageService {
  static const String _keyServerUrl = 'maganghub:server_url';
  static const String _keySelectedRepoIds = 'maganghub:selected_repo_ids';
  static const String _keyDraftAutoSave = 'maganghub:draft:auto';

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  Future<List<String>> getSelectedRepoIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectedRepoIds);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) return list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> setSelectedRepoIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedRepoIds, jsonEncode(ids));
  }

  Future<Map<String, dynamic>?> getAutoSavedDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDraftAutoSave);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> saveDraftLocally({
    required DraftFields draft,
    required String mode,
    String? manualNotes,
    String? combinedNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'draft': draft.toJson(),
      'mode': mode,
      'manualNotes': manualNotes ?? '',
      'combinedNotes': combinedNotes ?? '',
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_keyDraftAutoSave, jsonEncode(payload));
  }

  Future<void> clearLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftAutoSave);
  }
}
