import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameStatistics {
  final int gamesStarted;
  final int gamesWon;
  final int perfectWins;
  final int bestTime;
  final int totalTime;
  final int currentStreak;
  final int bestStreak;

  // 점수 관련 필드
  final int todayHighScore;
  final int weekHighScore;
  final int monthHighScore;
  final int totalScore;

  // 점수 기록 시간 (리셋 확인용)
  final String? lastScoreDate; // yyyy-MM-dd 형식
  final String? lastScoreWeek; // yyyy-Www 형식 (ISO week)
  final String? lastScoreMonth; // yyyy-MM 형식

  GameStatistics({
    this.gamesStarted = 0,
    this.gamesWon = 0,
    this.perfectWins = 0,
    this.bestTime = 0,
    this.totalTime = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.todayHighScore = 0,
    this.weekHighScore = 0,
    this.monthHighScore = 0,
    this.totalScore = 0,
    this.lastScoreDate,
    this.lastScoreWeek,
    this.lastScoreMonth,
  });

  double get winRate {
    if (gamesStarted == 0) return 0.0;
    return (gamesWon / gamesStarted) * 100;
  }

  int get averageTime {
    if (gamesWon == 0) return 0;
    return totalTime ~/ gamesWon;
  }

  Map<String, dynamic> toJson() => {
        'gamesStarted': gamesStarted,
        'gamesWon': gamesWon,
        'perfectWins': perfectWins,
        'bestTime': bestTime,
        'totalTime': totalTime,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'todayHighScore': todayHighScore,
        'weekHighScore': weekHighScore,
        'monthHighScore': monthHighScore,
        'totalScore': totalScore,
        'lastScoreDate': lastScoreDate,
        'lastScoreWeek': lastScoreWeek,
        'lastScoreMonth': lastScoreMonth,
      };

  factory GameStatistics.fromJson(Map<String, dynamic> json) => GameStatistics(
        gamesStarted: json['gamesStarted'] ?? 0,
        gamesWon: json['gamesWon'] ?? 0,
        perfectWins: json['perfectWins'] ?? 0,
        bestTime: json['bestTime'] ?? 0,
        totalTime: json['totalTime'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        bestStreak: json['bestStreak'] ?? 0,
        todayHighScore: json['todayHighScore'] ?? 0,
        weekHighScore: json['weekHighScore'] ?? 0,
        monthHighScore: json['monthHighScore'] ?? 0,
        totalScore: json['totalScore'] ?? 0,
        lastScoreDate: json['lastScoreDate'],
        lastScoreWeek: json['lastScoreWeek'],
        lastScoreMonth: json['lastScoreMonth'],
      );
}

class StatisticsStorage {
  static const String _keyBeginnerStats = 'stats_beginner';
  static const String _keyRookieStats = 'stats_rookie';
  static const String _keyEasyStats = 'stats_easy';
  static const String _keyMediumStats = 'stats_medium';
  static const String _keyHardStats = 'stats_hard';

  static Future<void> recordGameStart(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(difficulty);
    final stats = await getStatistics(difficulty);

    final newStats = GameStatistics(
      gamesStarted: stats.gamesStarted + 1,
      gamesWon: stats.gamesWon,
      perfectWins: stats.perfectWins,
      bestTime: stats.bestTime,
      totalTime: stats.totalTime,
      currentStreak: stats.currentStreak,
      bestStreak: stats.bestStreak,
      // 점수 필드 유지
      todayHighScore: stats.todayHighScore,
      weekHighScore: stats.weekHighScore,
      monthHighScore: stats.monthHighScore,
      totalScore: stats.totalScore,
      lastScoreDate: stats.lastScoreDate,
      lastScoreWeek: stats.lastScoreWeek,
      lastScoreMonth: stats.lastScoreMonth,
    );

    await prefs.setString(key, jsonEncode(newStats.toJson()));
  }

  static Future<void> recordGameWin({
    required String difficulty,
    required int timeInSeconds,
    required bool isPerfect,
    int score = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(difficulty);
    final stats = await getStatistics(difficulty);

    final newStreak = stats.currentStreak + 1;
    final newBestStreak =
        newStreak > stats.bestStreak ? newStreak : stats.bestStreak;
    final newBestTime = stats.bestTime == 0
        ? timeInSeconds
        : (timeInSeconds < stats.bestTime ? timeInSeconds : stats.bestTime);

    // 현재 시간 정보
    final now = DateTime.now();
    final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // ISO 주 계산 (일요일 시작)
    final startOfYear = DateTime(now.year, 1, 1);
    final daysSinceStartOfYear = now.difference(startOfYear).inDays;
    final weekNumber = ((daysSinceStartOfYear + startOfYear.weekday) / 7).ceil();
    final currentWeek = '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';

    // 오늘 최고 점수 (날짜가 다르면 리셋)
    int newTodayHighScore = stats.todayHighScore;
    if (stats.lastScoreDate != currentDate) {
      newTodayHighScore = score;
    } else if (score > stats.todayHighScore) {
      newTodayHighScore = score;
    }

    // 이번주 최고 점수 (주가 다르면 리셋)
    int newWeekHighScore = stats.weekHighScore;
    if (stats.lastScoreWeek != currentWeek) {
      newWeekHighScore = score;
    } else if (score > stats.weekHighScore) {
      newWeekHighScore = score;
    }

    // 이번달 최고 점수 (월이 다르면 리셋)
    int newMonthHighScore = stats.monthHighScore;
    if (stats.lastScoreMonth != currentMonth) {
      newMonthHighScore = score;
    } else if (score > stats.monthHighScore) {
      newMonthHighScore = score;
    }

    // 통산 최고 점수 (역대 최고)
    int newTotalScore = stats.totalScore;
    if (score > stats.totalScore) {
      newTotalScore = score;
    }

    final newStats = GameStatistics(
      gamesStarted: stats.gamesStarted,
      gamesWon: stats.gamesWon + 1,
      perfectWins: isPerfect ? stats.perfectWins + 1 : stats.perfectWins,
      bestTime: newBestTime,
      totalTime: stats.totalTime + timeInSeconds,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      todayHighScore: newTodayHighScore,
      weekHighScore: newWeekHighScore,
      monthHighScore: newMonthHighScore,
      totalScore: newTotalScore,
      lastScoreDate: currentDate,
      lastScoreWeek: currentWeek,
      lastScoreMonth: currentMonth,
    );

    await prefs.setString(key, jsonEncode(newStats.toJson()));
  }

  static Future<void> resetStreak(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(difficulty);
    final stats = await getStatistics(difficulty);

    final newStats = GameStatistics(
      gamesStarted: stats.gamesStarted,
      gamesWon: stats.gamesWon,
      perfectWins: stats.perfectWins,
      bestTime: stats.bestTime,
      totalTime: stats.totalTime,
      currentStreak: 0,
      bestStreak: stats.bestStreak,
    );

    await prefs.setString(key, jsonEncode(newStats.toJson()));
  }

  static Future<GameStatistics> getStatistics(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(difficulty);
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return GameStatistics();
    }

    return GameStatistics.fromJson(jsonDecode(jsonString));
  }

  static Future<void> resetStatistics(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(difficulty);
    await prefs.remove(key);
  }

  static String _getKey(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return _keyBeginnerStats;
      case 'rookie':
        return _keyRookieStats;
      case 'easy':
        return _keyEasyStats;
      case 'medium':
        return _keyMediumStats;
      case 'hard':
        return _keyHardStats;
      default:
        return _keyEasyStats;
    }
  }
}