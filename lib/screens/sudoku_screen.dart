import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

import '../models/sudoku_game.dart';
import '../utils/ad_helper.dart';
import '../utils/play_counter.dart';
import '../utils/sound_helper.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../data/puzzle_data.dart';
import '../utils/daily_mission_storage.dart';
import 'main_screen.dart';

class SudokuScreen extends StatefulWidget {
  final String? difficulty;
  final bool isDailyMission;
  final String? dailyMissionDate;
  final int? puzzleNumber;
  final List<List<int>>? savedBoard;
  final List<List<bool>>? savedCorrectCells;
  final int? savedElapsedSeconds;

  const SudokuScreen({
    super.key,
    this.difficulty,
    this.isDailyMission = false,
    this.dailyMissionDate,
    this.puzzleNumber,
    this.savedBoard,
    this.savedCorrectCells,
    this.savedElapsedSeconds,
  });

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final List<GlobalKey> _heartKeys = List.generate(3, (_) => GlobalKey());
  bool _isLoading = false;
  late ConfettiController _confettiController;


  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    AdHelper.preloadRewardedAd();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {});
        return true;
      }
      return false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<SudokuGame>();
      game.onCompletionCallback = () {
        _showCompletionDialog(context, game);
      };
      game.onGameOverCallback = () {
        _showGameOverDialog(context, game);
      };

      // 일일 미션인 경우 퍼즐 로드
      if (widget.isDailyMission && widget.puzzleNumber != null) {
        if (widget.savedBoard != null && widget.savedCorrectCells != null) {
          // 저장된 진행 상황 불러오기
          game.loadDailyMissionProgress(
            puzzleNumber: widget.puzzleNumber!,
            savedBoard: widget.savedBoard!,
            savedCorrectCells: widget.savedCorrectCells!,
            elapsedSeconds: widget.savedElapsedSeconds ?? 0,
          );
        } else {
          // 새로운 퍼즐 시작
          game.loadStage(widget.puzzleNumber!, difficulty: widget.difficulty ?? 'easy', recordStart: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Offset _getHeartPosition(int heartIndex) {
    if (heartIndex < 0 || heartIndex >= _heartKeys.length) {
      return Offset.zero;
    }
    final key = _heartKeys[heartIndex];
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  String _formatScore(int score) {
    // 3자리마다 쉼표 추가
    String scoreStr = score.toString();
    String result = '';
    int count = 0;

    for (int i = scoreStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = scoreStr[i] + result;
      count++;
    }

    return result;
  }


  void _showOptionsDialog(BuildContext context) async {
    bool soundEnabled = await SoundHelper.isSoundEnabled();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings, size: 28),
                  SizedBox(width: 8),
                  Text('옵션'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_up, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '효과음',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Switch(
                        value: soundEnabled,
                        onChanged: (value) async {
                          await SoundHelper.setSoundEnabled(value);
                          setState(() {
                            soundEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGameOverDialog(BuildContext context, SudokuGame game) {
    game.pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.heart_broken, color: Colors.red, size: 32),
                SizedBox(width: 8),
                Text('게임 오버'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dangerous, color: Colors.red, size: 80),
                SizedBox(height: 16),
                Text(
                  '3회 실수하면 게임이 종료됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '광고를 끝까지 시청해야 하트를 받을 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      print('>>> 하트 광고 버튼 클릭됨');

                      RewardedAd? ad = AdHelper.getPreloadedRewardedAd();

                      if (ad != null) {
                        bool rewardEarned = false;

                        ad.fullScreenContentCallback = FullScreenContentCallback(
                          onAdFailedToShowFullScreenContent: (ad, error) {
                            print('!!! 하트 광고 표시 실패: ${error.message}');
                            ad.dispose();
                          },
                          onAdDismissedFullScreenContent: (ad) {
                            print('하트 광고 닫힘 - rewardEarned: $rewardEarned');
                            ad.dispose();

                            if (rewardEarned) {
                              print('보상 지급: 하트 추가');
                              game.addHeart();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                game.resumeTimer();
                              }
                            }
                          },
                        );

                        ad.show(
                          onUserEarnedReward: (ad, reward) {
                            print('광고 시청 보상 조건 충족!');
                            rewardEarned = true;
                          },
                        );
                      } else {
                        print('!!! 하트 광고 로드 실패. 보상을 바로 지급합니다.');
                        game.addHeart();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          game.resumeTimer();
                        }
                      }
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('광고 시청 후 하트 3개 충전'),
                  ),
                  TextButton.icon(
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
                              game.resumeTimer();
                              game.restartStage();
                              setState(() => _isLoading = false);
                            },
                            onAdDismissedFullScreenContent: (ad) {
                              print('전면 광고 닫힘');
                              ad.dispose();
                              game.resumeTimer();
                              game.restartStage();
                              setState(() => _isLoading = false);
                            },
                          );
                          ad.show();
                        } else {
                          print('!!! 전면 광고 로드 실패. 바로 다시 시작합니다.');
                          game.resumeTimer();
                          game.restartStage();
                          setState(() => _isLoading = false);
                        }
                      } else {
                        print('플레이 횟수 3회 미만, 광고 스킵');
                        game.resumeTimer();
                        game.restartStage();
                        setState(() => _isLoading = false);
                      }
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('다시 시작'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // 게임 오버 다이얼로그 닫기
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('홈'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletionDialog(BuildContext context, SudokuGame game) async {
    final timeString = game.getElapsedTimeString();

    // 일일 미션이면 완료 처리
    if (widget.isDailyMission && widget.dailyMissionDate != null) {
      await DailyMissionStorage.completeMission(
        widget.dailyMissionDate!,
        widget.difficulty ?? 'easy',
        game.currentStage,
        elapsedSeconds: game.elapsedTime.inSeconds,
      );
    }

    if (!mounted) return;

    // 컨페티 시작
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            // 컨페티 위젯 (화면 상단 중앙에서 아래로, 넓게 퍼짐)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // 아래 방향 (90도)
                blastDirectionality: BlastDirectionality.explosive, // 폭발적으로 퍼짐
                emissionFrequency: 0.05, // 발생 빈도
                numberOfParticles: 20, // 한번에 나오는 입자 수
                gravity: 0.15, // 중력 (0.3 → 0.15로 줄여서 50% 속도)
                shouldLoop: false, // 반복 안함
                maxBlastForce: 15, // 최대 폭발 힘 (넓게 퍼지게)
                minBlastForce: 8, // 최소 폭발 힘
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                ],
              ),
            ),
            // 다이얼로그
            AlertDialog(
              title: Text(widget.isDailyMission ? '🎉 일일 미션 완료! 🎉' : '🎉 스테이지 완료! 🎉'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '총 점수',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatScore(game.totalScore),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '기록: $timeString',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.isDailyMission) ...[
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(); // 일일 미션 화면으로 돌아가기
                    },
                    child: const Text('홈'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop();
                      _showDifficultySelectionDialog(context, game);
                    },
                    child: const Text('다음 스테이지'),
                  ),
                  TextButton(
                    onPressed: () {
                      _confettiController.stop();
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                    child: const Text('홈'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDifficultySelectionDialog(BuildContext context, SudokuGame game) {
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
                game: game,
                label: '입문자',
                description: 'Beginner - 처음 시작하는 난이도',
                color: Colors.lightBlue,
                difficulty: 'beginner',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                game: game,
                label: '초보자',
                description: 'Rookie - 연습하기 좋은 난이도',
                color: Colors.cyan,
                difficulty: 'rookie',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                game: game,
                label: '초급',
                description: 'Easy - 쉬운 난이도',
                color: Colors.green,
                difficulty: 'easy',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                game: game,
                label: '중급',
                description: 'Medium - 보통 난이도',
                color: Colors.orange,
                difficulty: 'medium',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButton(
                context: context,
                game: game,
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

  void _showDifficultySelectionDialogFromGameOver(BuildContext context, SudokuGame game) {
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
              _buildDifficultyButtonFromGameOver(
                context: context,
                game: game,
                label: '입문자',
                description: 'Beginner - 처음 시작하는 난이도',
                color: Colors.lightBlue,
                difficulty: 'beginner',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButtonFromGameOver(
                context: context,
                game: game,
                label: '초보자',
                description: 'Rookie - 연습하기 좋은 난이도',
                color: Colors.cyan,
                difficulty: 'rookie',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButtonFromGameOver(
                context: context,
                game: game,
                label: '초급',
                description: 'Easy - 쉬운 난이도',
                color: Colors.green,
                difficulty: 'easy',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButtonFromGameOver(
                context: context,
                game: game,
                label: '중급',
                description: 'Medium - 보통 난이도',
                color: Colors.orange,
                difficulty: 'medium',
              ),
              const SizedBox(height: 12),
              _buildDifficultyButtonFromGameOver(
                context: context,
                game: game,
                label: '고급',
                description: 'Hard - 어려운 난이도',
                color: Colors.red,
                difficulty: 'hard',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showGameOverDialog(context, game);
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDifficultyButton({
    required BuildContext context,
    required SudokuGame game,
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

          final puzzlesOfDifficulty = <int>[];
          for (int i = 0; i < PuzzleData.difficulties.length; i++) {
            if (PuzzleData.difficulties[i] == difficulty) {
              puzzlesOfDifficulty.add(i);
            }
          }

          int nextStage;
          if (puzzlesOfDifficulty.isEmpty) {
            nextStage = 0;
          } else {
            final random = Random();
            nextStage = puzzlesOfDifficulty[random.nextInt(puzzlesOfDifficulty.length)];
          }

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
                  game.loadStage(nextStage, difficulty: difficulty);
                  setState(() => _isLoading = false);
                },
                onAdDismissedFullScreenContent: (ad) {
                  print('전면 광고 닫힘');
                  ad.dispose();
                  game.loadStage(nextStage, difficulty: difficulty);
                  setState(() => _isLoading = false);
                },
              );
              ad.show();
            } else {
              print('!!! 전면 광고 로드 실패. 바로 다음 스테이지로 이동합니다.');
              game.loadStage(nextStage, difficulty: difficulty);
              setState(() => _isLoading = false);
            }
          } else {
            print('플레이 횟수 3회 미만, 광고 스킵');
            game.loadStage(nextStage, difficulty: difficulty);
            setState(() => _isLoading = false);
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

  Widget _buildDifficultyButtonFromGameOver({
    required BuildContext context,
    required SudokuGame game,
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

          final puzzlesOfDifficulty = <int>[];
          for (int i = 0; i < PuzzleData.difficulties.length; i++) {
            if (PuzzleData.difficulties[i] == difficulty) {
              puzzlesOfDifficulty.add(i);
            }
          }

          int nextStage;
          if (puzzlesOfDifficulty.isEmpty) {
            nextStage = 0;
          } else {
            final random = Random();
            nextStage = puzzlesOfDifficulty[random.nextInt(puzzlesOfDifficulty.length)];
          }

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
                  game.resumeTimer();
                  game.loadStage(nextStage, difficulty: difficulty);
                  setState(() => _isLoading = false);
                },
                onAdDismissedFullScreenContent: (ad) {
                  print('전면 광고 닫힘');
                  ad.dispose();
                  game.resumeTimer();
                  game.loadStage(nextStage, difficulty: difficulty);
                  setState(() => _isLoading = false);
                },
              );
              ad.show();
            } else {
              print('!!! 전면 광고 로드 실패. 바로 새 게임을 시작합니다.');
              game.resumeTimer();
              game.loadStage(nextStage, difficulty: difficulty);
              setState(() => _isLoading = false);
            }
          } else {
            print('플레이 횟수 3회 미만, 광고 스킵');
            game.resumeTimer();
            game.loadStage(nextStage, difficulty: difficulty);
            setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();

    String difficultyText = '알 수 없음';
    if (game.currentStage < PuzzleData.difficulties.length) {
      final difficulty = PuzzleData.difficulties[game.currentStage];
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
        default:
          difficultyText = difficulty;
      }
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final game = context.read<SudokuGame>();

                // 일일 미션이면 진행 상황 저장
                if (widget.isDailyMission && widget.dailyMissionDate != null && !game.isCompleted) {
                  await DailyMissionStorage.saveMissionProgress(
                    date: widget.dailyMissionDate!,
                    difficulty: widget.difficulty ?? 'easy',
                    puzzleNumber: game.currentStage,
                    board: game.board,
                    correctCells: game.correctCells,
                    elapsedSeconds: game.elapsedTime.inSeconds,
                  );
                } else {
                  // 일반 게임이면 기존 방식대로 저장
                  await game.saveGame();
                }

                if (!context.mounted) return;

                // 일일 미션이면 단순히 뒤로가기
                if (widget.isDailyMission) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(),
                    ),
                  );
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 24),
                onPressed: () {
                  _showOptionsDialog(context);
                },
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Column(
            children: [
              // 보드 위 게임 정보 영역
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 난이도
                    Text(
                      difficultyText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // 점수
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${game.totalScore}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 하트
                    Row(
                      children: List.generate(3, (index) {
                        final isTargetHeart =
                            game.heartAnimationStatus ==
                                HeartAnimationStatus.animating &&
                            index == game.hearts;
                        return AnimatedScale(
                          key: _heartKeys[index],
                          scale: isTargetHeart ? 1.5 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            index < game.hearts
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 24,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // 타이머
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            game.getElapsedTimeString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 3, child: Center(child: SudokuBoard())),
              const Expanded(flex: 1, child: NumberPad()),
              SizedBox(
                height: 50,
                child: game.isBannerAdLoaded && game.bannerAd != null
                    ? Container(
                        alignment: Alignment.center,
                        child: AdWidget(ad: game.bannerAd!),
                      )
                    : Container(color: Colors.transparent),
              ),
            ],
          ),
        ),
        if (game.heartAnimationStatus == HeartAnimationStatus.animating)
          HeartAnimationOverlay(
            startPosition: Offset(
              MediaQuery.of(context).size.width / 2,
              MediaQuery.of(context).size.height / 2,
            ),
            endPosition: _getHeartPosition(game.hearts),
            onAnimationEnd: () {

            },
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
    );
  }
}

class HeartAnimationOverlay extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onAnimationEnd;

  const HeartAnimationOverlay({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.onAnimationEnd,
  });

  @override
  State<HeartAnimationOverlay> createState() => _HeartAnimationOverlayState();
}

class _HeartAnimationOverlayState extends State<HeartAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    print("LOG 2: HeartAnimationOverlay created.");
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final endPos = (widget.endPosition == Offset.zero)
        ? widget.startPosition
        : widget.endPosition;

    print(
      "LOG 2.5: Animation will fly from ${widget.startPosition} to $endPos",
    );

    _positionAnimation = Tween<Offset>(begin: widget.startPosition, end: endPos)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const _DelayCurve(delayFraction: 0.5 / 1.0),
          ),
        );

    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted) {
        _controller.forward().whenComplete(() {
          print(
            "LOG 3: Flying animation COMPLETED. Calling onAnimationEnd callback.",
          );
          widget.onAnimationEnd();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: IgnorePointer(
            child: Icon(
              Icons.favorite,
              color: Colors.red.withOpacity(1.0 - _controller.value),
              size: 30,
            ),
          ),
        );
      },
    );
  }
}

class _DelayCurve extends Curve {
  const _DelayCurve({required this.delayFraction});

  final double delayFraction;

  @override
  double transformInternal(double t) {
    if (t < delayFraction) {
      return 0.0;
    }
    final adjustedT = (t - delayFraction) / (1.0 - delayFraction);
    return Curves.easeOutCubic.transformInternal(adjustedT);
  }
}

