import 'package:shared_preferences/shared_preferences.dart';

class PlayCounter {
  static const String _playCountKey = 'play_count';

  // 앱 구동 후 첫 번째 전면 광고 노출 여부 (메모리, 재시작 시 초기화)
  static bool _hasShownFirstAd = false;

  static bool get hasShownFirstAd => _hasShownFirstAd;
  static void markFirstAdShown() => _hasShownFirstAd = true;

  // 플레이 횟수 가져오기
  static Future<int> getPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playCountKey) ?? 0;
  }

  // 플레이 횟수 증가
  static Future<void> incrementPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_playCountKey) ?? 0;
    await prefs.setInt(_playCountKey, currentCount + 1);
    print('>>> 플레이 횟수: ${currentCount + 1}');
  }

  // 5회 이상인지 확인
  static Future<bool> shouldShowAd() async {
    final count = await getPlayCount();
    return count >= 5;
  }
}
