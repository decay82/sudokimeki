import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyMissionId = 1001;
  static bool _initialized = false;

  static const _androidDetails = AndroidNotificationDetails(
    'daily_mission_channel',
    '데일리 미션 알림',
    channelDescription: '매일 데일리 미션 시간을 알려드립니다.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    // 플러그인 초기화 (반드시 완료)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 타임존 초기화 (실패해도 앱 멈추지 않음)
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 5));
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('>>> Timezone 초기화 실패, UTC 사용: $e');
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
    }

    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  // 매일 지정 시각에 데일리 미션 알림 예약
  static Future<void> scheduleDailyMissionNotification({
    int hour = 7,
    int minute = 45,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.zonedSchedule(
      _dailyMissionId,
      '스도키메키',
      '10년 젊어지는 1분 뇌활동 지금 도전해보세요.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 테스트용: 즉시 알림 발송
  static Future<void> sendTestNotification() async {
    if (kIsWeb || !_initialized) return;

    await _plugin.show(
      9999,
      '스도키메키 [테스트]',
      '10년 젊어지는 1분 뇌활동 지금 도전해보세요.',
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelDailyMissionNotification() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_dailyMissionId);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
