import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/recap_model.dart';
import '../../domain/models/settings_model.dart';

class LlmService {
  final http.Client _client;

  LlmService({http.Client? client}) : _client = client ?? http.Client();

  String _formatTodayIndonesian() {
    try {
      final now = DateTime.now();
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    } catch (_) {
      return DateTime.now().toIso8601String().split('T').first;
    }
  }

  String buildPrompt(String gitLogs, [String diffSection = '']) {
    final today = _formatTodayIndonesian();
    final diffBlock = diffSection.trim().isNotEmpty
        ? '\nDETAIL DIFF (file yang diubah + patch ringkas — ini bukti paling akurat, jangan diabaikan):\n${diffSection.length > 9000 ? diffSection.substring(0, 9000) : diffSection}\n'
        : '';

    return '''Kamu adalah asisten penulisan logbook magang IT harian untuk platform MagangHub Kemnaker.

KONTEKS:
- Hari: $today
- Peran penulis: mahasiswa magang IT (fullstack / backend / frontend — sesuaikan dari commit + diff)
- Tujuan: laporan harian yang terlihat dikerjakan manusia, natural, tidak seperti template AI.

DATA COMMIT HARI INI:
$gitLogs
$diffBlock
TUGAS:
Berdasarkan commit + diff di atas, buat 3 paragraf untuk logbook. Balas HANYA JSON valid tanpa markdown, tanpa penjelasan tambahan:

{
  "aktivitas": "paragraf 150-600 karakter, ceritakan apa yang dikerjakan hari ini berdasarkan commit & diff. Sebutkan file/fitur/bug yang relevan secara natural. Urutkan kronologis.",
  "pembelajaran": "paragraf 150-600 karakter, insight/skill baru dari pengerjaan di atas. Kaitkan dengan konsep teknis yang terlihat di diff pakai bahasa ringan.",
  "kendala": "paragraf 120-500 karakter, kendala yang mungkin muncul dari jenis pekerjaan di atas + solusi singkat. Jika commit terlihat lancar, tulis 'Tidak ada kendala berarti hari ini' lalu tambahkan antisipasi."
}

ATURAN GAYA BAHASA (WAJIB):
- Bahasa Indonesia santai, mengalir, humanis seperti anak magang ngetik sendiri. Tetap sopan & profesional.
- HINDARI bahasa skripsi/kaku: "Bahwasanya", "Adapun", "Telah dilaksanakan".
- Tiap field MINIMAL 100 karakter, MAKSIMAL 5000 karakter. Ideal 2-4 kalimat per field.
- Output harus JSON valid yang bisa di-parse.''';
  }

  String buildManualPrompt(String description) {
    final today = _formatTodayIndonesian();
    return '''Kamu adalah asisten penulisan logbook magang IT harian untuk MagangHub Kemnaker.

KONTEKS:
- Hari: $today
- Penulis: mahasiswa magang IT

DESKRIPSI BEBAS DARI USER (sumber utama, jangan mengarang di luar ini):
"""
$description
"""

TUGAS:
Susun ringkasan logbook dari deskripsi di atas. Balas HANYA JSON valid tanpa markdown:

{
  "aktivitas": "paragraf 150-600 karakter, rangkum aktivitas dari deskripsi dengan bahasa mengalir.",
  "pembelajaran": "paragraf 150-600 karakter, ekstrak pembelajaran / insight dari deskripsi.",
  "kendala": "paragraf 120-500 karakter. Jika ada kendala jelaskan + solusi, jika tidak tulis 'Tidak ada kendala berarti hari ini...'."
}

ATURAN:
- Bahasa Indonesia santai, humanis, seperti anak magang, tetap sopan.
- Tiap field 100-5000 karakter.
- JSON valid saja.''';
  }

