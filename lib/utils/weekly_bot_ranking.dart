import 'package:shared_preferences/shared_preferences.dart';
import '../models/ranking_entry.dart';
import 'bot_name_generator.dart';
import 'weekly_score_limits.dart';

class WeeklyBotRanking {
  static const int botCount = 50;

  /// 현재 주차 ID 가져오기 (예: "2025-W03")
  static String getCurrentWeekId() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysSinceStartOfYear = now.difference(startOfYear).inDays;
    final weekNumber = ((daysSinceStartOfYear + startOfYear.weekday) / 7).ceil();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// 주차 시작일 계산 (이번 주 월요일 00:00)
  static DateTime getWeekStartDate(String weekId) {
    // 현재 시간 기준으로 이번 주 월요일을 계산
    final now = DateTime.now();

    // 월요일 = 1, 일요일 = 7
    final currentWeekday = now.weekday;

    // 이번 주 월요일까지의 일수 계산
    final daysUntilMonday = currentWeekday - 1;

    // 이번 주 월요일 00:00:00
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysUntilMonday));

    return monday;
  }

  /// 주간 랭킹 생성 (봇 + 유저)
  static Future<List<RankingEntry>> generateWeeklyRanking(String difficulty) async {
    final weekId = getCurrentWeekId();
    final weekStart = getWeekStartDate(weekId);

    // 1. 봇 랭킹 생성 (실제 주차 시작일 기준)
    List<RankingEntry> bots = _generateBots(difficulty, weekId, weekStart);

    // 2. 내 점수 가져오기
    final myScore = await _getMyWeeklyScore(difficulty, weekId);

    // 3. 내 점수를 랭킹에 삽입
    if (myScore > 0) {
      bots.add(RankingEntry(
        rank: 0,
        name: '나',
        score: myScore,
        isBot: false,
        isMe: true,
      ));
    }

    // 4. 점수 순으로 정렬
    bots.sort((a, b) => b.score.compareTo(a.score));

    // 5. 순위 재계산
    for (int i = 0; i < bots.length; i++) {
      bots[i] = bots[i].copyWith(rank: i + 1);
    }

    return bots;
  }

  /// 봇 생성
  static List<RankingEntry> _generateBots(
    String difficulty,
    String weekId,
    DateTime weekStart,
  ) {
    // 난이도별로 다른 시드 생성 (난이도 문자열을 시드에 포함)
    final baseSeed = '$weekId-$difficulty'.hashCode;
    List<RankingEntry> bots = [];

    for (int i = 0; i < botCount; i++) {
      // 주차별로 고정된 봇 이름 (난이도별로 다른 이름 풀 사용)
      final botName = BotNameGenerator.generateName(
        seed: baseSeed + i,
        difficulty: difficulty,
      );

      // 주차 진행도에 따른 현재 점수
      final currentScore = WeeklyScoreLimits.getBotCurrentScore(
        i,
        difficulty,
        weekStart,
      );

      bots.add(RankingEntry(
        rank: i + 1,
        name: botName,
        score: currentScore,
        isBot: true,
        isMe: false,
      ));
    }

    return bots;
  }

  /// 내 주간 점수 가져오기 (private)
  static Future<int> _getMyWeeklyScore(String difficulty, String weekId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'weekly_score_${difficulty}_$weekId';
    return prefs.getInt(key) ?? 0;
  }

  /// 내 주간 점수 가져오기 (public, 외부 접근용)
  static Future<int> getMyWeeklyScore(String difficulty, String weekId) async {
    return await _getMyWeeklyScore(difficulty, weekId);
  }

  /// 내 주간 점수 저장
  static Future<void> saveMyWeeklyScore(String difficulty, int scoreToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final weekId = getCurrentWeekId();
    final key = 'weekly_score_${difficulty}_$weekId';

    final currentScore = await _getMyWeeklyScore(difficulty, weekId);
    final newScore = currentScore + scoreToAdd;

    await prefs.setInt(key, newScore);
  }

  /// 내 현재 순위 가져오기
  static Future<int?> getMyCurrentRank(String difficulty) async {
    final ranking = await generateWeeklyRanking(difficulty);
    final myEntry = ranking.firstWhere(
      (entry) => entry.isMe,
      orElse: () => RankingEntry(rank: 0, name: '', score: 0),
    );

    return myEntry.rank > 0 ? myEntry.rank : null;
  }

  /// 주간 리셋 확인 (필요시 이전 주차 데이터 삭제)
  static Future<void> checkAndResetWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final currentWeekId = getCurrentWeekId();
    final savedWeekId = prefs.getString('current_week_id');

    if (savedWeekId != null && savedWeekId != currentWeekId) {
      // 새 주차 시작 - 이전 주차 랭킹을 히스토리에 저장
      // ranking_history_storage에서 import 순환 참조를 피하기 위해 여기서 직접 호출하지 않음
      // 대신 ranking_screen에서 호출
    }

    await prefs.setString('current_week_id', currentWeekId);
  }
}
