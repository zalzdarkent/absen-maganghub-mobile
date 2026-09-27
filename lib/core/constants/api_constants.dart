import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const List<String> candidateBaseUrls = [
    'http://127.0.0.1:4174', // USB / adb reverse / Desktop
    'http://localhost:4174', // Localhost
    'http://192.168.1.13:4174', // Host Wi-Fi LAN
    'http://10.0.2.2:4174', // Android Emulator
  ];

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:4174';
    }
    try {
      if (Platform.isAndroid) {
        // 127.0.0.1 works on real devices with adb reverse and is faster than 10.0.2.2
        return 'http://127.0.0.1:4174';
      }
    } catch (_) {}
    return 'http://localhost:4174';
  }

  static const String statusEndpoint = '/api/status';
  static const String generateEndpoint = '/api/generate';
  static const String generateManualEndpoint = '/api/generate-manual';
  static const String generateCombinedEndpoint = '/api/generate-combined';
  static const String generateRecapEndpoint = '/api/generate-recap';
  static const String entriesEndpoint = '/api/entries';
  static const String exportEndpoint = '/api/entries/export';
  static const String settingsEndpoint = '/api/settings';
  static const String testLlmEndpoint = '/api/test-llm';
  static const String autoDraftEndpoint = '/api/auto-draft';
  static const String autoDraftGenerateEndpoint = '/api/auto-draft/generate';

  static const String defaultLocalLlmUrl = 'http://192.168.13.155:3000';
  static const String defaultLocalLlmModel = 'gpt-oss-20b';
  static const String defaultGeminiModel = 'gemini-3.6-flash';
}
