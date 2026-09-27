import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/ios_theme.dart';
import 'data/repositories/logbook_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/github_service.dart';
import 'data/services/llm_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/standalone_storage_service.dart';
import 'ui/view_models/app_state.dart';
import 'ui/view_models/generate_view_model.dart';
import 'ui/view_models/history_view_model.dart';
import 'ui/view_models/settings_view_model.dart';
import 'ui/views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize Services
  final localStorageService = LocalStorageService();
  final standaloneStorageService = StandaloneStorageService();
  final githubService = GithubService();
  final llmService = LlmService();
  final savedServerUrl = await localStorageService.getServerUrl();
  final apiService = ApiService(baseUrl: savedServerUrl);
  apiService.onBaseUrlDiscovered = (newUrl) {
    localStorageService.setServerUrl(newUrl);
  };

  // Initialize Repositories
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

  // Initialize ViewModels
  final appState = AppState(settingsRepository: settingsRepository);
  final generateViewModel = GenerateViewModel(
    logbookRepository: logbookRepository,
    settingsRepository: settingsRepository,
    localStorageService: localStorageService,
  );
  final historyViewModel = HistoryViewModel(logbookRepository: logbookRepository);
  final settingsViewModel = SettingsViewModel(settingsRepository: settingsRepository);

  runApp(MagangHubApp(
    appState: appState,
    generateViewModel: generateViewModel,
    historyViewModel: historyViewModel,
    settingsViewModel: settingsViewModel,
  ));
}

class MagangHubApp extends StatelessWidget {
  final AppState appState;
  final GenerateViewModel generateViewModel;
  final HistoryViewModel historyViewModel;
  final SettingsViewModel settingsViewModel;

  const MagangHubApp({
    super.key,
    required this.appState,
    required this.generateViewModel,
    required this.historyViewModel,
    required this.settingsViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'MagangHub Logbook',
      debugShowCheckedModeBanner: false,
      theme: IosTheme.darkTheme(),
      home: SplashScreen(
        generateViewModel: generateViewModel,
        historyViewModel: historyViewModel,
        settingsViewModel: settingsViewModel,
      ),
    );
  }
}
