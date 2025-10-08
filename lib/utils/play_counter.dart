import 'package:shared_preferences/shared_preferences.dart';

class PlayCounter {
  static const String _playCountKey = 'play_count';

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

  // 3회 이상인지 확인
  static Future<bool> shouldShowAd() async {
    final count = await getPlayCount();
    return count >= 3;
  }
}
