import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _soundEnabledKey = 'sound_enabled';

  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  static Future<void> playCorrectSound() async {
    if (!await isSoundEnabled()) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/correct.wav'));
    } catch (e) {
      print('정답 사운드 재생 실패: $e');
    }
  }

  static Future<void> playWrongSound() async {
    if (!await isSoundEnabled()) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/wrong.wav'));
    } catch (e) {
      print('오답 사운드 재생 실패: $e');
    }
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
