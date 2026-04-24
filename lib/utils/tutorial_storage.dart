import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorage {
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyTutorialDone = 'tutorial_done';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> isTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTutorialDone) ?? false;
  }

  static Future<void> setTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTutorialDone, true);
  }
}
