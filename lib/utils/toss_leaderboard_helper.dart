import 'dart:js_interop' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

// JavaScript 함수 선언
@js.JS('submitTossLeaderboardScore')
external void _submitTossLeaderboardScoreJS(
  String score,
  js.JSFunction onSuccess,
  js.JSFunction onError,
);

@js.JS('openTossLeaderboard')
external void _openTossLeaderboardJS(
  js.JSFunction onSuccess,
  js.JSFunction onError,
);

class TossLeaderboardHelper {
  static bool _sdkAvailable = true; // Track SDK availability

  /// 리더보드에 점수 제출
  /// [score] - 제출할 점수 (게임 완료 후 호출 권장)
  static Future<void> submitScore(double score) async {
    if (!kIsWeb) {
      print('[Toss Leaderboard] Web 환경이 아니므로 점수 제출 불가');
      return;
    }

    if (!_sdkAvailable) {
      print('[Toss Leaderboard] SDK를 사용할 수 없어 점수 제출 건너뜀');
      return;
    }

    try {
      print('[Toss Leaderboard] 점수 제출 시도: $score');

      _submitTossLeaderboardScoreJS(
        score.toString(),
        (() {
          print('[Toss Leaderboard] 점수 제출 성공: $score');
        }).toJS,
        ((js.JSAny? error) {
          print('[Toss Leaderboard] 점수 제출 실패: $error');
          // SDK not loaded error - mark as unavailable
          final errorStr = error.toString();
          if (errorStr.contains('SDK not loaded') || errorStr.contains('not loaded')) {
            _sdkAvailable = false;
            print('[Toss Leaderboard] SDK를 사용할 수 없음으로 표시됨');
          }
        }).toJS,
      );
    } catch (e) {
      print('[Toss Leaderboard] 점수 제출 예외: $e');
      _sdkAvailable = false;
    }
  }

  /// Toss 게임센터 리더보드 화면 열기
  /// 리더보드를 보여주고 앱이 백그라운드로 전환됨
  static Future<void> openLeaderboard() async {
    if (!kIsWeb) {
      print('[Toss Leaderboard] Web 환경이 아니므로 리더보드 열기 불가');
      return;
    }

    if (!_sdkAvailable) {
      print('[Toss Leaderboard] SDK를 사용할 수 없어 리더보드 열기 불가');
      return;
    }

    try {
      print('[Toss Leaderboard] 리더보드 열기 시도');

      _openTossLeaderboardJS(
        (() {
          print('[Toss Leaderboard] 리더보드 열기 성공');
        }).toJS,
        ((js.JSAny? error) {
          print('[Toss Leaderboard] 리더보드 열기 실패: $error');
          // SDK not loaded error - mark as unavailable
          final errorStr = error.toString();
          if (errorStr.contains('SDK not loaded') || errorStr.contains('not loaded')) {
            _sdkAvailable = false;
            print('[Toss Leaderboard] SDK를 사용할 수 없음으로 표시됨');
          }
        }).toJS,
      );
    } catch (e) {
      print('[Toss Leaderboard] 리더보드 열기 예외: $e');
      _sdkAvailable = false;
    }
  }

  /// 리더보드 사용 가능 여부 확인 (Web 환경이고 SDK가 로드됨)
  static bool isAvailable() {
    return kIsWeb && _sdkAvailable;
  }
}
