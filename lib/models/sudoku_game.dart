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
  if (hearts < 3) {
    hearts++;  // 즉시 증가
    print("하트 증가: $hearts");
    heartAnimationStatus = HeartAnimationStatus.animating;
    notifyListeners();
    
    // 애니메이션 시간 후 상태만 리셋
    Future.delayed(const Duration(milliseconds: 1000), () {
      heartAnimationStatus = HeartAnimationStatus.none;
      notifyListeners();
    });
  }
}

  

  int _checkCompletions(int row, int col) {
    int bonusScore = 0;
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
      _animateCompletion('box', boxIndex);
    }

    return bonusScore;
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
    int bonusScore = _checkCompletions(row, col);
    earnedScore += bonusScore;

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

      // 힌트 사용 시 콤보 초기화 및 0점 처리
      _calculateScore(row, col, isHint: true);

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

          // 주간 랭킹에 점수 저장
          await WeeklyBotRanking.saveMyWeeklyScore(currentDifficulty, totalScore);

          // 랭킹 배지 활성화
          await RankingBadgeHelper.activateBadge();

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

    // 점수 시스템 초기화
    totalScore = 0;
    currentCombo = 0;
    lastCorrectAnswerTime = null;
    
    if (recordStart) {
      await StatisticsStorage.recordGameStart(difficulty);
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

              // 점수 계산
              final earnedScore = _calculateScore(selectedRow!, selectedCol!);
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

            // 주간 랭킹에 점수 저장
            await WeeklyBotRanking.saveMyWeeklyScore(currentDifficulty, totalScore);

            // 랭킹 배지 활성화
            await RankingBadgeHelper.activateBadge();

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