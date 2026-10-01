import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:absen_maganghub/domain/models/settings_model.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await handler(request);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
    );
  }
}

void main() {
  group('Cloud AI & Presets Tests (Groq, Gemini, OpenCode)', () {
    test('SettingsModel initializes with Groq defaults as recommended free cloud', () {
      const s = SettingsModel();
      expect(s.cloudProvider, 'groq');
      expect(s.cloudModel, 'llama-3.1-8b-instant');
      expect(s.cloudUrl, 'https://api.groq.com/openai/v1/chat/completions');
      expect(s.isLocalLlm, true);
      expect(s.isCloud, false);
    });

    test('SettingsModel handles backward compatibility with opencode and gemini', () {
      final json = {
        'llmProvider': 'gemini',
        'geminiApiKey': 'sk-test-12345678',
        'geminiModel': 'gemini-3.6-flash',
      };
      final s = SettingsModel.fromJson(json);
      expect(s.llmProvider, 'opencode');
      expect(s.isOpenCode, true);
      expect(s.cloudApiKey, 'sk-test-12345678');
      expect(s.hasApiKey, true);
    });

    test('LlmService.generateWithCloud calls Groq endpoint with llama-3.3-70b-versatile', () async {
      String? capturedAuth;
      String? capturedUrl;
      Map<String, dynamic>? capturedBody;

      final client = MockHttpClient((request) async {
        capturedUrl = request.url.toString();
        capturedAuth = request.headers['authorization'] ?? request.headers['Authorization'];

        if (request is http.Request) {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        }

        final mockResponse = {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': jsonEncode({
                  'aktivitas': 'Hari ini saya mengerjakan integrasi Groq Cloud AI untuk mempercepat generate logbook harian dengan latensi sangat rendah.',
                  'pembelajaran': 'Mempelajari cara kerja inferensi LPU Groq dengan model Llama-3.3-70B untuk respon cepat dan parsing JSON terstruktur.',
                  'kendala': 'Tidak ada kendala berarti hari ini, proses pemanggilan endpoint Groq berjalan dengan sangat lancar dan responsif.'
                }),
              }
            }
          ]
        };

        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = LlmService(client: client);
      const settings = SettingsModel(
        llmProvider: 'cloud',
        cloudProvider: 'groq',
        cloudApiKey: 'gsk_test123456',
        cloudModel: 'llama-3.3-70b-versatile',
      );

      final result = await service.generateDraft(
        gitLogs: 'feat: add groq cloud support',
        diffSection: '',
        settings: settings,
      );

      expect(capturedUrl, 'https://api.groq.com/openai/v1/chat/completions');
      expect(capturedAuth, 'Bearer gsk_test123456');
      expect(capturedBody?['model'], 'llama-3.3-70b-versatile');
      expect(result.aktivitas.isNotEmpty, true);
      expect(result.pembelajaran.isNotEmpty, true);
      expect(result.kendala.isNotEmpty, true);
    });

    test('LlmService.generateWithGemini calls Google AI Studio endpoint with gemini-1.5-flash', () async {
      String? capturedUrl;

      final client = MockHttpClient((request) async {
        capturedUrl = request.url.toString();
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'aktivitas': 'Mengimplementasikan perbaikan endpoint Google Gemini 1.5 Flash agar tidak terjadi error 404 pada logbook generator.',
                      'pembelajaran': 'Memahami versi model resmi Google AI Studio (gemini-1.5-flash) yang stabil dan gratis untuk pemakaian kuota standar.',
                      'kendala': 'Tidak ada kendala, request berhasil direspons sesuai dengan format JSON yang ditentukan.'
                    })
                  }
                ]
              }
            }
          ]
        };

        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = LlmService(client: client);
      const settings = SettingsModel(
        llmProvider: 'cloud',
        cloudProvider: 'gemini',
        cloudApiKey: 'AIzaSyTestKey',
        cloudModel: 'gemini-1.5-flash',
      );

      final result = await service.generateDraft(
        gitLogs: 'fix: update gemini model to 1.5-flash',
        diffSection: '',
        settings: settings,
      );

      expect(capturedUrl, contains('generativelanguage.googleapis.com'));
      expect(capturedUrl, contains('gemini-1.5-flash'));
      expect(result.aktivitas.isNotEmpty, true);
    });

    test('LlmService.testConnection successfully connects to Groq', () async {
      final client = MockHttpClient((request) async {
        expect(request.url.toString(), 'https://api.groq.com/openai/v1/chat/completions');
        expect(request.headers['Authorization'], 'Bearer gsk_test_key');

        final mockRes = {
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'pong'}
            }
          ]
        };
        return http.Response(jsonEncode(mockRes), 200);
      });

      final service = LlmService(client: client);
      const settings = SettingsModel(
        llmProvider: 'cloud',
        cloudProvider: 'groq',
        cloudApiKey: 'gsk_test_key',
        cloudModel: 'llama-3.3-70b-versatile',
      );

      final res = await service.testConnection(settings);
      expect(res['ok'], true);
      expect(res['message'], contains('Groq (llama-3.3-70b-versatile) berhasil'));
    });

    test('LlmService.testConnection handles OpenCode FreeTierError with helpful message', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'error',
            'error': {
              'type': 'FreeTierError',
              'message': "OpenCode's free tier can only be used from within OpenCode"
            }
          }),
          403,
        );
      });

      final service = LlmService(client: client);
      const settings = SettingsModel(
        llmProvider: 'cloud',
        cloudProvider: 'opencode',
        cloudApiKey: 'sk-zen-free-key',
        cloudModel: 'big-pickle',
      );

      final res = await service.testConnection(settings);
      expect(res['ok'], false);
      expect(res['message'], contains('Groq (100% gratis di console.groq.com)'));
    });

    test('LlmService.testConnection handles Groq 404 model_not_found with friendly suggestion', () async {
      final client = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'The model `llama-3.3-70b-versatile` does not exist or you do not have access to it.',
              'type': 'invalid_request_error',
              'code': 'model_not_found'
            }
          }),
          404,
        );
      });

      final service = LlmService(client: client);
      const settings = SettingsModel(
        llmProvider: 'cloud',
        cloudProvider: 'groq',
        cloudApiKey: 'gsk_test_key',
        cloudModel: 'llama-3.3-70b-versatile',
      );

      final res = await service.testConnection(settings);
      expect(res['ok'], false);
      expect(res['message'], contains('llama-3.1-8b-instant'));
      expect(res['message'], contains('tidak dapat diakses'));
    });

    test('LlmService.fetchAvailableModels returns models for Groq provider', () async {
      final client = MockHttpClient((request) async {
        expect(request.url.toString(), 'https://api.groq.com/openai/v1/models');
        expect(request.headers['Authorization'], 'Bearer gsk_test_key');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'mixtral-8x7b-32768'},
              {'id': 'whisper-large-v3'},
              {'id': 'llama-3.1-8b-instant'},
              {'id': 'llama3-70b-8192'}
            ]
          }),
          200,
        );
      });

      final service = LlmService(client: client);
      final models = await service.fetchAvailableModels(
        provider: 'groq',
        apiKey: 'gsk_test_key',
      );

      expect(models.contains('llama-3.1-8b-instant'), true);
      expect(models.contains('llama3-70b-8192'), true);
      expect(models.contains('whisper-large-v3'), false); // filtered out
      expect(models.first, 'llama-3.1-8b-instant'); // prioritized first
    });
  });
}
