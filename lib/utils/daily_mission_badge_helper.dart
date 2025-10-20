import 'package:shared_preferences/shared_preferences.dart';

class DailyMissionBadgeHelper {
  static const String _lastCheckDateKey = 'daily_mission_last_check_date';

  /// 오늘 일일 미션 배지를 확인했는지 체크
  static Future<bool> shouldShowBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDate = prefs.getString(_lastCheckDateKey);
    final today = _getTodayString();

    // 마지막 확인 날짜가 오늘이 아니면 배지 표시
    return lastCheckDate != today;
  }

  /// 일일 미션 화면 진입 시 배지 비활성화 (오늘 날짜 저장)
  static Future<void> deactivateBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    await prefs.setString(_lastCheckDateKey, today);
  }

  /// 오늘 날짜 문자열 반환 (YYYY-MM-DD)
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
