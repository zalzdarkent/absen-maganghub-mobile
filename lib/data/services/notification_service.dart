import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  factory NotificationService({FlutterLocalNotificationsPlugin? plugin}) {
    if (plugin != null) {
      _instance._plugin = plugin;
    }
    return _instance;
  }

  static const int dailyReminderId = 1500;
  static const int testNotificationId = 9999;
  static const String channelId = 'maganghub_reminder_heads_up_v1';
  static const String channelName = 'Pengingat Logbook MagangHub';
  static const String channelDescription =
      'Pengingat harian jam 15:00 WIB untuk mengisi logbook dari commit Git';

  final ValueNotifier<String?> onNotificationPayload = ValueNotifier<String?>(null);

  bool get isInitialized => _isInitialized;

  /// Initialize local notification service with timezone & permissions
  Future<void> initialize({
    Function(NotificationResponse response)? onNotificationTap,
  }) async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      _configureTimezone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          onNotificationPayload.value = response.payload;
          onNotificationTap?.call(response);
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  void _configureTimezone() {
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      if (offsetHours == 7) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        return;
      } else if (offsetHours == 8) {
        tz.setLocalLocation(tz.getLocation('Asia/Makassar'));
        return;
      } else if (offsetHours == 9) {
        tz.setLocalLocation(tz.getLocation('Asia/Jayapura'));
        return;
      }

      final tzName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(tzName)) {
        tz.setLocalLocation(tz.getLocation(tzName));
        return;
      }
    } catch (_) {}

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback
    }
  }

  /// Request permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          final granted = await android.requestNotificationsPermission() ?? false;
          try {
            await android.requestExactAlarmsPermission();
          } catch (_) {}
          return granted;
        }
      } else if (Platform.isIOS) {
        final darwin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (darwin != null) {
          final granted = await darwin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      debugPrint('requestPermissions error: $e');
    }
    return true;
  }

  void _ensureTimezoneInitialized() {
    try {
      tz.initializeTimeZones();
      _configureTimezone();
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    _ensureTimezoneInitialized();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  NotificationDetails _buildNotificationDetails({
    required String title,
    required String body,
    String? icon,
  }) {
    final bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: 'MagangHub Logbook',
      htmlFormatSummaryText: false,
    );

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: icon ?? 'ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF10B981),
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        enableLights: true,
        ledColor: const Color(0xFF10B981),
        ledOnMs: 1000,
        ledOffMs: 500,
        category: AndroidNotificationCategory.reminder,
        ticker: '⏰ Waktunya Isi Logbook MagangHub!',
        styleInformation: bigTextStyle,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedule recurring daily reminder at specified hour:minute (default 15:00 WIB)
  Future<void> scheduleDailyReminder({
    int hour = 15,
    int minute = 0,
    String title = '⏰ Waktunya Isi Logbook MagangHub!',
    String body = 'Sudah jam 15:00 WIB. Yuk buat draft logbook hari ini dari commit Git kamu!',
  }) async {
    try {
      await cancelDailyReminder();

      final scheduledTime = _nextInstanceOfTime(hour, minute);
      final notificationDetails = _buildNotificationDetails(
        title: title,
        body: body,
      );

      try {
        await _plugin.zonedSchedule(
          id: dailyReminderId,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'open_generate',
        );
      } catch (e) {
        if (e.toString().contains('invalid_icon') || e.toString().contains('ic_notification')) {
          final fallbackDetails = _buildNotificationDetails(
            title: title,
            body: body,
            icon: '@mipmap/ic_launcher',
          );
          await _plugin.zonedSchedule(
            id: dailyReminderId,
            title: title,
            body: body,
            scheduledDate: scheduledTime,
            notificationDetails: fallbackDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'open_generate',
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('scheduleDailyReminder error: $e');
    }
  }

  /// Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (_) {}
  }

  /// Send immediate test notification
  Future<void> showTestNotification({
    String title = '🔔 Pengingat Logbook (Tes Berhasil!)',
    String body = 'Notifikasi MagangHub aktif! Ketuk notifikasi ini untuk langsung membuka aplikasi.',
  }) async {
    try {
      final notificationDetails = _buildNotificationDetails(
        title: title,
        body: body,
      );

      await _plugin.show(
        id: testNotificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'open_generate',
      );
    } catch (e) {
      debugPrint('showTestNotification error with ic_notification: $e');
      if (e.toString().contains('invalid_icon') || e.toString().contains('ic_notification')) {
        final fallbackDetails = _buildNotificationDetails(
          title: title,
          body: body,
          icon: '@mipmap/ic_launcher',
        );
        await _plugin.show(
          id: testNotificationId,
          title: title,
          body: body,
          notificationDetails: fallbackDetails,
          payload: 'open_generate',
        );
        return;
      }
      rethrow;
    }
  }
}
