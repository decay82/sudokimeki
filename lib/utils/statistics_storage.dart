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

  GameStatistics({
    this.gamesStarted = 0,
    this.gamesWon = 0,
    this.perfectWins = 0,
    this.bestTime = 0,
    this.totalTime = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
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
      };

  factory GameStatistics.fromJson(Map<String, dynamic> json) => GameStatistics(
        gamesStarted: json['gamesStarted'] ?? 0,
        gamesWon: json['gamesWon'] ?? 0,
        perfectWins: json['perfectWins'] ?? 0,
        bestTime: json['bestTime'] ?? 0,
        totalTime: json['totalTime'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        bestStreak: json['bestStreak'] ?? 0,
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
    );

    await prefs.setString(key, jsonEncode(newStats.toJson()));
  }

  static Future<void> recordGameWin({
    required String difficulty,
    required int timeInSeconds,
    required bool isPerfect,
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

    final newStats = GameStatistics(
      gamesStarted: stats.gamesStarted,
      gamesWon: stats.gamesWon + 1,
      perfectWins: isPerfect ? stats.perfectWins + 1 : stats.perfectWins,
      bestTime: newBestTime,
      totalTime: stats.totalTime + timeInSeconds,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
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