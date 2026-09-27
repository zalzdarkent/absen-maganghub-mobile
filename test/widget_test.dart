import 'package:flutter_test/flutter_test.dart';
import 'package:absen_maganghub/main.dart';
import 'package:absen_maganghub/data/repositories/logbook_repository.dart';
import 'package:absen_maganghub/data/repositories/settings_repository.dart';
import 'package:absen_maganghub/data/services/api_service.dart';
import 'package:absen_maganghub/data/services/github_service.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';
import 'package:absen_maganghub/data/services/local_storage_service.dart';
import 'package:absen_maganghub/data/services/standalone_storage_service.dart';
import 'package:absen_maganghub/ui/view_models/app_state.dart';
import 'package:absen_maganghub/ui/view_models/generate_view_model.dart';
import 'package:absen_maganghub/ui/view_models/history_view_model.dart';
import 'package:absen_maganghub/ui/view_models/settings_view_model.dart';

void main() {
  testWidgets('MagangHubApp smoke test', (WidgetTester tester) async {
    final localStorageService = LocalStorageService();
    final standaloneStorageService = StandaloneStorageService();
    final githubService = GithubService();
    final llmService = LlmService();
    final apiService = ApiService();
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
      generateViewModel: generateViewModel,
      historyViewModel: historyViewModel,
      settingsViewModel: settingsViewModel,
    ));

    // Initially SplashScreen is displayed
    expect(find.text('MagangHub'), findsWidgets);

    // Pump past splash duration (2400ms) and transition (650ms)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Pengaturan'), findsWidgets);
  });
}