  String buildCombinedPrompt(String gitLogs, String manualNotes, [String diffSection = '']) {
    final today = _formatTodayIndonesian();
    final diffBlock = diffSection.trim().isNotEmpty
        ? '\nDETAIL DIFF:\n${diffSection.length > 7000 ? diffSection.substring(0, 7000) : diffSection}\n'
        : '';

    return '''Kamu adalah asisten penulisan logbook magang IT harian untuk MagangHub Kemnaker. Tugasmu MENGGABUNGKAN dua sumber agar hasilnya lebih akurat & lengkap.

KONTEKS:
- Hari: $today
- Penulis: mahasiswa magang IT
- Mode: GABUNGAN (commit Git + diff + catatan manual user)

SUMBER 1 — COMMIT GIT HARI INI:
${gitLogs.isNotEmpty ? gitLogs : '(tidak ada commit hari ini)'}
$diffBlock
SUMBER 2 — CATATAN MANUAL USER:
"""
$manualNotes
"""

TUGAS:
Buat 3 paragraf logbook yang MENYATUKAN kedua sumber di atas menjadi satu narasi koheren. Balas HANYA JSON valid tanpa markdown:

{
  "aktivitas": "paragraf 150-600 karakter, rangkum apa yang dikerjakan hari ini dengan menyatukan commit dan catatan manual.",
  "pembelajaran": "paragraf 150-600 karakter, insight teknis atau soft skill yang diperoleh.",
  "kendala": "paragraf 120-500 karakter, kendala yang dihadapi dan solusinya."
}

ATURAN:
- Bahasa Indonesia santai, mengalir, humanis.
- Tiap field minimal 100 karakter.
- JSON valid saja.''';
  }

  String buildRecapPrompt(List<LogbookEntry> entries, String period) {
    final isWeekly = period == 'weekly';
    final label = isWeekly ? 'MINGGUAN (7 hari terakhir)' : 'BULANAN';
    final today = _formatTodayIndonesian();

    final blocks = entries.map((e) {
      final act = e.aktivitas.replaceAll('\n', ' ');
      final lrn = e.pembelajaran.replaceAll('\n', ' ');
      final obs = e.kendala.replaceAll('\n', ' ');
      return '[${e.tanggal}] Aktivitas: $act | Pembelajaran: $lrn | Kendala: $obs';
    }).join('\n');

    final rentang = entries.isNotEmpty
        ? '${entries.first.tanggal} — ${entries.last.tanggal}'
        : '-';

    return '''Kamu adalah asisten penulisan laporan magang untuk MagangHub Kemnaker.
KONTEKS:
- Hari ini: $today
- Periode rekap: $label
- Rentang: $rentang
- Total entri: ${entries.length}

DATA LOGBOOK PER HARI:
$blocks

TUGAS:
Buat rekap ${isWeekly ? 'mingguan' : 'bulanan'} dari data di atas. Balas HANYA JSON valid tanpa markdown:

{
  "ringkasan": "paragraf 300-700 karakter, rangkum progres utama periode ini.",
  "highlights": ["3-5 bullet highlight poin paling penting"],
  "kendalaTeratasi": "paragraf 80-300 karakter rangkum kendala + solusi.",
  "saran": "1 kalimat 30-120 karakter saran untuk periode depan.",
  "totalHari": ${entries.length},
  "rentang": "$rentang"
}''';
  }

