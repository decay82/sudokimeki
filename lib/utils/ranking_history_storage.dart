import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ranking_history.dart';
import 'weekly_bot_ranking.dart';

class RankingHistoryStorage {
  static const String _keyHistories = 'ranking_histories';

  /// 현재 주차의 랭킹을 저장
  static Future<void> saveCurrentWeekRanking() async {
    final weekId = WeeklyBotRanking.getCurrentWeekId();
    final seasonNumber = _extractSeasonNumber(weekId);

    // 각 난이도별 내 순위 가져오기
    final easyRank = await WeeklyBotRanking.getMyCurrentRank('easy');
    final mediumRank = await WeeklyBotRanking.getMyCurrentRank('medium');
    final hardRank = await WeeklyBotRanking.getMyCurrentRank('hard');

    // 각 난이도별 내 점수 가져오기
    final easyScore = await WeeklyBotRanking.getMyWeeklyScore('easy', weekId);
    final mediumScore = await WeeklyBotRanking.getMyWeeklyScore('medium', weekId);
    final hardScore = await WeeklyBotRanking.getMyWeeklyScore('hard', weekId);

    // 기록이 있는 난이도만 저장
    final records = <String, RankingRecord?>{};

    if (easyRank != null && easyScore > 0) {
      records['easy'] = RankingRecord(rank: easyRank, score: easyScore);
    }

    if (mediumRank != null && mediumScore > 0) {
      records['medium'] = RankingRecord(rank: mediumRank, score: mediumScore);
    }

    if (hardRank != null && hardScore > 0) {
      records['hard'] = RankingRecord(rank: hardRank, score: hardScore);
    }

    // 하나라도 기록이 있으면 저장
    if (records.isNotEmpty) {
      final history = RankingHistory(
        seasonId: weekId,
        seasonNumber: seasonNumber,
        records: records,
      );

      await _addHistory(history);
    }
  }

  /// 히스토리 추가
  static Future<void> _addHistory(RankingHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final histories = await getAllHistories();

    // 같은 시즌이 있으면 덮어쓰기
    histories.removeWhere((h) => h.seasonId == history.seasonId);
    histories.add(history);

    // 최신순으로 정렬 (시즌 번호 내림차순)
    histories.sort((a, b) => b.seasonNumber.compareTo(a.seasonNumber));

    final jsonList = histories.map((h) => h.toJson()).toList();
    await prefs.setString(_keyHistories, jsonEncode(jsonList));
  }

  /// 모든 히스토리 가져오기 (최신순)
  static Future<List<RankingHistory>> getAllHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyHistories);

    if (jsonString == null) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => RankingHistory.fromJson(json)).toList();
  }

  /// 시즌 번호 추출 ("2025-W43" -> 43)
  static int _extractSeasonNumber(String weekId) {
    final parts = weekId.split('-W');
    return int.parse(parts[1]);
  }

  /// 히스토리 초기화 (테스트용)
  static Future<void> clearAllHistories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistories);
  }
}
