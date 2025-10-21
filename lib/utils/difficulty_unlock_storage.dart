import 'package:shared_preferences/shared_preferences.dart';

class DifficultyUnlockStorage {
  // 난이도별 완료 횟수 키
  static const String _keyBeginnerCompleted = 'difficulty_beginner_completed';
  static const String _keyRookieCompleted = 'difficulty_rookie_completed';
  static const String _keyEasyCompleted = 'difficulty_easy_completed';
  static const String _keyMediumCompleted = 'difficulty_medium_completed';
  static const String _keyHardCompleted = 'difficulty_hard_completed';

  // 난이도별 잠금 해제 조건
  static const Map<String, Map<String, dynamic>> unlockRequirements = {
    'beginner': {'required': 0, 'previousDifficulty': null},
    'rookie': {'required': 0, 'previousDifficulty': null},
    'easy': {'required': 2, 'previousDifficulty': 'rookie'},
    'medium': {'required': 4, 'previousDifficulty': 'easy'},
    'hard': {'required': 10, 'previousDifficulty': 'medium'},
  };

  // 난이도별 설명
  static const Map<String, String> difficultyDescriptions = {
    'beginner': 'Beginner - 처음 시작하는 난이도',
    'rookie': 'Rookie - 연습하기 좋은 난이도',
  };

  // 난이도별 완료 횟수 증가
  static Future<void> incrementCompleted(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForDifficulty(difficulty);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
    print('$difficulty 완료 횟수 증가: ${current + 1}');
  }

  // 난이도별 완료 횟수 조회
  static Future<int> getCompleted(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForDifficulty(difficulty);
    return prefs.getInt(key) ?? 0;
  }

  // 난이도 잠금 해제 여부 확인
  static Future<bool> isUnlocked(String difficulty) async {
    final requirement = unlockRequirements[difficulty];
    if (requirement == null) return false;

    // 필요 횟수가 0이면 항상 해제
    if (requirement['required'] == 0) return true;

    // 이전 난이도 완료 횟수 확인
    final previousDifficulty = requirement['previousDifficulty'] as String?;
    if (previousDifficulty == null) return true;

    final completed = await getCompleted(previousDifficulty);
    final required = requirement['required'] as int;

    return completed >= required;
  }

  // 난이도별 잠금 해제 진행률 문자열
  static Future<String> getUnlockProgressText(String difficulty) async {
    final requirement = unlockRequirements[difficulty];
    if (requirement == null) return '';

    // 이미 해제된 경우 설명 반환
    if (await isUnlocked(difficulty)) {
      return difficultyDescriptions[difficulty] ?? '';
    }

    // 잠금 상태: 진행률 표시
    final previousDifficulty = requirement['previousDifficulty'] as String?;
    if (previousDifficulty == null) return '';

    final completed = await getCompleted(previousDifficulty);
    final required = requirement['required'] as int;

    final previousName = _getDifficultyKoreanName(previousDifficulty);
    return '$previousName $completed/$required번 완료';
  }

  // 난이도 한글 이름
  static String _getDifficultyKoreanName(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return '입문자';
      case 'rookie':
        return '초보자';
      case 'easy':
        return '초급';
      case 'medium':
        return '중급';
      case 'hard':
        return '고급';
      default:
        return '';
    }
  }

  // 난이도별 저장 키 반환
  static String _getKeyForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return _keyBeginnerCompleted;
      case 'rookie':
        return _keyRookieCompleted;
      case 'easy':
        return _keyEasyCompleted;
      case 'medium':
        return _keyMediumCompleted;
      case 'hard':
        return _keyHardCompleted;
      default:
        return '';
    }
  }

  // 디버그: 모든 완료 횟수 출력
  static Future<void> printAllProgress() async {
    print('=== 난이도별 완료 횟수 ===');
    for (var difficulty in ['beginner', 'rookie', 'easy', 'medium', 'hard']) {
      final completed = await getCompleted(difficulty);
      final unlocked = await isUnlocked(difficulty);
      print('$difficulty: $completed번 완료, 잠금해제: $unlocked');
    }
  }

  // 테스트용: 모든 데이터 초기화
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBeginnerCompleted);
    await prefs.remove(_keyRookieCompleted);
    await prefs.remove(_keyEasyCompleted);
    await prefs.remove(_keyMediumCompleted);
    await prefs.remove(_keyHardCompleted);
    print('모든 난이도 진행률 초기화됨');
  }
}
