import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:absen_maganghub/main.dart';
import 'package:absen_maganghub/data/repositories/auth_repository.dart';
import 'package:absen_maganghub/data/repositories/logbook_repository.dart';
import 'package:absen_maganghub/data/repositories/settings_repository.dart';
import 'package:absen_maganghub/data/services/api_service.dart';
import 'package:absen_maganghub/data/services/github_service.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';
import 'package:absen_maganghub/data/services/local_storage_service.dart';
import 'package:absen_maganghub/data/services/standalone_storage_service.dart';
import 'package:absen_maganghub/ui/view_models/app_state.dart';
import 'package:absen_maganghub/ui/view_models/auth_view_model.dart';
import 'package:absen_maganghub/ui/view_models/generate_view_model.dart';
import 'package:absen_maganghub/ui/view_models/history_view_model.dart';
import 'package:absen_maganghub/ui/view_models/settings_view_model.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      if (Platform.isLinux) {
        try {
          open.overrideFor(OperatingSystem.linux, () {
            try {
              return DynamicLibrary.open('libsqlite3.so');
            } catch (_) {
              return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
            }
          });
        } catch (_) {}
      }
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
    }
  });

  testWidgets('MagangHubApp smoke test navigates to AuthScreen when not logged in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorageService = LocalStorageService();

    await localStorageService.setActiveUserId(null);

    final standaloneStorageService = StandaloneStorageService(
      dbName: 'test_widget_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final githubService = GithubService();
    final llmService = LlmService();
    final apiService = ApiService();
    final authRepository = AuthRepository(
      sqliteDatabaseService: standaloneStorageService.sqlite,
      localStorageService: localStorageService,
      standaloneStorageService: standaloneStorageService,
    );
    final settingsRepository = SettingsRepository(
      apiService: apiService,
      localStorageService: localStorageService,
      standaloneStorageService: standaloneStorageService,
      llmService: llmService,
    );
    final logbookRepository = LogbookRepository(
      apiService: apiService,
      githubService: githubService,
      llmService: llmService,
      standaloneStorageService: standaloneStorageService,
      settingsRepository: settingsRepository,
    );

    final authViewModel = AuthViewModel(authRepository: authRepository);
    final appState = AppState(settingsRepository: settingsRepository);
    final generateViewModel = GenerateViewModel(
      logbookRepository: logbookRepository,
      settingsRepository: settingsRepository,
      localStorageService: localStorageService,
    );
    final historyViewModel = HistoryViewModel(logbookRepository: logbookRepository);
    final settingsViewModel = SettingsViewModel(settingsRepository: settingsRepository);

    await tester.pumpWidget(MagangHubApp(
      appState: appState,
      authViewModel: authViewModel,
      generateViewModel: generateViewModel,
      historyViewModel: historyViewModel,
      settingsViewModel: settingsViewModel,
    ));

    // Initially SplashScreen is displayed
    expect(find.text('MagangHub'), findsWidgets);

    // Pump past splash duration (2400ms) and transition (650ms)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    // When not logged in, AuthScreen is displayed
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Daftar Akun'), findsWidgets);
  });
}
