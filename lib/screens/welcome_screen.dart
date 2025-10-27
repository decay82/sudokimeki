import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import '../models/sudoku_game.dart';
import '../utils/game_storage.dart';
import '../utils/ad_helper.dart';
import '../utils/play_counter.dart';
import '../utils/difficulty_unlock_storage.dart';
import '../utils/localization_helper.dart';
import '../l10n/app_localizations.dart';
import '../data/puzzle_data.dart';
import 'sudoku_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool showAppBar;
  final Function(int)? onNavigate;

  const WelcomeScreen({super.key, this.showAppBar = true, this.onNavigate});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hasSavedGame = false;
  String _savedGameInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    AdHelper.preloadInterstitialAd();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // 업데이트가 있으면 항상 즉시 업데이트 (강제)
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print('인앱 업데이트 확인 실패: $e');
    }
  }

 Future<void> _checkSavedGame() async {
  final hasSaved = await GameStorage.hasSavedGame();

  if (hasSaved) {
    final savedData = await GameStorage.loadGame();
    if (savedData != null) {
      final currentStage = savedData['currentStage'] as int;
      final elapsedSeconds = savedData['elapsedSeconds'] as int;

      // ✅ l10n을 여기서 먼저 가져오기
      final l10n = AppLocalizations.of(context)!;

      String difficultyText = l10n.difficultyUnknown;  // ✅ '알 수 없음' 번역
      if (currentStage < PuzzleData.difficulties.length) {
        final difficulty = PuzzleData.difficulties[currentStage];
        switch (difficulty) {
          case 'beginner':
            difficultyText = l10n.difficultyBeginner;  // ✅ difficultyText = 추가
            break;
          case 'rookie':
            difficultyText = l10n.difficultyRookie;  // ✅ difficultyText = 추가, ) 제거
            break;
          case 'easy':
            difficultyText = l10n.difficultyEasy;  // ✅ 번역 적용
            break;
          case 'medium':
            difficultyText = l10n.difficultyMedium;  // ✅ 번역 적용
            break;
          case 'hard':
            difficultyText = l10n.difficultyHard;  // ✅ 번역 적용
            break;
        }
      }

      final minutes = elapsedSeconds ~/ 60;
      final seconds = elapsedSeconds % 60;
      final timeText =
          '${minutes.toString().padLeft(3, '0')}:${seconds.toString().padLeft(2, '0')}';

      setState(() {
        _hasSavedGame = true;
        _savedGameInfo = '$difficultyText / $timeText';
      });
    } else {
      setState(() {
        _hasSavedGame = false;
      });
    }
  } else {
    setState(() {
      _hasSavedGame = false;
    });
  }
}

  void _showDifficultyDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<Map<String, bool>>(
        future: _checkAllDifficultiesUnlocked(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final unlockStatus = snapshot.data!;
          final l10n = AppLocalizations.of(context)!;  // ✅ 이미 선언하셨네요!

          return FutureBuilder<Map<String, String>>(
            future: _getAllProgressTexts(context),
            builder: (context, progressSnapshot) {
              if (!progressSnapshot.hasData) {
                return const AlertDialog(
                  content: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final progressTexts = progressSnapshot.data!;

              return AlertDialog(
                title: Text(  // ✅ const 제거 (l10n은 const가 아니므로)
                  l10n.selectDifficulty,  // ✅ '난이도 선택' → 번역 키
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyBeginner,  // ✅ '입문자' → 번역 키
                      description: l10n.difficultyBeginnerDesc,  // ✅ 설명도 번역
                      color: Colors.lightBlue,
                      difficulty: 'beginner',
                      isUnlocked: unlockStatus['beginner'] ?? true,
                      progressText: progressTexts['beginner'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyRookie,  // ✅ '초보자' → 번역 키
                      description: l10n.difficultyRookieDesc,  // ✅ 설명도 번역
                      color: Colors.cyan,
                      difficulty: 'rookie',
                      isUnlocked: unlockStatus['rookie'] ?? true,
                      progressText: progressTexts['rookie'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyEasy,  // ✅ '초급' → 번역 키
                      description: l10n.difficultyEasyDesc,  // ✅ 설명도 번역
                      color: Colors.green,
                      difficulty: 'easy',
                      isUnlocked: unlockStatus['easy'] ?? false,
                      progressText: progressTexts['easy'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyMedium,  // ✅ '중급' → 번역 키
                      description: l10n.difficultyMediumDesc,  // ✅ 설명도 번역
                      color: Colors.orange,
                      difficulty: 'medium',
                      isUnlocked: unlockStatus['medium'] ?? false,
                      progressText: progressTexts['medium'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyHard,  // ✅ '고급' → 번역 키
                      description: l10n.difficultyHardDesc,  // ✅ 설명도 번역
                      color: Colors.red,
                      difficulty: 'hard',
                      isUnlocked: unlockStatus['hard'] ?? false,
                      progressText: progressTexts['hard'] ?? '',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),  // ✅ '취소' → 번역 키, const 제거
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

  Future<Map<String, bool>> _checkAllDifficultiesUnlocked() async {
    return {
      'beginner': await DifficultyUnlockStorage.isUnlocked('beginner'),
      'rookie': await DifficultyUnlockStorage.isUnlocked('rookie'),
      'easy': await DifficultyUnlockStorage.isUnlocked('easy'),
      'medium': await DifficultyUnlockStorage.isUnlocked('medium'),
      'hard': await DifficultyUnlockStorage.isUnlocked('hard'),
    };
  }

  Future<Map<String, String>> _getAllProgressTexts(BuildContext context) async {
    return {
      'beginner': await DifficultyUnlockStorage.getUnlockProgressText(context, 'beginner'),
      'rookie': await DifficultyUnlockStorage.getUnlockProgressText(context, 'rookie'),
      'easy': await DifficultyUnlockStorage.getUnlockProgressText(context, 'easy'),
      'medium': await DifficultyUnlockStorage.getUnlockProgressText(context, 'medium'),
      'hard': await DifficultyUnlockStorage.getUnlockProgressText(context, 'hard'),
    };
  }

  Widget _buildDifficultyButton({
    required BuildContext context,
    required String label,
    required String description,
    required Color color,
    required String difficulty,
    required bool isUnlocked,
    required String progressText,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isUnlocked
            ? () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);

                // 플레이 횟수 증가
                await PlayCounter.incrementPlayCount();

                // 3회 이상일 때만 광고 표시
                bool shouldShowAd = await PlayCounter.shouldShowAd();

                if (shouldShowAd) {
                  InterstitialAd? ad = AdHelper.getPreloadedInterstitialAd();

                  if (ad != null) {
                    ad.fullScreenContentCallback = FullScreenContentCallback(
                      onAdFailedToShowFullScreenContent: (ad, error) {
                        print('!!! 전면 광고 표시 실패: ${error.message}');
                        ad.dispose();
                        _startGameWithDifficulty(difficulty);
                      },
                      onAdDismissedFullScreenContent: (ad) {
                        print('전면 광고 닫힘');
                        ad.dispose();
                        _startGameWithDifficulty(difficulty);
                      },
                    );
                    ad.show();
                  } else {
                    print('!!! 전면 광고 로드 실패. 바로 게임을 시작합니다.');
                    _startGameWithDifficulty(difficulty);
                  }
                } else {
                  print('플레이 횟수 3회 미만, 광고 스킵');
                  _startGameWithDifficulty(difficulty);
                }
              }
            : null, // Disable button if locked
        style: ElevatedButton.styleFrom(
          backgroundColor: isUnlocked ? color : Colors.grey,
          foregroundColor: isUnlocked ? Colors.white : Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isUnlocked) ...[
                  const Icon(Icons.lock, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked ? description : progressText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

 void _startGameWithDifficulty(String difficulty) async {
  final game = context.read<SudokuGame>();

  await GameStorage.clearSavedGame();

  final puzzlesOfDifficulty = <int>[];
  for (int i = 0; i < PuzzleData.difficulties.length; i++) {
    if (PuzzleData.difficulties[i] == difficulty) {
      puzzlesOfDifficulty.add(i);
    }
  }

  if (puzzlesOfDifficulty.isEmpty) {
    if (!mounted) return;
    
    // ✅ l10n 추가
    final l10n = AppLocalizations.of(context)!;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noPuzzlesForDifficulty(
          getDifficultyName(context, difficulty)  // ✅ 난이도 이름을 번역해서 전달
        )),
      ),
    );
    return;
  }

  final random = Random();
  final randomStage =
      puzzlesOfDifficulty[random.nextInt(puzzlesOfDifficulty.length)];

  game.loadStage(randomStage, difficulty: difficulty);

  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const SudokuScreen()),
  );
}

  void _continueGame(BuildContext context) async {
    final game = context.read<SudokuGame>();

    final loaded = await game.loadSavedGame();

    if (!mounted) return;

    if (loaded) {
      // 플레이 횟수 증가
      await PlayCounter.incrementPlayCount();

      // 3회 이상일 때만 광고 표시
      bool shouldShowAd = await PlayCounter.shouldShowAd();

      if (shouldShowAd) {
        InterstitialAd? ad = AdHelper.getPreloadedInterstitialAd();

        if (ad != null) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('!!! 전면 광고 표시 실패: ${error.message}');
              ad.dispose();
              if (mounted) {
                setState(() => _isLoading = true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SudokuScreen()),
                );
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              print('전면 광고 닫힘');
              ad.dispose();
              if (mounted) {
                setState(() => _isLoading = true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SudokuScreen()),
                );
              }
            },
          );
          ad.show();
        } else {
          print('!!! 전면 광고 로드 실패. 바로 게임 화면으로 이동합니다.');
          setState(() => _isLoading = true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SudokuScreen()),
          );
        }
      } else {
        print('플레이 횟수 3회 미만, 광고 스킵');
        setState(() => _isLoading = true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SudokuScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 게임이 없습니다.')),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;  // ✅ l10n 선언
  
  return Scaffold(
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B4FFF),
                Color(0xFF9D7EFF),
                Color(0xFFD4C5FF),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      const Text(
                        'Sudoku',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(  // ✅ const 제거
                        l10n.sudokuPuzzleGame,  // ✅ '스도쿠 퍼즐 게임' → 번역 키
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),

                      const Spacer(flex: 3),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _showDifficultyDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(  // ✅ const 제거
                                  l10n.newGame,  // ✅ '새로 시작' → 번역 키
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: OutlinedButton(
                                onPressed: _hasSavedGame
                                    ? () => _continueGame(context)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white38,
                                  side: BorderSide(
                                    color: _hasSavedGame
                                        ? Colors.white
                                        : Colors.white38,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  _hasSavedGame
                                      ? l10n.continueGame(_savedGameInfo)  // ✅ '이어서 하기\n...' → 번역 키
                                      : l10n.noSavedGame,  // ✅ '저장된 게임 없음' → 번역 키
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    ),
  );
}
}