import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/logbook_entry_model.dart';

class LocalStorageService {
  static const String _keyServerUrl = 'maganghub:server_url';
  static const String _keySelectedRepoIds = 'maganghub:selected_repo_ids';
  static const String _keyDraftAutoSave = 'maganghub:draft:auto';
  static const String _keyActiveUserId = 'maganghub:active_user_id';

  Future<int?> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyActiveUserId);
  }

  Future<void> setActiveUserId(int? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_keyActiveUserId);
    } else {
      await prefs.setInt(_keyActiveUserId, id);
    }
  }

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

  String _draftKey(int? userId) =>
      userId != null ? '$_keyDraftAutoSave:$userId' : _keyDraftAutoSave;

  Future<Map<String, dynamic>?> getAutoSavedDraft({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    String? raw;
    if (userId != null) {
      raw = prefs.getString(_draftKey(userId));
    }
    raw ??= prefs.getString(_keyDraftAutoSave);
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
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'draft': draft.toJson(),
      'mode': mode,
      'manualNotes': manualNotes ?? '',
      'combinedNotes': combinedNotes ?? '',
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_draftKey(userId), jsonEncode(payload));
  }

  static const String _keyAccentTheme = 'maganghub:accent_theme';

  Future<String> getAccentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccentTheme) ?? 'emerald';
  }

  Future<void> setAccentTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccentTheme, theme);
  }

  static const String _keyDailyReminder = 'maganghub:daily_reminder_enabled';
  static const String _keyReminderHour = 'maganghub:reminder_hour';
  static const String _keyReminderMinute = 'maganghub:reminder_minute';

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminder) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, enabled);
  }

  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderHour) ?? 15;
  }

  Future<int> getReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderMinute) ?? 0;
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> clearLocalDraft({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.remove(_draftKey(userId));
    }
    await prefs.remove(_keyDraftAutoSave);
  }
}
