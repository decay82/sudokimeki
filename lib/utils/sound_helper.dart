import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SoundHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _soundEnabledKey = 'sound_enabled';
  static bool _audioSupported = true; // Track if audio is supported

  static Future<bool> isSoundEnabled() async {
    // Disable sound on web if audio is not supported
    if (kIsWeb && !_audioSupported) return false;

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
      if (kIsWeb) _audioSupported = false;
    }
  }

  static Future<void> playWrongSound() async {
    if (!await isSoundEnabled()) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/wrong.wav'));
    } catch (e) {
      print('오답 사운드 재생 실패: $e');
      if (kIsWeb) _audioSupported = false;
    }
  }

  static Future<void> playCompleteSound() async {
    if (!await isSoundEnabled()) return;

    try {
      await _audioPlayer.play(AssetSource('sounds/complete.wav'));
    } catch (e) {
      print('완료 사운드 재생 실패: $e');
      if (kIsWeb) _audioSupported = false;
    }
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
