import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absen_maganghub/data/services/local_storage_service.dart';
import 'package:absen_maganghub/data/services/notification_service.dart';
import 'package:absen_maganghub/data/repositories/settings_repository.dart';
import 'package:absen_maganghub/data/services/api_service.dart';
import 'package:absen_maganghub/data/services/standalone_storage_service.dart';
import 'package:absen_maganghub/data/services/llm_service.dart';
import 'package:absen_maganghub/ui/view_models/settings_view_model.dart';
import 'package:absen_maganghub/ui/views/settings/widgets/notification_reminder_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Push Notification Reminder Unit Tests', () {
    test('NotificationService singleton has expected channel and ID constants', () {
      final notifService = NotificationService();
      expect(NotificationService.dailyReminderId, 1500);
      expect(NotificationService.testNotificationId, 9999);
      expect(NotificationService.channelId, 'maganghub_reminder_heads_up_v1');
      expect(NotificationService.channelName, contains('MagangHub'));
      expect(notifService, isNotNull);
    });

    test('LocalStorageService defaults daily reminder to enabled at 15:00', () async {
      final localStorage = LocalStorageService();
      expect(await localStorage.isDailyReminderEnabled(), isTrue);
      expect(await localStorage.getReminderHour(), 15);
      expect(await localStorage.getReminderMinute(), 0);

      await localStorage.setDailyReminderEnabled(false);
      expect(await localStorage.isDailyReminderEnabled(), isFalse);

      await localStorage.setReminderTime(16, 30);
      expect(await localStorage.getReminderHour(), 16);
      expect(await localStorage.getReminderMinute(), 30);
    });

    test('SettingsViewModel loads reminder settings and toggles state correctly', () async {
      final localStorage = LocalStorageService();
      final standaloneStorage = StandaloneStorageService();
      final apiService = ApiService(baseUrl: null);
      final llmService = LlmService();

      final repo = SettingsRepository(
        apiService: apiService,
        localStorageService: localStorage,
        standaloneStorageService: standaloneStorage,
        llmService: llmService,
      );

      final viewModel = SettingsViewModel(settingsRepository: repo);
      await viewModel.init();

      expect(viewModel.isDailyReminderEnabled, isTrue);
      expect(viewModel.reminderHour, 15);
      expect(viewModel.reminderMinute, 0);

      await viewModel.toggleDailyReminder(false);
      expect(viewModel.isDailyReminderEnabled, isFalse);
      expect(await localStorage.isDailyReminderEnabled(), isFalse);

      await viewModel.toggleDailyReminder(true);
      expect(viewModel.isDailyReminderEnabled, isTrue);
      expect(await localStorage.isDailyReminderEnabled(), isTrue);
    });
  });

  group('NotificationReminderSection Widget Tests', () {
    testWidgets('renders title, 15:00 WIB description, switch, and test button', (tester) async {
      final localStorage = LocalStorageService();
      final standaloneStorage = StandaloneStorageService();
      final apiService = ApiService(baseUrl: null);
      final llmService = LlmService();

      final repo = SettingsRepository(
        apiService: apiService,
        localStorageService: localStorage,
        standaloneStorageService: standaloneStorage,
        llmService: llmService,
      );

      final viewModel = SettingsViewModel(settingsRepository: repo);
      await viewModel.init();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: NotificationReminderSection(viewModel: viewModel),
            ),
          ),
        ),
      );

      expect(find.text('Pengingat Push Logbook'), findsOneWidget);
      expect(find.text('Notifikasi setiap hari jam 15:00 WIB'), findsOneWidget);
      expect(find.text('Pengingat Aktif: Jam 15:00 WIB Setiap Hari'), findsOneWidget);
      expect(find.text('Kirim Tes Notifikasi'), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsOneWidget);

      // Verify switch is on
      final switchFinder = find.byType(CupertinoSwitch);
      final switchWidget = tester.widget<CupertinoSwitch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggling switch updates reminder status text', (tester) async {
      final localStorage = LocalStorageService();
      final standaloneStorage = StandaloneStorageService();
      final apiService = ApiService(baseUrl: null);
      final llmService = LlmService();

      final repo = SettingsRepository(
        apiService: apiService,
        localStorageService: localStorage,
        standaloneStorageService: standaloneStorage,
        llmService: llmService,
      );

      final viewModel = SettingsViewModel(settingsRepository: repo);
      await viewModel.init();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => NotificationReminderSection(viewModel: viewModel),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pengingat Aktif: Jam 15:00 WIB Setiap Hari'), findsOneWidget);

      // Tap the switch
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      expect(viewModel.isDailyReminderEnabled, isFalse);
      expect(find.text('Pengingat Sedang Nonaktif'), findsOneWidget);
    });
  });
}
