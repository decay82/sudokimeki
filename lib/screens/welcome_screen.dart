import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import '../models/sudoku_game.dart';
import '../utils/game_storage.dart';
import '../utils/ad_helper.dart';
import '../utils/play_counter.dart';
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
        final availableVersionCode = updateInfo.availableVersionCode ?? 0;

        // 1.1.5+15 이상 버전이 Play Store에 나오면 즉시 업데이트 (강제)
        // 현재 버전: 1.1.4+14
        // 다음 버전: 1.1.5+15 → 즉시 업데이트 실행
        if (availableVersionCode >= 15) {
          await InAppUpdate.performImmediateUpdate();
        }
        // 15 미만 버전은 업데이트 안 함
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

        String difficultyText = '알 수 없음';
        if (currentStage < PuzzleData.difficulties.length) {
          final difficulty = PuzzleData.difficulties[currentStage];
          switch (difficulty) {
            case 'beginner':
              difficultyText = '입문자';
              break;
            case 'rookie':
              difficultyText = '초보자';
              break;
            case 'easy':
              difficultyText = '초급';
              break;
            case 'medium':
              difficultyText = '중급';
              break;
            case 'hard':
              difficultyText = '고급';
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
        return AlertDialog(
          title: const Text(
            '난이도 선택',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyButton(
                context: context,
                label: '입문자',
                description: 'Beginner - 처음 시작하는 난이도',
                color: Colors.lightBlue,
                difficulty: 'beginner',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                label: '초보자',
                description: 'Rookie - 연습하기 좋은 난이도',
                color: Colors.cyan,
                difficulty: 'rookie',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                label: '초급',
                description: 'Easy - 쉬운 난이도',
                color: Colors.green,
                difficulty: 'easy',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                label: '중급',
                description: 'Medium - 보통 난이도',
                color: Colors.orange,
                difficulty: 'medium',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                label: '고급',
                description: 'Hard - 어려운 난이도',
                color: Colors.red,
                difficulty: 'hard',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDifficultyButton({
    required BuildContext context,
    required String label,
    required String description,
    required Color color,
    required String difficulty,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
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
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$difficulty 난이도의 퍼즐이 없습니다.')),
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

                    const Text(
                      '스도쿠 퍼즐 게임',
                      style: TextStyle(
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
                              child: const Text(
                                '새로 시작',
                                style: TextStyle(
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
                                    ? '이어서 하기\n$_savedGameInfo'
                                    : '저장된 게임 없음',
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