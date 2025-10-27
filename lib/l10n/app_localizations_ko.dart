// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get difficultyBeginner => '입문자';

  @override
  String get difficultyRookie => '초보자';

  @override
  String get difficultyEasy => '초급';

  @override
  String get difficultyMedium => '중급';

  @override
  String get difficultyHard => '고급';

  @override
  String get difficultyUnknown => '알 수 없음';

  @override
  String get difficultyBeginnerDesc => 'Beginner - 처음 시작하는 난이도';

  @override
  String get difficultyRookieDesc => 'Rookie - 연습하기 좋은 난이도';

  @override
  String get difficultyEasyDesc => 'Easy - 쉬운 난이도';

  @override
  String get difficultyMediumDesc => 'Medium - 보통 난이도';

  @override
  String get difficultyHardDesc => 'Hard - 어려운 난이도';

  @override
  String get selectDifficulty => '난이도 선택';

  @override
  String get cancel => '취소';

  @override
  String get sudokuPuzzleGame => '스도쿠 퍼즐 게임';

  @override
  String get newGame => '새로 시작';

  @override
  String continueGame(String info) {
    return '이어서 하기\n$info';
  }

  @override
  String get noSavedGame => '저장된 게임 없음';

  @override
  String get noSavedGameAvailable => '저장된 게임이 없습니다.';

  @override
  String noPuzzlesForDifficulty(String difficulty) {
    return '$difficulty 난이도의 퍼즐이 없습니다.';
  }

  @override
  String get statistics => '통계';

  @override
  String get games => '게임';

  @override
  String get gamesStarted => '시작한 게임';

  @override
  String get gamesWon => '승리한 게임';

  @override
  String get winRate => '승률';

  @override
  String get perfectWins => '실수 없이 승리';

  @override
  String get highScore => '최고 점수';

  @override
  String get today => '오늘';

  @override
  String get thisWeek => '이번주';

  @override
  String get thisMonth => '이번달';

  @override
  String get allTime => '통산';

  @override
  String get time => '시간';

  @override
  String get bestTime => '최고 시간';

  @override
  String get averageTime => '평균 시간';

  @override
  String get winStreak => '연승';

  @override
  String get currentStreak => '현재 연승';

  @override
  String get bestStreak => '최고 연승';

  @override
  String get resetStatistics => '통계 초기화';

  @override
  String get confirmResetStatistics => '통계를 초기화 하시겠습니까?';

  @override
  String difficultyDataWillBeReset(String difficulty) {
    return '$difficulty 데이터가 초기화 됩니다.';
  }

  @override
  String statisticsReset(String difficulty) {
    return '$difficulty 통계가 초기화되었습니다.';
  }

  @override
  String get reset => '재설정';

  @override
  String get dailyMission => '일일 미션';

  @override
  String get completedMission => '완료된 미션';

  @override
  String get difficulty => '난이도';

  @override
  String get clearTime => '클리어 시간';

  @override
  String get play => '플레이';

  @override
  String yearMonth(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get completed => '완료';

  @override
  String get clearAllMissions => '모든 미션을 클리어하세요';

  @override
  String get sunday => '일';

  @override
  String get monday => '월';

  @override
  String get tuesday => '화';

  @override
  String get wednesday => '수';

  @override
  String get thursday => '목';

  @override
  String get friday => '금';

  @override
  String get saturday => '토';

  @override
  String get ranking => '랭킹';

  @override
  String get rankingHistory => '랭킹 히스토리';

  @override
  String get noRankingData => '랭킹 데이터가 없습니다.';

  @override
  String get initializing => '초기화 중...';

  @override
  String timeRemaining(int days, String hours, String minutes, String seconds) {
    return '$days일 $hours:$minutes:$seconds';
  }

  @override
  String get history => '히스토리';

  @override
  String get noRankingHistory => '랭킹 히스토리가 없습니다.';

  @override
  String season(int number) {
    return '$number시즌';
  }

  @override
  String rankNumber(int rank) {
    return '$rank위';
  }

  @override
  String get smartOn => '스마트\nON';

  @override
  String get smart => '스마트';

  @override
  String get memoOn => '메모\nON';

  @override
  String get memo => '메모';

  @override
  String get delete => '삭제';

  @override
  String get hintOn => '힌트\nON';

  @override
  String hintPlus(int count) {
    return '힌트\n+$count';
  }

  @override
  String get hint => '힌트';

  @override
  String get completedGamesNotSaved => '완료된 게임은 저장하지 않습니다.';

  @override
  String get savedGameLoaded => '저장된 게임을 불러왔습니다.';

  @override
  String difficultyProgress(String previousName, int completed, int required) {
    return '$previousName $completed/$required번 완료';
  }

  @override
  String get me => '나';

  @override
  String get options => '옵션';

  @override
  String get soundEffects => '효과음';

  @override
  String get close => '닫기';

  @override
  String get gameOver => '게임 오버';

  @override
  String get watchAdToGetHeart => '광고를 끝까지 시청해야 하트를 받을 수 있습니다.';

  @override
  String get adWatchHeartRecharge => '광고 시청 후 하트 3개 충전';

  @override
  String get restart => '다시 시작';

  @override
  String get home => '홈';

  @override
  String get totalScore => '총 점수';

  @override
  String record(String time) {
    return '기록: $time';
  }

  @override
  String get nextStage => '다음 스테이지';

  @override
  String get unknown => '알 수 없음';

  @override
  String get trophyCollection => '트로피 콜렉션';

  @override
  String get noDailyMissionsYet => '아직 일일 미션이 없습니다';

  @override
  String get inProgress => '진행 중';

  @override
  String get confirm => '확인';

  @override
  String get gameOverMessage => '3회 실수하면 게임이 종료됩니다.';
}
