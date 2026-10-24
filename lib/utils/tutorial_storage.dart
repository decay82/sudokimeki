import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorage {
  static const String _smartInputTutorialKey = 'tutorial_smart_input_completed';
  static const String _hintTutorialKey = 'tutorial_hint_completed';

  /// 스마트 입력 튜토리얼 완료 여부 확인
  static Future<bool> isSmartInputTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_smartInputTutorialKey) ?? false;
  }

  /// 스마트 입력 튜토리얼 완료 표시
  static Future<void> markSmartInputTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smartInputTutorialKey, true);
  }

  /// 힌트 튜토리얼 완료 여부 확인
  static Future<bool> isHintTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hintTutorialKey) ?? false;
  }

  /// 힌트 튜토리얼 완료 표시
  static Future<void> markHintTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintTutorialKey, true);
  }

  /// 모든 튜토리얼 초기화 (테스트용)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_smartInputTutorialKey);
    await prefs.remove(_hintTutorialKey);
  }
}
