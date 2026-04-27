import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import '../models/sudoku_game.dart';
import '../utils/game_storage.dart';
import '../utils/ad_helper.dart';
import '../utils/play_counter.dart';
import '../utils/difficulty_unlock_storage.dart';
import '../l10n/app_localizations.dart';
import '../utils/tutorial_storage.dart';
import 'onboarding_screen.dart';
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
    AdHelper.preloadRewardedAd();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // 유연한 업데이트: UI 차단 없이 백그라운드 다운로드
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
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
      final currentDifficulty = savedData['currentDifficulty'] as String? ?? 'beginner';
      final elapsedSeconds = savedData['elapsedSeconds'] as int;

      final l10n = AppLocalizations.of(context)!;

      String difficultyText = l10n.difficultyUnknown;
      switch (currentDifficulty) {
        case 'beginner':
          difficultyText = l10n.difficultyBeginner;
          break;
        case 'easy':
          difficultyText = l10n.difficultyEasy;
          break;
        case 'normal':
          difficultyText = l10n.difficultyNormal;
          break;
        case 'hard':
          difficultyText = l10n.difficultyHard;
          break;
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
                      label: l10n.difficultyBeginner,
                      description: l10n.difficultyBeginnerDesc,
                      color: Colors.lightBlue,
                      difficulty: 'beginner',
                      isUnlocked: unlockStatus['beginner'] ?? true,
                      progressText: progressTexts['beginner'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyEasy,
                      description: l10n.difficultyEasyDesc,
                      color: Colors.cyan,
                      difficulty: 'easy',
                      isUnlocked: unlockStatus['easy'] ?? true,
                      progressText: progressTexts['easy'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyNormal,
                      description: l10n.difficultyNormalDesc,
                      color: Colors.green,
                      difficulty: 'normal',
                      isUnlocked: unlockStatus['normal'] ?? false,
                      progressText: progressTexts['normal'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildDifficultyButton(
                      context: context,
                      label: l10n.difficultyHard,
                      description: l10n.difficultyHardDesc,
                      color: Colors.orange,
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
      'easy':     await DifficultyUnlockStorage.isUnlocked('easy'),
      'normal':   await DifficultyUnlockStorage.isUnlocked('normal'),
      'hard':     await DifficultyUnlockStorage.isUnlocked('hard'),
    };
  }

  Future<Map<String, String>> _getAllProgressTexts(BuildContext context) async {
    return {
      'beginner': await DifficultyUnlockStorage.getUnlockProgressText(context, 'beginner'),
      'easy':     await DifficultyUnlockStorage.getUnlockProgressText(context, 'easy'),
      'normal':   await DifficultyUnlockStorage.getUnlockProgressText(context, 'normal'),
      'hard':     await DifficultyUnlockStorage.getUnlockProgressText(context, 'hard'),
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
                final nav = Navigator.of(context);
                nav.pop();

                // 첫 실행 시 온보딩으로 이동
                final onboardingDone = await TutorialStorage.isOnboardingDone();
                if (!mounted) return;
                if (!onboardingDone) {
                  nav.push(
                    MaterialPageRoute(
                      builder: (context) =>
                          OnboardingScreen(selectedDifficulty: difficulty),
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                // 플레이 횟수 증가
                await PlayCounter.incrementPlayCount();

                // 5회 이상일 때만 광고 표시
                bool shouldShowAd = await PlayCounter.shouldShowAd();

                if (shouldShowAd) {
                  RewardedAd? ad = AdHelper.getPreloadedRewardedAd();

                  if (ad != null) {
                    ad.fullScreenContentCallback = FullScreenContentCallback(
                      onAdFailedToShowFullScreenContent: (ad, error) {
                        print('!!! 리워드 광고 표시 실패: ${error.message}');
                        ad.dispose();
                        _startGameWithDifficulty(difficulty);
                      },
                      onAdDismissedFullScreenContent: (ad) {
                        print('리워드 광고 닫힘');
                        ad.dispose();
                        _startGameWithDifficulty(difficulty);
                      },
                    );
                    ad.show(onUserEarnedReward: (ad, reward) {});
                  } else {
                    print('!!! 리워드 광고 로드 실패. 바로 게임을 시작합니다.');
                    _startGameWithDifficulty(difficulty);
                  }
                } else {
                  print('플레이 횟수 5회 미만, 광고 스킵');
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

  // generator가 퍼즐을 생성하므로 stage 인덱스 불필요
  game.loadStage(0, difficulty: difficulty);

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

      // 5회 이상일 때만 광고 표시
      bool shouldShowAd = await PlayCounter.shouldShowAd();

      if (shouldShowAd) {
        RewardedAd? ad = AdHelper.getPreloadedRewardedAd();

        if (ad != null) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('!!! 리워드 광고 표시 실패: ${error.message}');
              ad.dispose();
              if (mounted) {
                setState(() => _isLoading = true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SudokuScreen()),
                );
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              print('리워드 광고 닫힘');
              ad.dispose();
              if (mounted) {
                setState(() => _isLoading = true);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SudokuScreen()),
                );
              }
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {});
        } else {
          print('!!! 리워드 광고 로드 실패. 바로 게임 화면으로 이동합니다.');
          setState(() => _isLoading = true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SudokuScreen()),
          );
        }
      } else {
        print('플레이 횟수 5회 미만, 광고 스킵');
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
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    body: Stack(
      children: [
        // 기본 흰색 배경
        Container(color: const Color(0xFFFFFCFC)),

        // 좌상단 은은한 핑크 빛
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFB3B8), Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),

        // 우측 핑크 빛
        Positioned(
          top: 260,
          right: -140,
          child: Container(
            width: 360,
            height: 360,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFD9DD), Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),

        // 실제 UI
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              const Text(
                'Sudoku',
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF4B55),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                l10n.sudokuPuzzleGame,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF777777),
                ),
              ),

              const Spacer(flex: 4),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  children: [
                    // 새로 시작 버튼
                    GestureDetector(
                      onTap: _showDifficultyDialog,
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4B55),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4B55).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.newGame,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 이어서 하기 버튼
                    GestureDetector(
                      onTap: _hasSavedGame ? () => _continueGame(context) : null,
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _hasSavedGame
                                ? const Color(0xFFFF6A73)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _hasSavedGame
                              ? l10n.continueGame(_savedGameInfo)
                              : l10n.noSavedGame,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _hasSavedGame
                                ? const Color(0xFFFF4B55)
                                : Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
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

        // 로딩 오버레이
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