import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../domain/models/commit_model.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/recap_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/status_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String _baseUrl;
  final http.Client _client;
  void Function(String newUrl)? onBaseUrlDiscovered;
  bool _isProbing = false;

  ApiService({String? baseUrl, http.Client? client, this.onBaseUrlDiscovered})
      : _baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _baseUrl = trimmed;
  }

  bool _isNetworkFailure(dynamic e) {
    if (e is TimeoutException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection reset') ||
        msg.contains('connection timed out') ||
        msg.contains('os error: connection refused');
  }

  Future<String?> probeCandidateUrls({Duration timeout = const Duration(milliseconds: 1500)}) async {
    if (_isProbing) return null;
    _isProbing = true;
    try {
      final candidates = [
        _baseUrl,
        ...ApiConstants.candidateBaseUrls.where((u) => u != _baseUrl),
      ];

      for (final url in candidates) {
        try {
          final uri = Uri.parse('$url${ApiConstants.statusEndpoint}');
          final res = await _client.get(uri).timeout(timeout);
          if (res.statusCode == 200) {
            if (_baseUrl != url) {
              _baseUrl = url;
              onBaseUrlDiscovered?.call(url);
            }
            return url;
          }
        } catch (_) {}
      }
      return null;
    } finally {
      _isProbing = false;
    }
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final filtered = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          filtered[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: filtered);
    }
    return uri;
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? queryParams, Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (_isNetworkFailure(e)) {
        // Attempt quick auto-discovery if backend address changed
        final workingUrl = await probeCandidateUrls();
        if (workingUrl != null) {
          try {
            final retryUri = _buildUri(path, queryParams);
            final retryResponse = await _client.get(
              retryUri,
              headers: {'Accept': 'application/json'},
            ).timeout(timeout);
            return _handleResponse(retryResponse);
          } catch (_) {}
        }
        throw ApiException('Server backend tidak dapat dihubungi di $_baseUrl. Pastikan server aktif di port 4174.');
      }
      if (e is ApiException) rethrow;
      throw ApiException('Gagal terhubung ke backend: $e');
    }
  }

  Future<dynamic> _post(String path, {dynamic body, Duration timeout = const Duration(seconds: 40)}) async {
    try {
      final uri = _buildUri(path);
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (_isNetworkFailure(e)) {
        final workingUrl = await probeCandidateUrls();
        if (workingUrl != null) {
          try {
            final retryUri = _buildUri(path);
            final retryResponse = await _client.post(
              retryUri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body != null ? jsonEncode(body) : null,
            ).timeout(timeout);
            return _handleResponse(retryResponse);
          } catch (_) {}
        }
        throw ApiException('Server backend tidak dapat dihubungi di $_baseUrl. Cek port 4174.');
      }
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengirim data: $e');
    }
  }

  Future<dynamic> _put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memperbarui data: $e');
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await _client.delete(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal menghapus data: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        return response.body;
      }
    }

    String errorMsg = 'Error $status';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        errorMsg = decoded['error'] ?? decoded['message'] ?? errorMsg;
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMsg = response.body;
      }
    }
    throw ApiException(errorMsg, status);
  }

  // API Methods
  Future<StatusResponse> getStatus({List<String>? repoIds}) async {
    final query = <String, dynamic>{};
    if (repoIds != null && repoIds.isNotEmpty) {
      query['repoIds'] = repoIds.join(',');
    }
    final data = await _get(ApiConstants.statusEndpoint, queryParams: query);
    return StatusResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CommitDiffResponse> getCommitDiff(String sha) async {
    final data = await _get('/api/commits/$sha/diff');
    return CommitDiffResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> generateDraft({List<String>? repoIds}) async {
    final body = (repoIds != null && repoIds.isNotEmpty)
        ? {'repoIds': repoIds}
        : null;
    final data = await _post(ApiConstants.generateEndpoint, body: body);
    return data as Map<String, dynamic>;
  }

  Future<DraftFields> generateManualDraft(String description) async {
    final data = await _post(
      ApiConstants.generateManualEndpoint,
      body: {'description': description},
    );
    return DraftFields.fromJson((data as Map<String, dynamic>)['draft'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> generateCombinedDraft({
    required String manualNotes,
    String? gitLogs,
    String? diffSection,
    List<String>? repoIds,
  }) async {
    final payload = <String, dynamic>{
      'manualNotes': manualNotes,
      'gitLogs': ?gitLogs,
      'diffSection': ?diffSection,
      if (repoIds != null && repoIds.isNotEmpty) 'repoIds': repoIds,
    };
    final data = await _post(ApiConstants.generateCombinedEndpoint, body: payload);
    return data as Map<String, dynamic>;
  }

  Future<RecapModel> generateRecap(String period) async {
    final data = await _post(
      ApiConstants.generateRecapEndpoint,
      body: {'period': period},
    );
    final map = data as Map<String, dynamic>;
    return RecapModel.fromJson(map['recap'] as Map<String, dynamic>);
  }

  Future<List<LogbookEntry>> getEntries() async {
    final data = await _get(ApiConstants.entriesEndpoint);
    final list = (data as Map<String, dynamic>)['entries'] as List<dynamic>? ?? [];
    return list.map((e) => LogbookEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveEntry(DraftFields draft, {String? gitLogs}) async {
    final payload = {
      'aktivitas': draft.aktivitas.trim(),
      'pembelajaran': draft.pembelajaran.trim(),
      'kendala': draft.kendala.trim(),
      'gitLogs': ?gitLogs,
    };
    await _post(ApiConstants.entriesEndpoint, body: payload);
  }

  Future<void> updateEntry(int rowNumber, DraftFields draft) async {
    final payload = {
      'aktivitas': draft.aktivitas.trim(),
      'pembelajaran': draft.pembelajaran.trim(),
      'kendala': draft.kendala.trim(),
    };
    await _put('${ApiConstants.entriesEndpoint}/$rowNumber', body: payload);
  }

  Future<void> deleteEntry(int rowNumber) async {
    await _delete('${ApiConstants.entriesEndpoint}/$rowNumber');
  }

  Future<Uint8List> downloadExcelBytes() async {
    final uri = _buildUri(ApiConstants.exportEndpoint);
    final response = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException('Gagal mengunduh file Excel (Status: ${response.statusCode})');
  }

  Future<SettingsModel> getSettings() async {
    final data = await _get(ApiConstants.settingsEndpoint);
    return SettingsModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> saveSettings(Map<String, dynamic> payload) async {
    await _post(ApiConstants.settingsEndpoint, body: payload);
  }

  Future<Map<String, dynamic>> testLlm(Map<String, dynamic> payload) async {
    final data = await _post(ApiConstants.testLlmEndpoint, body: payload);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getAutoDraft({List<String>? repoIds}) async {
    final query = <String, dynamic>{};
    if (repoIds != null && repoIds.isNotEmpty) {
      query['repoIds'] = repoIds.join(',');
    }
    try {
      final data = await _get(ApiConstants.autoDraftEndpoint, queryParams: query);
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> triggerAutoDraft({List<String>? repoIds}) async {
    final body = (repoIds != null && repoIds.isNotEmpty)
        ? {'repoIds': repoIds}
        : null;
    await _post(ApiConstants.autoDraftGenerateEndpoint, body: body);
  }

  Future<void> deleteAutoDraft() async {
    try {
      await _delete(ApiConstants.autoDraftEndpoint);
    } catch (_) {}
  }
}
