import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/puzzle_data.dart';
import '../utils/ad_helper.dart';
import '../utils/game_storage.dart';
import '../utils/statistics_storage.dart';
import '../utils/sound_helper.dart';
import '../utils/weekly_bot_ranking.dart';
import '../utils/ranking_badge_helper.dart';
import '../utils/difficulty_unlock_storage.dart';
import '../utils/analytics_helper.dart';

enum HeartAnimationStatus { none, animating }

class SudokuGame extends ChangeNotifier {
  final List<List<List<int>>> puzzles = PuzzleData.puzzles;
  final List<List<List<int>>> solutions = PuzzleData.solutions;
  Set<String> completedLines = {};

  List<List<bool>> correctCells = [];
  int currentStage = 0;
  HeartAnimationStatus heartAnimationStatus = HeartAnimationStatus.none;

  // 동시 애니메이션 지원: 여러 애니메이션을 동시에 실행
  // Map 키: 'row_0', 'col_5', 'box_3' 등
  // Map 값: 현재 애니메이션 단계 (0-8)
  Map<String, int> activeAnimations = {};

  // 순차 실행 모드 (true: 순차, false: 동시) - 나중에 변경 가능
  bool sequentialAnimationMode = false;
  List<List<int>> board = [];
  List<List<int>> initialBoard = [];
  List<List<Set<int>>> memos = [];
  bool isMemoMode = false;
  bool isSmartInputMode = false;
  int? selectedNumber;
  Set<String> conflictingCells = {}; // "row_col" 형식으로 저장
  bool isBlinking = false;

  int? selectedRow;
  int? selectedCol;

  DateTime? startTime;
  Duration elapsedTime = Duration.zero;
  Duration pausedTime = Duration.zero;
  bool isCompleted = false;
  bool isTimerPaused = false;

  int hearts = 3;

  bool isHintMode = false;
  int hintsUsed = 0;
  int hintsAvailable = 1; // 보유 힌트 개수

  BannerAd? bannerAd;
  bool isBannerAdLoaded = false;

  Function()? onCompletionCallback;
  Function()? onGameOverCallback;

  String currentDifficulty = 'easy';

  // ========== 점수 시스템 ==========
  int totalScore = 0;  // 총 점수
  int currentCombo = 0;  // 현재 콤보 수
  DateTime? lastCorrectAnswerTime;  // 마지막 정답 시간 (콤보용)

  // 점수 표시용 데이터 (셀 위에 점수 표시)
  int? scoreDisplayRow;
  int? scoreDisplayCol;
  int? scoreDisplayValue;
  DateTime? scoreDisplayTime;

  // 난이도별 점수표
  static const Map<String, Map<String, int>> scoreTable = {
    'beginner': {'base': 10, 'line': 50, 'box': 50, 'combo': 5, 'clear': 500},
    'rookie': {'base': 20, 'line': 100, 'box': 100, 'combo': 10, 'clear': 1000},
    'easy': {'base': 20, 'line': 100, 'box': 100, 'combo': 10, 'clear': 1000},
    'medium': {'base': 30, 'line': 150, 'box': 150, 'combo': 15, 'clear': 1500},
    'hard': {'base': 50, 'line': 300, 'box': 300, 'combo': 25, 'clear': 3000},
  };

  SudokuGame() {
    loadStage(0, recordStart: false);

    if (!kIsWeb) {
      _loadBannerAd();
    }
  }

void addHeart() {
  // 하트를 3개로 충전
  hearts = 3;
  print("하트 충전: $hearts개로 복구");
  heartAnimationStatus = HeartAnimationStatus.animating;
  notifyListeners();

  // 애니메이션 시간 후 상태만 리셋
  Future.delayed(const Duration(milliseconds: 1000), () {
    heartAnimationStatus = HeartAnimationStatus.none;
    notifyListeners();
  });
}

  

