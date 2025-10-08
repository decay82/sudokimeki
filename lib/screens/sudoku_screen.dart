import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';

import '../models/sudoku_game.dart';
import '../utils/ad_helper.dart';
import '../utils/play_counter.dart';
import '../utils/sound_helper.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../data/puzzle_data.dart';
import 'welcome_screen.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final List<GlobalKey> _heartKeys = List.generate(3, (_) => GlobalKey());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    });
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
                label: const Text('광고 시청 후 하트 1개 받기'),
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
                      print('!!! 전면 광고 로드 실패. 바로 새 게임을 시작합니다.');
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
                label: const Text('새 게임'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletionDialog(BuildContext context, SudokuGame game) {
    final timeString = game.getElapsedTimeString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 스테이지 완료! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 80),
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDifficultySelectionDialog(context, game);
              },
              child: const Text('다음 스테이지'),
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
                await game.saveGame();

                if (!context.mounted) return;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
            ),
            title: Row(
              children: [
                Text(difficultyText),
                const Spacer(),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings, size: 24),
                  onPressed: () {
                    _showOptionsDialog(context);
                  },
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Column(
            children: [
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