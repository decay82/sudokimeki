import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DayStatus {
  locked,      // 비활성화 (아직 열리지 않음)
  available,   // 활성화 (플레이 가능)
  inProgress,  // 진행중 (중간에 나간 상태)
  completed,   // 클리어
}

class DailyMissionData {
  final String date; // yyyy-MM-dd 형식
  final DayStatus status;
  final String? difficulty; // 선택한 난이도
  final int? puzzleNumber; // 플레이한 퍼즐 번호
  final List<List<int>>? savedBoard; // 진행중인 보드
  final List<List<bool>>? savedCorrectCells; // 진행중인 정답 셀
  final int? elapsedSeconds; // 경과 시간

  DailyMissionData({
    required this.date,
    required this.status,
    this.difficulty,
    this.puzzleNumber,
    this.savedBoard,
    this.savedCorrectCells,
    this.elapsedSeconds,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'status': status.toString(),
    'difficulty': difficulty,
    'puzzleNumber': puzzleNumber,
    'savedBoard': savedBoard,
    'savedCorrectCells': savedCorrectCells,
    'elapsedSeconds': elapsedSeconds,
  };

  factory DailyMissionData.fromJson(Map<String, dynamic> json) {
    return DailyMissionData(
      date: json['date'],
      status: DayStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => DayStatus.locked,
      ),
      difficulty: json['difficulty'],
      puzzleNumber: json['puzzleNumber'],
      savedBoard: json['savedBoard'] != null
          ? (json['savedBoard'] as List).map((row) => (row as List).cast<int>()).toList()
          : null,
      savedCorrectCells: json['savedCorrectCells'] != null
          ? (json['savedCorrectCells'] as List).map((row) => (row as List).cast<bool>()).toList()
          : null,
      elapsedSeconds: json['elapsedSeconds'],
    );
  }
}

class DailyMissionStorage {
  static const String _keyPrefix = 'daily_mission_';
  static const String _keyTrophies = 'daily_mission_trophies';

  // 특정 날짜의 미션 데이터 저장
  static Future<void> saveDailyMission(DailyMissionData data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${data.date}';
    await prefs.setString(key, jsonEncode(data.toJson()));
  }

  // 특정 날짜의 미션 데이터 로드
  static Future<DailyMissionData?> loadDailyMission(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$date';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return DailyMissionData.fromJson(json);
    } catch (e) {
      print('일일 미션 데이터 로드 실패: $e');
      return null;
    }
  }

  // 특정 월의 모든 미션 데이터 로드
  static Future<Map<String, DailyMissionData>> loadMonthMissions(int year, int month) async {
    final result = <String, DailyMissionData>{};

    // 해당 월의 모든 날짜 확인
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final data = await loadDailyMission(dateString);

      if (data != null) {
        result[dateString] = data;
      }
    }

    return result;
  }

  // 미션 시작 (난이도와 퍼즐 번호 저장)
  static Future<void> startMission(String date, String difficulty, int puzzleNumber) async {
    final data = DailyMissionData(
      date: date,
      status: DayStatus.inProgress,
      difficulty: difficulty,
      puzzleNumber: puzzleNumber,
    );
    await saveDailyMission(data);
  }

  // 미션 진행 상황 저장
  static Future<void> saveMissionProgress({
    required String date,
    required String difficulty,
    required int puzzleNumber,
    required List<List<int>> board,
    required List<List<bool>> correctCells,
    required int elapsedSeconds,
  }) async {
    final data = DailyMissionData(
      date: date,
      status: DayStatus.inProgress,
      difficulty: difficulty,
      puzzleNumber: puzzleNumber,
      savedBoard: board,
      savedCorrectCells: correctCells,
      elapsedSeconds: elapsedSeconds,
    );
    await saveDailyMission(data);
  }

  // 미션 완료
  static Future<void> completeMission(String date, String difficulty, int puzzleNumber, {int? elapsedSeconds}) async {
    final data = DailyMissionData(
      date: date,
      status: DayStatus.completed,
      difficulty: difficulty,
      puzzleNumber: puzzleNumber,
      elapsedSeconds: elapsedSeconds,
    );
    await saveDailyMission(data);
  }

  // 트로피 획득 여부 저장
  static Future<void> saveTrophy(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final trophies = await loadTrophies();
    final key = '$year-${month.toString().padLeft(2, '0')}';
    trophies.add(key);
    await prefs.setStringList(_keyTrophies, trophies.toList());
  }

  // 트로피 목록 로드
  static Future<Set<String>> loadTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrophies) ?? [];
    return Set<String>.from(list);
  }

  // 특정 월의 트로피 획득 여부 확인
  static Future<bool> hasTrophy(int year, int month) async {
    final trophies = await loadTrophies();
    final key = '$year-${month.toString().padLeft(2, '0')}';
    return trophies.contains(key);
  }

  // 특정 월의 모든 날짜가 완료되었는지 확인
  static Future<bool> isMonthCompleted(int year, int month) async {
    final missions = await loadMonthMissions(year, month);

    // 2025년 10월은 1일부터 시작
    final startDay = 1;

    // 항상 해당 월의 마지막 날까지 확인 (현재 월이어도 전체 일수 확인)
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = startDay; day <= daysInMonth; day++) {
      final dateString = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final data = missions[dateString];

      if (data == null || data.status != DayStatus.completed) {
        return false;
      }
    }

    return true;
  }
}
