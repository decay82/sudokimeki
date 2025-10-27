import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  // 게임 시작
  static Future<void> logGameStart({
    required String difficulty,
    required int puzzleNumber,
    bool isDailyMission = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_start',
        parameters: {
          'difficulty': difficulty,
          'puzzle_number': puzzleNumber,
          'is_daily_mission': isDailyMission,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 게임 완료
  static Future<void> logGameComplete({
    required String difficulty,
    required int puzzleNumber,
    required int elapsedSeconds,
    required int hintsUsed,
    required int hearts,
    required int score,
    bool isPerfect = false,
    bool isDailyMission = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_complete',
        parameters: {
          'difficulty': difficulty,
          'puzzle_number': puzzleNumber,
          'elapsed_seconds': elapsedSeconds,
          'hints_used': hintsUsed,
          'hearts_remaining': hearts,
          'score': score,
          'is_perfect': isPerfect,
          'is_daily_mission': isDailyMission,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 게임 오버
  static Future<void> logGameOver({
    required String difficulty,
    required int puzzleNumber,
    required int elapsedSeconds,
    required int hintsUsed,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_over',
        parameters: {
          'difficulty': difficulty,
          'puzzle_number': puzzleNumber,
          'elapsed_seconds': elapsedSeconds,
          'hints_used': hintsUsed,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 힌트 사용
  static Future<void> logHintUsed({
    required String difficulty,
    required int puzzleNumber,
    required int hintsUsedTotal,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'hint_used',
        parameters: {
          'difficulty': difficulty,
          'puzzle_number': puzzleNumber,
          'hints_used_total': hintsUsedTotal,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 광고 시청 (하트 회복)
  static Future<void> logAdWatched({
    required String adType, // 'heart_recovery', 'hint', 'interstitial'
    required bool completed,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ad_watched',
        parameters: {
          'ad_type': adType,
          'completed': completed,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 일일 미션 완료
  static Future<void> logDailyMissionComplete({
    required String date,
    required String difficulty,
    required int elapsedSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'daily_mission_complete',
        parameters: {
          'date': date,
          'difficulty': difficulty,
          'elapsed_seconds': elapsedSeconds,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 트로피 획득
  static Future<void> logTrophyEarned({
    required String monthKey, // "2025-10"
  }) async {
    try {
      await _analytics.logEvent(
        name: 'trophy_earned',
        parameters: {
          'month_key': monthKey,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 난이도 선택
  static Future<void> logDifficultySelected({
    required String difficulty,
    required bool isUnlocked,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'difficulty_selected',
        parameters: {
          'difficulty': difficulty,
          'is_unlocked': isUnlocked,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 난이도 잠금 해제
  static Future<void> logDifficultyUnlocked({
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'difficulty_unlocked',
        parameters: {
          'difficulty': difficulty,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 화면 조회
  static Future<void> logScreenView({
    required String screenName,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 랭킹 조회
  static Future<void> logRankingView({
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ranking_view',
        parameters: {
          'difficulty': difficulty,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 통계 조회
  static Future<void> logStatisticsView({
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'statistics_view',
        parameters: {
          'difficulty': difficulty,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 통계 초기화
  static Future<void> logStatisticsReset({
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'statistics_reset',
        parameters: {
          'difficulty': difficulty,
        },
      );
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 사용자 속성 설정
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }

  // 앱 오픈
  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      if (kDebugMode) print('Analytics error: $e');
    }
  }
}
