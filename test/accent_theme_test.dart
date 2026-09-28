import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absen_maganghub/core/theme/app_accent_theme.dart';
import 'package:absen_maganghub/core/theme/ios_colors.dart';
import 'package:absen_maganghub/core/theme/ios_theme.dart';
import 'package:absen_maganghub/core/widgets/ios_button.dart';
import 'package:absen_maganghub/data/repositories/settings_repository.dart';
import 'package:absen_maganghub/data/services/api_service.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';
import 'package:absen_maganghub/data/services/local_storage_service.dart';
import 'package:absen_maganghub/data/services/standalone_storage_service.dart';
import 'package:absen_maganghub/ui/view_models/settings_view_model.dart';
import 'package:absen_maganghub/ui/views/settings/widgets/accent_theme_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accent Theme Unit & Logic Tests', () {
    late LocalStorageService localStorageService;
    late StandaloneStorageService standaloneStorageService;
    late SettingsRepository settingsRepository;
    late SettingsViewModel settingsViewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      localStorageService = LocalStorageService();
      standaloneStorageService = StandaloneStorageService(
        dbName: 'test_accent_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      settingsRepository = SettingsRepository(
        apiService: ApiService(),
        localStorageService: localStorageService,
        standaloneStorageService: standaloneStorageService,
        llmService: LlmService(),
      );
      settingsViewModel = SettingsViewModel(settingsRepository: settingsRepository);

      // Reset to emerald before each test
      IosColors.setAccentTheme(AccentColorTheme.emerald);
    });

    test('Initial default accent theme is Emerald Green', () {
      expect(IosColors.currentTheme, equals(AccentColorTheme.emerald));
      expect(IosColors.isSusanoo, isFalse);
      expect(IosColors.primary, equals(const Color(0xFF30D158)));
      expect(IosColors.statusGreen, equals(const Color(0xFF30D158)));
      expect(IosColors.onPrimary, equals(CupertinoColors.black));
    });

    test('Switching to Susanoo theme updates colors to Sasuke Susanoo Purple', () {
      IosColors.setAccentTheme(AccentColorTheme.susanoo);

      expect(IosColors.currentTheme, equals(AccentColorTheme.susanoo));
      expect(IosColors.isSusanoo, isTrue);
      expect(IosColors.primary, equals(const Color(0xFFA855F7)));
      expect(IosColors.statusGreen, equals(const Color(0xFFA855F7)));
      expect(IosColors.onPrimary, equals(CupertinoColors.white));
      expect(IosColors.primaryLight, equals(const Color(0xFFC084FC)));
      expect(IosColors.primaryDark, equals(const Color(0xFF7E22CE)));
    });

    test('IosTheme darkTheme and lightTheme reflect dynamic primaryColor', () {
      IosColors.setAccentTheme(AccentColorTheme.emerald);
      final emeraldDark = IosTheme.darkTheme();
      expect(emeraldDark.primaryColor, equals(const Color(0xFF30D158)));
      expect(emeraldDark.primaryContrastingColor, equals(CupertinoColors.black));

      IosColors.setAccentTheme(AccentColorTheme.susanoo);
      final susanooDark = IosTheme.darkTheme();
      expect(susanooDark.primaryColor, equals(const Color(0xFFA855F7)));
      expect(susanooDark.primaryContrastingColor, equals(CupertinoColors.white));
    });

    test('LocalStorageService persists and loads accent theme', () async {
      await localStorageService.setAccentTheme('susanoo');
      final loaded = await localStorageService.getAccentTheme();
      expect(loaded, equals('susanoo'));

      await localStorageService.setAccentTheme('emerald');
      final loadedEmerald = await localStorageService.getAccentTheme();
      expect(loadedEmerald, equals('emerald'));
    });

    test('SettingsViewModel toggleAccentTheme toggles between Emerald and Susanoo', () async {
      await settingsViewModel.init();
      expect(settingsViewModel.isSusanooTheme, isFalse);

      await settingsViewModel.toggleAccentTheme();
      expect(settingsViewModel.isSusanooTheme, isTrue);
      expect(IosColors.isSusanoo, isTrue);
      expect(await settingsRepository.getAccentTheme(), equals('susanoo'));

      await settingsViewModel.toggleAccentTheme();
      expect(settingsViewModel.isSusanooTheme, isFalse);
      expect(IosColors.isSusanoo, isFalse);
      expect(await settingsRepository.getAccentTheme(), equals('emerald'));
    });
  });

  group('Accent Theme UI & Widget Tests', () {
    late LocalStorageService localStorageService;
    late StandaloneStorageService standaloneStorageService;
    late SettingsRepository settingsRepository;
    late SettingsViewModel settingsViewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      localStorageService = LocalStorageService();
      standaloneStorageService = StandaloneStorageService(
        dbName: 'test_widget_accent_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      settingsRepository = SettingsRepository(
        apiService: ApiService(),
        localStorageService: localStorageService,
        standaloneStorageService: standaloneStorageService,
        llmService: LlmService(),
      );
      settingsViewModel = SettingsViewModel(settingsRepository: settingsRepository);
      await settingsViewModel.init();
      IosColors.setAccentTheme(AccentColorTheme.emerald);
    });

    testWidgets('AccentThemeSection renders title, toggle switch, and preview cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: AccentThemeSection(viewModel: settingsViewModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tema & Warna Aksen'), findsOneWidget);
      expect(find.text('Mode Susanoo Sasuke'), findsOneWidget);
      expect(find.text('CHAKRA'), findsOneWidget);
      expect(find.text('Emerald Green'), findsOneWidget);
      expect(find.text('Susanoo Purple'), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });

    testWidgets('Tapping Susanoo Purple card switches active theme to Susanoo', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ListenableBuilder(
              listenable: settingsViewModel,
              builder: (context, _) => AccentThemeSection(viewModel: settingsViewModel),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(settingsViewModel.isSusanooTheme, isFalse);

      // Tap on Susanoo card
      await tester.tap(find.text('Susanoo Purple'));
      await tester.pumpAndSettle();

      expect(settingsViewModel.isSusanooTheme, isTrue);
      expect(IosColors.isSusanoo, isTrue);
      expect(IosColors.primary, equals(const Color(0xFFA855F7)));
    });

    testWidgets('Toggling CupertinoSwitch switches between Emerald and Susanoo', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: ListenableBuilder(
              listenable: settingsViewModel,
              builder: (context, _) => AccentThemeSection(viewModel: settingsViewModel),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(CupertinoSwitch);
      expect(switchFinder, findsOneWidget);

      // Flip switch ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settingsViewModel.isSusanooTheme, isTrue);
      expect(IosColors.isSusanoo, isTrue);

      // Flip switch OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settingsViewModel.isSusanooTheme, isFalse);
      expect(IosColors.isSusanoo, isFalse);
    });

    testWidgets('IosButton primary variant adopts Susanoo Purple when active', (WidgetTester tester) async {
      IosColors.setAccentTheme(AccentColorTheme.susanoo);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: IosButton(
              text: 'Susanoo Button',
              variant: IosButtonVariant.primary,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cupertinoButton = tester.widget<CupertinoButton>(find.byType(CupertinoButton));
      expect(cupertinoButton.color, equals(const Color(0xFFA855F7)));
    });
  });
}
