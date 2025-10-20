import 'package:shared_preferences/shared_preferences.dart';

class RankingBadgeHelper {
  static const String _key = 'show_ranking_badge';

  /// 랭킹 배지 표시 여부 설정
  static Future<void> setShowBadge(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, show);
  }

  /// 랭킹 배지 표시 여부 가져오기
  static Future<bool> shouldShowBadge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// 게임 클리어 시 배지 활성화
  static Future<void> activateBadge() async {
    await setShowBadge(true);
  }

  /// 랭킹 화면 진입 시 배지 비활성화
  static Future<void> deactivateBadge() async {
    await setShowBadge(false);
  }
}
