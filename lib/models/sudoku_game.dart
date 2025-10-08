import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/puzzle_data.dart';
import '../utils/ad_helper.dart';
import '../utils/game_storage.dart';
import '../utils/statistics_storage.dart';
import '../utils/sound_helper.dart';

enum HeartAnimationStatus { none, animating }

class SudokuGame extends ChangeNotifier {
  final List<List<List<int>>> puzzles = PuzzleData.puzzles;
  final List<List<List<int>>> solutions = PuzzleData.solutions;
  Set<String> completedLines = {};

  List<List<bool>> correctCells = [];
  int currentStage = 0;
  HeartAnimationStatus heartAnimationStatus = HeartAnimationStatus.none;

  String? currentlyAnimating;
  int animationStep = 0;
  List<List<int>> board = [];
  List<List<int>> initialBoard = [];
  List<List<Set<int>>> memos = [];
  bool isMemoMode = false;

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

  

  void _checkCompletions(int row, int col) {
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
      _animateCompletion('box', boxIndex);
    }
  }

  Future<void> _animateCompletion(String type, int index) async {
    currentlyAnimating = '${type}_$index';

    for (int step = 0; step < 9; step++) {
      animationStep = step;
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 50));
    }

    currentlyAnimating = null;
    animationStep = 0;
    notifyListeners();
  }

  bool isCellAnimating(int row, int col) {
    if (currentlyAnimating == null) return false;

    final parts = currentlyAnimating!.split('_');
    final type = parts[0];
    final index = int.parse(parts[1]);

    if (type == 'row') {
      return row == index && col <= animationStep;
    } else if (type == 'col') {
      return col == index && row <= animationStep;
    } else if (type == 'box') {
      int boxRow = index ~/ 3;
      int boxCol = index % 3;
      int cellRow = row - (boxRow * 3);
      int cellCol = col - (boxCol * 3);

      if (cellRow < 0 || cellRow >= 3 || cellCol < 0 || cellCol >= 3) {
        return false;
      }

      int cellIndex = cellRow * 3 + cellCol;
      return row >= boxRow * 3 &&
          row < (boxRow + 1) * 3 &&
          col >= boxCol * 3 &&
          col < (boxCol + 1) * 3 &&
          cellIndex <= animationStep;
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
      notifyListeners();

      if (_checkIfComplete()) {
        if (startTime != null && !isCompleted) {
          elapsedTime = DateTime.now().difference(startTime!);
          isCompleted = true;
          
          await StatisticsStorage.recordGameWin(
            difficulty: currentDifficulty,
            timeInSeconds: elapsedTime.inSeconds,
            isPerfect: hintsUsed == 0 && hearts == 3,
          );
          
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
              _checkCompletions(selectedRow!, selectedCol!);
            } else {
              hearts--;
              SoundHelper.playWrongSound();
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
            
            await StatisticsStorage.recordGameWin(
              difficulty: currentDifficulty,
              timeInSeconds: elapsedTime.inSeconds,
              isPerfect: hintsUsed == 0 && hearts == 3,
            );
            
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