  // 완료 체크 결과를 담는 클래스
  ({int bonusScore, int completedLinesCount}) _checkCompletions(int row, int col) {
    int bonusScore = 0;
    int completedLinesCount = 0;
    final scores = scoreTable[currentDifficulty] ?? scoreTable['easy']!;

    bool rowComplete = true;
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == 0 ||
          solutions[currentStage][row][i] != board[row][i]) {
        rowComplete = false;
        break;
      }
    }
    if (rowComplete && !completedLines.contains('row_$row')) {
      completedLines.add('row_$row');
      bonusScore += scores['line']!;
      completedLinesCount++;
      _animateCompletion('row', row);
    }

    bool colComplete = true;
    for (int i = 0; i < 9; i++) {
      if (board[i][col] == 0 ||
          solutions[currentStage][i][col] != board[i][col]) {
        colComplete = false;
        break;
      }
    }
    if (colComplete && !completedLines.contains('col_$col')) {
      completedLines.add('col_$col');
      bonusScore += scores['line']!;
      completedLinesCount++;
      _animateCompletion('col', col);
    }

    int boxRow = (row ~/ 3);
    int boxCol = (col ~/ 3);
    int boxIndex = boxRow * 3 + boxCol;
    bool boxComplete = true;

    for (int i = boxRow * 3; i < boxRow * 3 + 3; i++) {
      for (int j = boxCol * 3; j < boxCol * 3 + 3; j++) {
        if (board[i][j] == 0 || solutions[currentStage][i][j] != board[i][j]) {
          boxComplete = false;
          break;
        }
      }
      if (!boxComplete) break;
    }

    if (boxComplete && !completedLines.contains('box_$boxIndex')) {
      completedLines.add('box_$boxIndex');
      bonusScore += scores['box']!;
      completedLinesCount++;
      _animateCompletion('box', boxIndex);
    }

    return (bonusScore: bonusScore, completedLinesCount: completedLinesCount);
  }

  // 점수 계산 메서드
  int _calculateScore(int row, int col, {bool isHint = false}) {
    if (isHint) {
      // 힌트 사용 시 0점 + 콤보 초기화
      currentCombo = 0;
      lastCorrectAnswerTime = null;
      return 0;
    }

    final scores = scoreTable[currentDifficulty] ?? scoreTable['easy']!;
    int earnedScore = 0;

    // 1. 기본 점수
    earnedScore += scores['base']!;

    // 2. 라인/박스 보너스 (_checkCompletions에서 계산됨)
    final completionResult = _checkCompletions(row, col);
    earnedScore += completionResult.bonusScore;

    // 3. 콤보 보너스
    final now = DateTime.now();
    if (lastCorrectAnswerTime != null) {
      final timeDiff = now.difference(lastCorrectAnswerTime!);
      if (timeDiff.inSeconds <= 5) {
        // 5초 이내면 콤보 유지 및 증가
        currentCombo++;
        earnedScore += scores['combo']! * currentCombo;
      } else {
        // 5초 초과면 콤보 초기화
        currentCombo = 0;
      }
    } else {
      // 첫 정답
      currentCombo = 0;
    }

    lastCorrectAnswerTime = now;
    totalScore += earnedScore;

    // 점수 표시 데이터 설정
    if (earnedScore > 0) {
      scoreDisplayRow = row;
      scoreDisplayCol = col;
      scoreDisplayValue = earnedScore;
      scoreDisplayTime = DateTime.now();

      // 0.5초 후 점수 표시 제거
      Future.delayed(const Duration(milliseconds: 500), () {
        scoreDisplayRow = null;
        scoreDisplayCol = null;
        scoreDisplayValue = null;
        scoreDisplayTime = null;
        notifyListeners();
      });
    }

    return earnedScore;
  }

  // 클리어 보너스 적용
  void _applyClearBonus() {
    final scores = scoreTable[currentDifficulty] ?? scoreTable['easy']!;
    totalScore += scores['clear']!;
  }

  Future<void> _animateCompletion(String type, int index) async {
    final animationKey = '${type}_$index';

    if (sequentialAnimationMode) {
      // 순차 실행 모드: 이전 애니메이션이 끝날 때까지 대기
      while (activeAnimations.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }

    // 애니메이션 시작
    activeAnimations[animationKey] = 0;
    notifyListeners();

    // 0-8 단계로 애니메이션 (총 9개 셀)
    for (int step = 0; step < 9; step++) {
      activeAnimations[animationKey] = step;
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 50));
    }

    // 애니메이션 종료
    activeAnimations.remove(animationKey);
    notifyListeners();
  }

  bool isCellAnimating(int row, int col) {
    if (activeAnimations.isEmpty) return false;

    // 모든 활성 애니메이션을 확인하여 하나라도 해당 셀을 애니메이팅하면 true
    for (final entry in activeAnimations.entries) {
      final parts = entry.key.split('_');
      final type = parts[0];
      final index = int.parse(parts[1]);
      final animationStep = entry.value;

      bool isAnimating = false;

      if (type == 'row') {
        isAnimating = row == index && col <= animationStep;
      } else if (type == 'col') {
        isAnimating = col == index && row <= animationStep;
      } else if (type == 'box') {
        int boxRow = index ~/ 3;
        int boxCol = index % 3;
        int cellRow = row - (boxRow * 3);
        int cellCol = col - (boxCol * 3);

        if (cellRow >= 0 && cellRow < 3 && cellCol >= 0 && cellCol < 3) {
          int cellIndex = cellRow * 3 + cellCol;
          isAnimating = row >= boxRow * 3 &&
              row < (boxRow + 1) * 3 &&
              col >= boxCol * 3 &&
              col < (boxCol + 1) * 3 &&
              cellIndex <= animationStep;
        }
      }

      if (isAnimating) return true;
    }

    return false;
  }

  void _loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isBannerAdLoaded = false;
        },
      ),
    )..load();
  }

  void toggleHintMode() {
    print('========== toggleHintMode 호출됨 ==========');

    if (!isHintMode) {
      // 힌트가 있으면 바로 활성화
      if (hintsAvailable > 0) {
        print('보유 힌트 사용: $hintsAvailable개');
        isHintMode = true;
        notifyListeners();
      } else {
        // 힌트가 없으면 광고 시청
        print('힌트 없음. 광고 시청 필요');
        RewardedAd? ad = AdHelper.getPreloadedRewardedAd();

        if (ad != null) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('!!! 힌트 광고 표시 실패: ${error.message}');
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('힌트 광고 닫힘');
              ad.dispose();
            },
          );

          ad.show(
            onUserEarnedReward: (ad, reward) {
              print('힌트 광고 보상 획득!');
              isHintMode = true;
              notifyListeners();
            },
          );
        } else {
          print('!!! 힌트 광고 로드 실패. 힌트 모드를 바로 활성화합니다.');
          isHintMode = true;
          notifyListeners();
        }
      }
    } else {
      isHintMode = false;
      notifyListeners();
    }
  }

  void useHint(int row, int col) async {
    if (initialBoard[row][col] == 0 && currentStage < solutions.length) {
      final answer = solutions[currentStage][row][col];
      board[row][col] = answer;
      memos[row][col].clear();
      correctCells[row][col] = true;
      hintsUsed++;
      isHintMode = false;

      // 보유 힌트 개수 감소
      if (hintsAvailable > 0) {
        hintsAvailable--;
        print('힌트 사용 완료. 남은 힌트: $hintsAvailable개');
      }

      // 힌트 입력 시 관련 셀들의 메모에서 동일한 숫자 제거
      _removeMemosInRelatedCells(row, col, answer);

      // 힌트 사용 시 콤보 초기화 및 0점 처리
      _calculateScore(row, col, isHint: true);

      // Analytics: 힌트 사용 이벤트
      if (!kIsWeb) {
        await AnalyticsHelper.logHintUsed(
          difficulty: currentDifficulty,
          puzzleNumber: currentStage,
          hintsUsedTotal: hintsUsed,
        );
      }

      notifyListeners();

      if (_checkIfComplete()) {
        if (startTime != null && !isCompleted) {
          elapsedTime = DateTime.now().difference(startTime!);
          isCompleted = true;

          // 클리어 보너스 적용
          _applyClearBonus();

          // 게임 완료 시 통계 기록 (일반 게임 + 일일 미션 공통)
          await StatisticsStorage.recordGameWin(
            difficulty: currentDifficulty,
            timeInSeconds: elapsedTime.inSeconds,
            isPerfect: hintsUsed == 0 && hearts == 3,
            score: totalScore,
          );

          // 난이도별 완료 횟수 증가
          await DifficultyUnlockStorage.incrementCompleted(currentDifficulty);

          // 주간 랭킹에 점수 저장
          await WeeklyBotRanking.saveMyWeeklyScore(currentDifficulty, totalScore);

          // 랭킹 배지 활성화 (초급, 중급, 고급만)
          if (currentDifficulty == 'easy' ||
              currentDifficulty == 'medium' ||
              currentDifficulty == 'hard') {
            await RankingBadgeHelper.activateBadge();
          }

          // Analytics: 게임 완료 이벤트
          if (!kIsWeb) {
            await AnalyticsHelper.logGameComplete(
              difficulty: currentDifficulty,
              puzzleNumber: currentStage,
              elapsedSeconds: elapsedTime.inSeconds,
              hintsUsed: hintsUsed,
              hearts: hearts,
              score: totalScore,
              isPerfect: hintsUsed == 0 && hearts == 3,
              isDailyMission: false,
            );
          }

          await GameStorage.clearSavedGame();

          if (onCompletionCallback != null) {
            onCompletionCallback!();
          }
        }
      }
    }
  }

  void loadStage(int stage, {String difficulty = 'easy', bool recordStart = true}) async {
    currentStage = stage;
    currentDifficulty = difficulty;
    board = puzzles[stage].map((row) => List<int>.from(row)).toList();
    initialBoard = puzzles[stage].map((row) => List<int>.from(row)).toList();
    memos = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    correctCells = List.generate(9, (_) => List.generate(9, (_) => false));
    completedLines.clear();
    selectedRow = null;
    selectedCol = null;
    isMemoMode = false;
    startTime = DateTime.now();
    elapsedTime = Duration.zero;
    isCompleted = false;
    hearts = 3;
    hintsUsed = 0;
    hintsAvailable = 1; // 매판 시작 시 힌트 1개 지급

    // 점수 시스템 초기화
    totalScore = 0;
    currentCombo = 0;
    lastCorrectAnswerTime = null;

    if (recordStart) {
      await StatisticsStorage.recordGameStart(difficulty);

      // Analytics: 게임 시작 이벤트
      if (!kIsWeb) {
        await AnalyticsHelper.logGameStart(
          difficulty: difficulty,
          puzzleNumber: stage,
          isDailyMission: false,
        );
      }
    }

    notifyListeners();
  }

  Future<void> saveGame() async {
    if (isCompleted) {
      print('완료된 게임은 저장하지 않습니다.');
      return;
    }

    final elapsedSeconds = startTime != null
        ? DateTime.now().difference(startTime!).inSeconds
        : 0;

    await GameStorage.saveGame(
      currentStage: currentStage,
      board: board,
      initialBoard: initialBoard,
      memos: memos,
      correctCells: correctCells,
      hearts: hearts,
      hintsUsed: hintsUsed,
      elapsedSeconds: elapsedSeconds,
      completedLines: completedLines,
      hintsAvailable: hintsAvailable,
    );
  }

  Future<bool> loadSavedGame() async {
    final savedData = await GameStorage.loadGame();

    if (savedData == null) {
      return false;
    }

    currentStage = savedData['currentStage'];
    board = savedData['board'];
    initialBoard = savedData['initialBoard'];
    memos = savedData['memos'];
    correctCells = savedData['correctCells'];
    hearts = savedData['hearts'];
    hintsUsed = savedData['hintsUsed'];
    completedLines = savedData['completedLines'];
    hintsAvailable = savedData['hintsAvailable'] ?? 1;

    final elapsedSeconds = savedData['elapsedSeconds'];
    startTime = DateTime.now().subtract(Duration(seconds: elapsedSeconds));
    elapsedTime = Duration.zero;
    isCompleted = false;

    selectedRow = null;
    selectedCol = null;
    isMemoMode = false;

    notifyListeners();
    print('저장된 게임을 불러왔습니다.');
    return true;
  }

  // 일일 미션용: 저장된 진행 상황 로드
  void loadDailyMissionProgress({
    required int puzzleNumber,
    required List<List<int>> savedBoard,
    required List<List<bool>> savedCorrectCells,
    required int elapsedSeconds,
  }) {
    currentStage = puzzleNumber;
    board = savedBoard.map((row) => List<int>.from(row)).toList();
    correctCells = savedCorrectCells.map((row) => List<bool>.from(row)).toList();

    // initialBoard는 원본 퍼즐에서 가져오기
    initialBoard = puzzles[puzzleNumber].map((row) => List<int>.from(row)).toList();

    memos = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    completedLines.clear();
    selectedRow = null;
    selectedCol = null;
    isMemoMode = false;
    hearts = 3;
    hintsUsed = 0;
    hintsAvailable = 1; // 매판 시작 시 힌트 1개 지급
    isCompleted = false;

    startTime = DateTime.now().subtract(Duration(seconds: elapsedSeconds));
    elapsedTime = Duration.zero;
    isTimerPaused = false;

    notifyListeners();
  }

  void restartStage() {
    loadStage(currentStage, difficulty: currentDifficulty);
  }

  void pauseTimer() {
    if (!isTimerPaused && startTime != null) {
      pausedTime = DateTime.now().difference(startTime!);
      isTimerPaused = true;
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (isTimerPaused && startTime != null) {
      startTime = DateTime.now().subtract(pausedTime);
      isTimerPaused = false;
      notifyListeners();
    }
  }

  String getElapsedTimeString() {
    if (startTime == null) return "00:00";
    final duration = isCompleted
        ? elapsedTime
        : (isTimerPaused
            ? pausedTime
            : DateTime.now().difference(startTime!));
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void toggleMemoMode() {
    isMemoMode = !isMemoMode;
    notifyListeners();
  }

  void toggleSmartInputMode() {
    isSmartInputMode = !isSmartInputMode;
    if (!isSmartInputMode) {
      selectedNumber = null;
    } else {
      // 스마트 입력 모드를 켤 때 기존 셀 선택 해제
      selectedRow = null;
      selectedCol = null;
    }
    notifyListeners();
  }

  void selectNumber(int number) {
    if (isSmartInputMode) {
      if (selectedNumber == number) {
        selectedNumber = null;
      } else {
        selectedNumber = number;
      }
      notifyListeners();
    }
  }

  // 남은 칸 개수 계산
  int _getRemainingCount(int number) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (initialBoard[i][j] == number ||
            (correctCells[i][j] && board[i][j] == number)) {
          count++;
        }
      }
    }
    return 9 - count;
  }

  // 다음으로 자동 선택할 숫자 찾기
  int? _findNextNumberToSelect(int removedNumber) {
    // 각 숫자의 남은 칸 개수 계산
    Map<int, int> remainingCounts = {};
    for (int num = 1; num <= 9; num++) {
      int remaining = _getRemainingCount(num);
      if (remaining > 0) {
        remainingCounts[num] = remaining;
      }
    }

    if (remainingCounts.isEmpty) {
      return null; // 모든 숫자가 다 채워짐
    }

    // 가장 적게 남은 개수 찾기 (가장 많이 채워진 숫자)
    int minRemaining = remainingCounts.values.reduce((a, b) => a < b ? a : b);

    // 가장 적게 남은 숫자들 필터링
    List<int> candidates = remainingCounts.entries
        .where((entry) => entry.value == minRemaining)
        .map((entry) => entry.key)
        .toList();

    if (candidates.length == 1) {
      return candidates[0];
    }

    // 동점일 때: 제거된 숫자보다 큰 수 중 가장 가까운 수
    List<int> greaterNumbers = candidates.where((num) => num > removedNumber).toList();
    if (greaterNumbers.isNotEmpty) {
      greaterNumbers.sort();
      return greaterNumbers[0];
    }

    // 제거된 숫자보다 큰 수가 없으면 가장 작은 수
    candidates.sort();
    return candidates[0];
  }

  // 정답 입력 시 해당 행/열/박스의 메모에서 동일한 숫자 제거
  void _removeMemosInRelatedCells(int row, int col, int number) {
    // 같은 행의 모든 셀에서 메모 제거
    for (int i = 0; i < 9; i++) {
      if (memos[row][i].contains(number)) {
        memos[row][i].remove(number);
      }
    }

    // 같은 열의 모든 셀에서 메모 제거
    for (int i = 0; i < 9; i++) {
      if (memos[i][col].contains(number)) {
        memos[i][col].remove(number);
      }
    }

    // 같은 3x3 박스의 모든 셀에서 메모 제거
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (memos[i][j].contains(number)) {
          memos[i][j].remove(number);
        }
      }
    }
  }

  List<String> findConflictingCells(int row, int col, int number) {
    List<String> conflicts = [];

    // 같은 행에 해당 숫자가 있는지 확인 (정답 또는 초기 숫자만)
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == number &&
          (initialBoard[row][i] != 0 || correctCells[row][i])) {
        conflicts.add('${row}_$i');
      }
    }

    // 같은 열에 해당 숫자가 있는지 확인 (정답 또는 초기 숫자만)
    for (int i = 0; i < 9; i++) {
      if (board[i][col] == number &&
          (initialBoard[i][col] != 0 || correctCells[i][col])) {
        conflicts.add('${i}_$col');
      }
    }

    // 같은 3x3 박스에 해당 숫자가 있는지 확인 (정답 또는 초기 숫자만)
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (board[i][j] == number &&
            (initialBoard[i][j] != 0 || correctCells[i][j])) {
          conflicts.add('${i}_$j');
        }
      }
    }

    return conflicts;
  }

  bool canAddMemoNumber(int row, int col, int number) {
    // 이미 메모에 있으면 추가 안함
    if (memos[row][col].contains(number)) {
      return false;
    }

    // 충돌하는 셀이 있는지 확인
    return findConflictingCells(row, col, number).isEmpty;
  }

  Future<void> _blinkConflictingCells() async {
    for (int i = 0; i < 3; i++) {
      isBlinking = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      isBlinking = false;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    conflictingCells.clear();
    notifyListeners();
  }

  void smartInputCell(int row, int col) {
    if (!isSmartInputMode || selectedNumber == null) {
      return;
    }

    if (initialBoard[row][col] != 0 || correctCells[row][col]) {
      return;
    }

    if (isMemoMode) {
      // 메모 모드: 이미 있으면 제거, 없으면 추가
      if (memos[row][col].contains(selectedNumber!)) {
        // 이미 메모에 있으면 제거
        memos[row][col].remove(selectedNumber!);
        notifyListeners();
        saveGame();
        return;
      }

      // 충돌하는 셀 찾기
      final conflicts = findConflictingCells(row, col, selectedNumber!);

      if (conflicts.isEmpty) {
        // 충돌 없으면 메모 추가
        memos[row][col].add(selectedNumber!);
        notifyListeners();
        saveGame();
      } else {
        // 충돌 있으면 점멸 효과
        conflictingCells = conflicts.toSet();
        _blinkConflictingCells();
      }
    } else {
      // 일반 모드: 답 입력
      setNumber(selectedNumber!);
    }
  }

  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
    notifyListeners();
  }

  void setNumber(int number) async {
    if (selectedRow != null && selectedCol != null) {
      if (hearts <= 0) {
        if (onGameOverCallback != null) {
          onGameOverCallback!();
        }
        return;
      }

      if (correctCells[selectedRow!][selectedCol!]) {
        return;
      }

      if (initialBoard[selectedRow!][selectedCol!] == 0) {
        if (isMemoMode) {
          if (memos[selectedRow!][selectedCol!].contains(number)) {
            memos[selectedRow!][selectedCol!].remove(number);
          } else {
            memos[selectedRow!][selectedCol!].add(number);
          }
        } else {
          final oldValue = board[selectedRow!][selectedCol!];
          board[selectedRow!][selectedCol!] = number;
          memos[selectedRow!][selectedCol!].clear();

          if (currentStage < solutions.length &&
              number != 0 &&
              oldValue != number) {
            final correctAnswer =
                solutions[currentStage][selectedRow!][selectedCol!];
            if (number == correctAnswer) {
              correctCells[selectedRow!][selectedCol!] = true;
              SoundHelper.playCorrectSound();

              // 정답 입력 시 관련 셀들의 메모에서 동일한 숫자 제거
              _removeMemosInRelatedCells(selectedRow!, selectedCol!, number);

              // 점수 계산 및 라인 완료 체크
              final completionResult = _checkCompletions(selectedRow!, selectedCol!);

              // 기본 점수 + 라인 보너스 계산
              final scores = scoreTable[currentDifficulty] ?? scoreTable['easy']!;
              int earnedScore = scores['base']! + completionResult.bonusScore;

              // 콤보 보너스
              final now = DateTime.now();
              if (lastCorrectAnswerTime != null) {
                final timeDiff = now.difference(lastCorrectAnswerTime!);
                if (timeDiff.inSeconds <= 5) {
                  currentCombo++;
                  earnedScore += scores['combo']! * currentCombo;
                } else {
                  currentCombo = 0;
                }
              } else {
                currentCombo = 0;
              }

              lastCorrectAnswerTime = now;
              totalScore += earnedScore;

              // 점수 표시
              if (earnedScore > 0) {
                scoreDisplayRow = selectedRow;
                scoreDisplayCol = selectedCol;
                scoreDisplayValue = earnedScore;
                scoreDisplayTime = DateTime.now();

                Future.delayed(const Duration(milliseconds: 500), () {
                  scoreDisplayRow = null;
                  scoreDisplayCol = null;
                  scoreDisplayValue = null;
                  scoreDisplayTime = null;
                  notifyListeners();
                });
              }

              // 스마트 입력 모드에서 선택된 숫자가 모두 채워졌는지 확인
              if (isSmartInputMode && selectedNumber != null) {
                final remaining = _getRemainingCount(selectedNumber!);
                if (remaining == 0) {
                  final currentSelectedNumber = selectedNumber!;

                  // 라인 완료 여부에 따라 다른 딜레이 적용
                  if (completionResult.completedLinesCount > 0) {
                    // 라인 완료 애니메이션 대기 (각 라인당 450ms)
                    final animationDuration = completionResult.completedLinesCount * 450;
                    Future.delayed(Duration(milliseconds: animationDuration), () {
                      if (selectedNumber == currentSelectedNumber) {
                        final nextNumber = _findNextNumberToSelect(currentSelectedNumber);
                        selectedNumber = nextNumber;
                        notifyListeners();
                      }
                    });
                  } else {
                    // 라인 완료 없으면 0.45초 대기
                    Future.delayed(const Duration(milliseconds: 450), () {
                      if (selectedNumber == currentSelectedNumber) {
                        final nextNumber = _findNextNumberToSelect(currentSelectedNumber);
                        selectedNumber = nextNumber;
                        notifyListeners();
                      }
                    });
                  }
                }
              }
            } else {
              hearts--;
              SoundHelper.playWrongSound();

              // 오답일 때 충돌하는 셀 찾아서 점멸
              final conflicts = findConflictingCells(selectedRow!, selectedCol!, number);
              if (conflicts.isNotEmpty) {
                conflictingCells = conflicts.toSet();
                _blinkConflictingCells();
              }

              if (hearts <= 0) {
                // Analytics: 게임 오버 이벤트
                if (!kIsWeb) {
                  final elapsedSeconds = startTime != null
                      ? DateTime.now().difference(startTime!).inSeconds
                      : 0;
                  await AnalyticsHelper.logGameOver(
                    difficulty: currentDifficulty,
                    puzzleNumber: currentStage,
                    elapsedSeconds: elapsedSeconds,
                    hintsUsed: hintsUsed,
                  );
                }

                if (onGameOverCallback != null) {
                  onGameOverCallback!();
                }
              }
            }
          }
        }
        notifyListeners();

        await saveGame();

        if (!isMemoMode && _checkIfComplete()) {
          if (startTime != null && !isCompleted) {
            elapsedTime = DateTime.now().difference(startTime!);
            isCompleted = true;

            // 클리어 보너스 적용
            _applyClearBonus();

            // 게임 완료 시 통계 기록 (일반 게임 + 일일 미션 공통)
            await StatisticsStorage.recordGameWin(
              difficulty: currentDifficulty,
              timeInSeconds: elapsedTime.inSeconds,
              isPerfect: hintsUsed == 0 && hearts == 3,
              score: totalScore,
            );

            // 난이도별 완료 횟수 증가
            await DifficultyUnlockStorage.incrementCompleted(currentDifficulty);

            // 주간 랭킹에 점수 저장
            await WeeklyBotRanking.saveMyWeeklyScore(currentDifficulty, totalScore);

            // 랭킹 배지 활성화 (초급, 중급, 고급만)
            if (currentDifficulty == 'easy' ||
                currentDifficulty == 'medium' ||
                currentDifficulty == 'hard') {
              await RankingBadgeHelper.activateBadge();
            }

            // Analytics: 게임 완료 이벤트
            if (!kIsWeb) {
              await AnalyticsHelper.logGameComplete(
                difficulty: currentDifficulty,
                puzzleNumber: currentStage,
                elapsedSeconds: elapsedTime.inSeconds,
                hintsUsed: hintsUsed,
                hearts: hearts,
                score: totalScore,
                isPerfect: hintsUsed == 0 && hearts == 3,
                isDailyMission: false,
              );
            }

            await GameStorage.clearSavedGame();

            if (onCompletionCallback != null) {
              onCompletionCallback!();
            }
          }
        }
      }
    }
  }

  bool _checkIfComplete() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] == 0) return false;
        if (!isValidPlacement(i, j, board[i][j])) return false;
      }
    }
    return true;
  }

  void clearCell() {
    if (selectedRow != null && selectedCol != null) {
      if (correctCells[selectedRow!][selectedCol!]) {
        return;
      }

      if (initialBoard[selectedRow!][selectedCol!] == 0) {
        board[selectedRow!][selectedCol!] = 0;
        memos[selectedRow!][selectedCol!].clear();
        notifyListeners();

        saveGame();
      }
    }
  }

  bool isInitialCell(int row, int col) {
    return initialBoard[row][col] != 0;
  }

  bool isValidPlacement(int row, int col, int number) {
    if (number == 0) return true;

    for (int i = 0; i < 9; i++) {
      if (i != col && board[row][i] == number) {
        if (correctCells[row][i] || isInitialCell(row, i)) {
          continue;
        }
        return false;
      }
    }

    for (int i = 0; i < 9; i++) {
      if (i != row && board[i][col] == number) {
        if (correctCells[i][col] || isInitialCell(i, col)) {
          continue;
        }
        return false;
      }
    }

    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (i != row && j != col && board[i][j] == number) {
          if (correctCells[i][j] || isInitialCell(i, j)) {
            continue;
          }
          return false;
        }
      }
    }

    return true;
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }
}