  Map<String, dynamic> extractJsonObject(String rawText) {
    var text = rawText.replaceAll('\uFEFF', '').trim();

    // Check code blocks
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false).firstMatch(text);
    if (codeBlockMatch != null) {
      text = codeBlockMatch.group(1)!.trim();
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    // Find JSON substring by brackets
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      final candidate = text.substring(firstBrace, lastBrace + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    throw Exception('Model AI tidak menghasilkan format JSON yang valid. Silakan coba lagi.');
  }

  DraftFields _ensureCompliance(Map<String, dynamic> parsed) {
    String act = (parsed['aktivitas'] as String?)?.trim() ?? '';
    String lrn = (parsed['pembelajaran'] as String?)?.trim() ?? '';
    String obs = (parsed['kendala'] as String?)?.trim() ?? '';

    if (act.length < 100 && act.isNotEmpty) {
      act += ' Aktivitas hari ini terlaksana dengan baik dan mencapai target harian yang direncanakan.';
    }
    if (lrn.length < 100 && lrn.isNotEmpty) {
      lrn += ' Proses ini memberikan pemahaman yang lebih mendalam mengenai alur kerja dan implementasi sistem.';
    }
    if (obs.length < 100 && obs.isNotEmpty) {
      obs += ' Koordinasi dan diskusi yang baik membantu mengatasi hambatan minor yang muncul selama pengerjaan.';
    }

    return DraftFields(aktivitas: act, pembelajaran: lrn, kendala: obs);
  }

  Future<DraftFields> generateWithLocalLlm(String prompt, {required SettingsModel settings}) async {
    var rawUrl = settings.localLlmUrl.trim();
    if (rawUrl.isEmpty) rawUrl = 'http://192.168.13.155:3000';
    if (rawUrl.endsWith('/')) rawUrl = rawUrl.substring(0, rawUrl.length - 1);

    final model = settings.localLlmModel.trim().isNotEmpty ? settings.localLlmModel : 'gpt-oss-20b';
    final apiKey = settings.localLlmApiKey.trim();

    // Try standard endpoint (/v1/chat/completions and /chat/completions)
    final endpoints = [
      '$rawUrl/chat/completions',
      '$rawUrl/v1/chat/completions',
    ];

    Exception? lastErr;
    for (final ep in endpoints) {
      try {
        final uri = Uri.parse(ep);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (apiKey.isNotEmpty && apiKey != 'none') {
          headers['Authorization'] = 'Bearer $apiKey';
        }

        final body = jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'Kamu adalah asisten penulisan logbook magang IT harian yang menghasilkan respon dalam format JSON valid saja.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        });

        final res = await _client.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 60));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final content = data['choices']?[0]?['message']?['content'] as String? ?? '';
          if (content.isNotEmpty) {
            final jsonMap = extractJsonObject(content);
            return _ensureCompliance(jsonMap);
          }
        } else {
          lastErr = Exception('Local LLM error (HTTP ${res.statusCode}): ${res.body}');
        }
      } catch (e) {
        lastErr = Exception('Tidak dapat terhubung ke Local LLM di $ep: $e');
      }
    }

    throw lastErr ?? Exception('Gagal menghubungi Local LLM.');
  }

  Future<DraftFields> generateWithGemini(String prompt, {required SettingsModel settings}) async {
    final apiKey = settings.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception('API Key Google Gemini belum diisi. Masukkan di tab Pengaturan atau gunakan Local LLM.');
    }

    final model = settings.geminiModel.trim().isNotEmpty ? settings.geminiModel : 'gemini-3.6-flash';
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      }
    });

    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 40));

    if (res.statusCode != 200) {
      throw Exception('Gemini API error (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
    final jsonMap = extractJsonObject(text);
    return _ensureCompliance(jsonMap);
  }

  Future<DraftFields> generateDraft({
    required String gitLogs,
    required String diffSection,
    required SettingsModel settings,
  }) async {
    final prompt = buildPrompt(gitLogs, diffSection);
    if (settings.llmProvider == 'gemini') {
      return generateWithGemini(prompt, settings: settings);
    } else {
      return generateWithLocalLlm(prompt, settings: settings);
    }
  }

  Future<DraftFields> generateManualDraft({
    required String description,
    required SettingsModel settings,
  }) async {
    final prompt = buildManualPrompt(description);
    if (settings.llmProvider == 'gemini') {
      return generateWithGemini(prompt, settings: settings);
    } else {
      return generateWithLocalLlm(prompt, settings: settings);
    }
  }

  Future<DraftFields> generateCombinedDraft({
    required String gitLogs,
    required String manualNotes,
    required String diffSection,
    required SettingsModel settings,
  }) async {
    final prompt = buildCombinedPrompt(gitLogs, manualNotes, diffSection);
    if (settings.llmProvider == 'gemini') {
      return generateWithGemini(prompt, settings: settings);
    } else {
      return generateWithLocalLlm(prompt, settings: settings);
    }
  }

  Future<RecapModel> generateRecap({
    required List<LogbookEntry> entries,
    required String period,
    required SettingsModel settings,
  }) async {
    final prompt = buildRecapPrompt(entries, period);
    Map<String, dynamic> raw;

    if (settings.llmProvider == 'gemini') {
      final apiKey = settings.geminiApiKey.trim();
      if (apiKey.isEmpty) {
        throw Exception('API Key Google Gemini belum diisi di Pengaturan.');
      }
      final model = settings.geminiModel.trim().isNotEmpty ? settings.geminiModel : 'gemini-3.6-flash';
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      ).timeout(const Duration(seconds: 45));

      final data = jsonDecode(res.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
      raw = extractJsonObject(text);
    } else {
      var rawUrl = settings.localLlmUrl.trim();
      if (rawUrl.isEmpty) rawUrl = 'http://192.168.13.155:3000';
      if (rawUrl.endsWith('/')) rawUrl = rawUrl.substring(0, rawUrl.length - 1);
      final ep = '$rawUrl/chat/completions';
      final res = await _client.post(
        Uri.parse(ep),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': settings.localLlmModel.isNotEmpty ? settings.localLlmModel : 'gpt-oss-20b',
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 60));

      final data = jsonDecode(res.body);
      final text = data['choices']?[0]?['message']?['content'] as String? ?? '';
      raw = extractJsonObject(text);
    }

    return RecapModel.fromJson(raw);
  }

  Future<Map<String, dynamic>> testConnection(SettingsModel settings) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (settings.llmProvider == 'gemini') {
        final apiKey = settings.geminiApiKey.trim();
        if (apiKey.isEmpty) {
          return {'ok': false, 'message': 'API Key Gemini belum diisi.'};
        }
        final model = settings.geminiModel.isNotEmpty ? settings.geminiModel : 'gemini-3.6-flash';
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
        final res = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{'parts': [{'text': 'halo'}]}],
          }),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        if (res.statusCode == 200) {
          return {'ok': true, 'latencyMs': stopwatch.elapsedMilliseconds, 'message': 'Koneksi Gemini Cloud berhasil!'};
        } else {
          return {'ok': false, 'message': 'HTTP ${res.statusCode}: ${res.body}'};
        }
      } else {
        var rawUrl = settings.localLlmUrl.trim();
        if (rawUrl.isEmpty) rawUrl = 'http://192.168.13.155:3000';
        if (rawUrl.endsWith('/')) rawUrl = rawUrl.substring(0, rawUrl.length - 1);

        final uri = Uri.parse('$rawUrl/chat/completions');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (settings.localLlmApiKey.isNotEmpty && settings.localLlmApiKey != 'none') {
          headers['Authorization'] = 'Bearer ${settings.localLlmApiKey}';
        }

        final res = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode({
            'model': settings.localLlmModel.isNotEmpty ? settings.localLlmModel : 'gpt-oss-20b',
            'messages': [{'role': 'user', 'content': 'ping'}],
            'max_tokens': 5,
          }),
        ).timeout(const Duration(seconds: 8));

        stopwatch.stop();
        if (res.statusCode == 200) {
          return {
            'ok': true,
            'latencyMs': stopwatch.elapsedMilliseconds,
            'message': 'Koneksi ke Local LLM PT (${settings.localLlmModel}) berhasil!',
          };
        } else {
          return {'ok': false, 'message': 'Local LLM error (HTTP ${res.statusCode})'};
        }
      }
    } catch (e) {
      stopwatch.stop();
      return {'ok': false, 'message': e.toString()};
    }
  }
}
