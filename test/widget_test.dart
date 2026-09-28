import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:absen_maganghub/core/widgets/ios_button.dart';
import 'package:absen_maganghub/main.dart';
import 'package:absen_maganghub/domain/models/user_model.dart';
import 'package:absen_maganghub/data/repositories/auth_repository.dart';
import 'package:absen_maganghub/data/repositories/logbook_repository.dart';
import 'package:absen_maganghub/data/repositories/settings_repository.dart';
import 'package:absen_maganghub/data/services/api_service.dart';
import 'package:absen_maganghub/data/services/github_service.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';
import 'package:absen_maganghub/data/services/local_storage_service.dart';
import 'package:absen_maganghub/data/services/sqlite_database_service.dart';
import 'package:absen_maganghub/data/services/standalone_storage_service.dart';
import 'package:absen_maganghub/ui/view_models/app_state.dart';
import 'package:absen_maganghub/ui/view_models/auth_view_model.dart';
import 'package:absen_maganghub/ui/view_models/generate_view_model.dart';
import 'package:absen_maganghub/ui/view_models/history_view_model.dart';
import 'package:absen_maganghub/ui/view_models/settings_view_model.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  final SqliteDatabaseService sqliteDatabaseService;
  @override
  final LocalStorageService localStorageService;
  @override
  final StandaloneStorageService standaloneStorageService;

  UserModel? _currentUser;

  FakeAuthRepository({
    required this.sqliteDatabaseService,
    required this.localStorageService,
    required this.standaloneStorageService,
    UserModel? initialUser,
  }) : _currentUser = initialUser;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<UserModel?> checkSession() async => _currentUser;

  @override
  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _currentUser = UserModel(
      id: 1,
      username: usernameOrEmail,
      email: '$usernameOrEmail@example.com',
      name: 'User $usernameOrEmail',
      createdAt: DateTime.now().toIso8601String(),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    _currentUser = UserModel(
      id: 2,
      username: username,
      email: email,
      name: name ?? username,
      createdAt: DateTime.now().toIso8601String(),
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}

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

    // Now on AuthScreen
    expect(find.byType(IosButton), findsWidgets);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Daftar Akun'), findsWidgets);
  });

  testWidgets('AuthScreen register flow displays iOS loading effect and navigates directly to MainNavigationScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorageService = LocalStorageService();
    final standaloneStorageService = StandaloneStorageService(
      dbName: 'test_register_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final githubService = GithubService();
    final llmService = LlmService();
    final apiService = ApiService();
    final authRepository = FakeAuthRepository(
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

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MagangHubApp(
      appState: appState,
      authViewModel: authViewModel,
      generateViewModel: generateViewModel,
      historyViewModel: historyViewModel,
      settingsViewModel: settingsViewModel,
    ));

    // Wait past splash
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    // Switch to Register tab
    await tester.tap(find.text('Daftar Akun'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Fill form using exact keys
    await tester.enterText(find.byKey(const Key('auth_input_name')), 'Test User');
    await tester.enterText(find.byKey(const Key('auth_input_email')), 'testuser@example.com');
    await tester.enterText(find.byKey(const Key('auth_input_username')), 'testuser');
    await tester.enterText(find.byKey(const Key('auth_input_password')), 'secret123');
    await tester.enterText(find.byKey(const Key('auth_input_confirm_password')), 'secret123');
    await tester.pump();

    // Tap submit button
    await tester.tap(find.byKey(const Key('auth_btn_submit')));
    await tester.pump();

    // Should immediately show iOS loading indicator and loading text
    expect(find.byType(CupertinoActivityIndicator), findsWidgets);
    expect(find.text('Sedang Mendaftar...'), findsOneWidget);

    // 1. Advance past the minimum 650ms loading duration
    await tester.pump(const Duration(milliseconds: 700));

    // 2. Advance past toast delay (250ms)
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Advance past page route transition (650ms)
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    // Directly in MainNavigationScreen (Generate tab, Riwayat tab, Pengaturan tab)
    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Pengaturan'), findsWidgets);

    // Let toast 3s auto-dismiss timer finish
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('AuthScreen login flow displays iOS loading effect and navigates directly to MainNavigationScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorageService = LocalStorageService();
    final standaloneStorageService = StandaloneStorageService(
      dbName: 'test_login_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final githubService = GithubService();
    final llmService = LlmService();
    final apiService = ApiService();
    final authRepository = FakeAuthRepository(
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

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MagangHubApp(
      appState: appState,
      authViewModel: authViewModel,
      generateViewModel: generateViewModel,
      historyViewModel: historyViewModel,
      settingsViewModel: settingsViewModel,
    ));

    // Wait past splash
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    // On Login tab
    await tester.enterText(find.byKey(const Key('auth_input_username')), 'johndoe');
    await tester.enterText(find.byKey(const Key('auth_input_password')), 'password123');
    await tester.pump();

    // Tap Masuk button
    await tester.tap(find.byKey(const Key('auth_btn_submit')));
    await tester.pump();

    // Should immediately show iOS loading indicator and loading text
    expect(find.byType(CupertinoActivityIndicator), findsWidgets);
    expect(find.text('Sedang Masuk...'), findsOneWidget);

    // 1. Advance past 650ms loading duration
    await tester.pump(const Duration(milliseconds: 700));

    // 2. Advance past toast delay (250ms)
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Advance past page route transition (650ms)
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    // Directly in MainNavigationScreen (Generate tab, Riwayat tab, Pengaturan tab)
    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Pengaturan'), findsWidgets);

    // Let toast 3s auto-dismiss timer finish
    await tester.pump(const Duration(seconds: 4));
  });
}
