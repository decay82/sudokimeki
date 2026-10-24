import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

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

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  bool _hasSavedGame = false;
  String _savedGameInfo = '';
  bool _isLoading = false;
  String _selectedDifficulty = 'beginner';

  late AnimationController _heartController;
  late AnimationController _pulseController;
  late Animation<double> _heartAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();

    // 하트 비트 애니메이션
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _heartAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    // 로고 펄스 애니메이션
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final hasSaved = await GameStorage.hasSavedGame();

    if (hasSaved) {
      final savedData = await GameStorage.loadGame();
      if (savedData != null) {
        final currentStage = savedData['currentStage'] as int;
        final elapsedSeconds = savedData['elapsedSeconds'] as int;

        final l10n = AppLocalizations.of(context)!;

        String difficultyText = l10n.difficultyUnknown;
        if (currentStage < PuzzleData.difficulties.length) {
          final difficulty = PuzzleData.difficulties[currentStage];
          switch (difficulty) {
            case 'beginner':
              difficultyText = l10n.difficultyBeginner;
              break;
            case 'rookie':
              difficultyText = l10n.difficultyRookie;
              break;
            case 'easy':
              difficultyText = l10n.difficultyEasy;
              break;
            case 'medium':
              difficultyText = l10n.difficultyMedium;
              break;
            case 'hard':
              difficultyText = l10n.difficultyHard;
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
              return const Center(child: CircularProgressIndicator());
            }

            final unlockStatus = snapshot.data!;
            final l10n = AppLocalizations.of(context)!;

            return FutureBuilder<Map<String, String>>(
              future: _getAllProgressTexts(context),
              builder: (context, progressSnapshot) {
                final progressTexts = progressSnapshot.data ?? {};

                return AlertDialog(
                  backgroundColor: const Color(0xFFFFF9FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    children: [
                      const Text('🎮', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        l10n.selectDifficulty,
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDifficultyButton(
                          context: context,
                          label: l10n.difficultyBeginner,
                          description: l10n.difficultyBeginnerDesc,
                          color: const Color(0xFF4CAF50),
                          difficulty: 'beginner',
                          isUnlocked: unlockStatus['beginner'] ?? true,
                          progressText: progressTexts['beginner'] ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildDifficultyButton(
                          context: context,
                          label: l10n.difficultyRookie,
                          description: l10n.difficultyRookieDesc,
                          color: const Color(0xFF00BCD4),
                          difficulty: 'rookie',
                          isUnlocked: unlockStatus['rookie'] ?? true,
                          progressText: progressTexts['rookie'] ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildDifficultyButton(
                          context: context,
                          label: l10n.difficultyEasy,
                          description: l10n.difficultyEasyDesc,
                          color: const Color(0xFF2196F3),
                          difficulty: 'easy',
                          isUnlocked: unlockStatus['easy'] ?? false,
                          progressText: progressTexts['easy'] ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildDifficultyButton(
                          context: context,
                          label: l10n.difficultyMedium,
                          description: l10n.difficultyMediumDesc,
                          color: const Color(0xFFFF9800),
                          difficulty: 'medium',
                          isUnlocked: unlockStatus['medium'] ?? false,
                          progressText: progressTexts['medium'] ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildDifficultyButton(
                          context: context,
                          label: l10n.difficultyHard,
                          description: l10n.difficultyHardDesc,
                          color: const Color(0xFFF44336),
                          difficulty: 'hard',
                          isUnlocked: unlockStatus['hard'] ?? false,
                          progressText: progressTexts['hard'] ?? '',
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
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
            ? () {
                Navigator.of(context).pop();
                _startGameWithDifficulty(difficulty);
              }
            : null,
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

      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noPuzzlesForDifficulty(
              getDifficultyName(context, difficulty))),
        ),
      );
      return;
    }

    await PlayCounter.incrementPlayCount();

    final random = Random();
    final randomStage =
        puzzlesOfDifficulty[random.nextInt(puzzlesOfDifficulty.length)];

    game.loadStage(randomStage, difficulty: difficulty);

    // Toss 전면형 광고 표시 (3회마다)
    final playCount = await PlayCounter.getPlayCount();
    if (playCount % 3 == 0) {
      await AdHelper.showInterstitialAd(
        onAdClosed: () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SudokuScreen()),
            );
          }
        },
        onAdFailed: () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SudokuScreen()),
            );
          }
        },
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SudokuScreen()),
      );
    }
  }

  void _continueGame(BuildContext context) async {
    final game = context.read<SudokuGame>();

    final loaded = await game.loadSavedGame();

    if (!mounted) return;

    if (loaded) {
      await PlayCounter.incrementPlayCount();

      setState(() => _isLoading = true);

      // Toss 전면형 광고 표시 (3회마다)
      final playCount = await PlayCounter.getPlayCount();
      if (playCount % 3 == 0) {
        await AdHelper.showInterstitialAd(
          onAdClosed: () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SudokuScreen()),
              );
            }
          },
          onAdFailed: () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SudokuScreen()),
              );
            }
          },
        );
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SudokuScreen()),
          );
        }
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
          // 핑크 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE4EC),
                  Color(0xFFFFD1DC),
                  Color(0xFFFFAFC5),
                  Color(0xFFFF8FAB),
                ],
              ),
            ),
          ),

          // 떠다니는 하트 배경
          ..._buildFloatingHearts(),

          // 반짝이는 스파클
          ..._buildSparkles(),

          // 메인 컨텐츠
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // 로고 섹션
                    _buildLogoSection(),

                    const SizedBox(height: 50),

                    // 메뉴 버튼들
                    _buildMenuButtons(l10n),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 떠다니는 하트들
  List<Widget> _buildFloatingHearts() {
    final hearts = ['💕', '💗', '💖', '💓', '💝', '💘'];
    final positions = [
      {'left': 0.05, 'top': 0.10},
      {'left': 0.15, 'top': 0.60},
      {'left': 0.85, 'top': 0.20},
      {'left': 0.75, 'top': 0.70},
      {'left': 0.50, 'top': 0.85},
      {'left': 0.25, 'top': 0.35},
    ];

    return List.generate(6, (index) {
      return Positioned(
        left: MediaQuery.of(context).size.width * (positions[index]['left']! as double),
        top: MediaQuery.of(context).size.height * (positions[index]['top']! as double),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 2000 + index * 200),
          curve: Curves.easeInOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, sin(value * 2 * pi + index) * 15),
              child: Transform.rotate(
                angle: sin(value * 2 * pi + index) * 0.1,
                child: Opacity(
                  opacity: 0.3,
                  child: Text(
                    hearts[index % hearts.length],
                    style: TextStyle(fontSize: 24.0 + (index % 3) * 4),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // 반짝이는 스파클
  List<Widget> _buildSparkles() {
    final positions = [
      {'left': 0.20, 'top': 0.15},
      {'left': 0.80, 'top': 0.25},
      {'left': 0.30, 'top': 0.45},
      {'left': 0.70, 'top': 0.55},
      {'left': 0.15, 'top': 0.75},
    ];

    return List.generate(5, (index) {
      return Positioned(
        left: MediaQuery.of(context).size.width * (positions[index]['left']! as double),
        top: MediaQuery.of(context).size.height * (positions[index]['top']! as double),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 2000 + index * 500),
          curve: Curves.easeInOut,
          builder: (context, double value, child) {
            final opacity = (sin(value * 2 * pi + index) + 1) / 2 * 0.7 + 0.3;
            final scale = (sin(value * 2 * pi + index) + 1) / 2 * 0.5 + 1.0;
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // 로고 섹션
  Widget _buildLogoSection() {
    return Column(
      children: [
        // 로고 아이콘
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B9D), Color(0xFFFF4757)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 0,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 광택 효과
                Positioned(
                  top: 8,
                  left: 8,
                  right: 60,
                  bottom: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                // 스도쿠 그리드
                Center(
                  child: _buildMiniSudokuGrid(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 타이틀
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFFF4757), Color(0xFFFF7675)],
          ).createShader(bounds),
          child: const Text(
            '스도키메키',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 서브타이틀
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '두근두근',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '스도쿠 퍼즐',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8B7580),
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // 도키도키 애니메이션
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _heartAnimation,
                child: const Text('💓', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 4),
              const Text(
                '도키도키',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              ScaleTransition(
                scale: _heartAnimation,
                child: const Text('💓', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 미니 스도쿠 그리드
  Widget _buildMiniSudokuGrid() {
    return SizedBox(
      width: 70,
      height: 70,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _GridCell(text: '9'),
          _GridCell(text: '♥', isHeart: true),
          _GridCell(text: '3'),
          _GridCell(text: '1'),
          _GridCell(text: '5'),
          _GridCell(text: '♥', isHeart: true),
          _GridCell(text: '♥', isHeart: true),
          _GridCell(text: '7'),
          _GridCell(text: '2'),
        ],
      ),
    );
  }

  // 난이도 선택 Pills
  Widget _buildDifficultyPills(AppLocalizations l10n) {
    final difficulties = [
      {'key': 'beginner', 'label': l10n.difficultyBeginner, 'emoji': ''},
      {'key': 'rookie', 'label': l10n.difficultyRookie, 'emoji': ''},
      {'key': 'easy', 'label': l10n.difficultyEasy, 'emoji': '🔥'},
      {'key': 'medium', 'label': l10n.difficultyMedium, 'emoji': '💪'},
      {'key': 'hard', 'label': l10n.difficultyHard, 'emoji': '👑'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '난이도 선택',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8B7580),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: difficulties.map((diff) {
            final isSelected = _selectedDifficulty == diff['key'];
            return GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = diff['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF4757)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFFF6B9D).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  '${diff['emoji']} ${diff['label']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF4A3540),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 메뉴 버튼들
  Widget _buildMenuButtons(AppLocalizations l10n) {
    return Column(
      children: [
        // 새로 시작 버튼
        _MenuButton(
          icon: '🎮',
          label: l10n.newGame,
          isPrimary: true,
          onPressed: () => _startGameWithDifficulty(_selectedDifficulty),
        ),

        const SizedBox(height: 16),

        // 이어하기 버튼
        _MenuButton(
          icon: '📂',
          label: _hasSavedGame ? l10n.continueGame(_savedGameInfo) : '이어하기',
          isPrimary: false,
          isEnabled: _hasSavedGame,
          onPressed: _hasSavedGame ? () => _continueGame(context) : null,
        ),
      ],
    );
  }
}

// 그리드 셀 위젯
class _GridCell extends StatelessWidget {
  final String text;
  final bool isHeart;

  const _GridCell({required this.text, this.isHeart = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHeart ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeart ? 12 : 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE91E63),
          ),
        ),
      ),
    );
  }
}

// 메뉴 버튼 위젯
class _MenuButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? null
              : (isEnabled ? Colors.white : Colors.white.withOpacity(0.5)),
          foregroundColor: isPrimary ? Colors.white : const Color(0xFFE91E63),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          elevation: isEnabled ? 8 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isEnabled && !isPrimary
                ? BorderSide(color: const Color(0xFFFF6B9D).withOpacity(0.3), width: 2)
                : BorderSide.none,
          ),
          shadowColor: isPrimary ? const Color(0xFFFF4757).withOpacity(0.4) : null,
        ).copyWith(
          backgroundColor: isPrimary
              ? MaterialStateProperty.all(Colors.transparent)
              : null,
        ),
        child: Ink(
          decoration: isPrimary
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF4757)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isPrimary
                        ? Colors.white
                        : (isEnabled ? const Color(0xFFE91E63) : const Color(0xFF8B7580)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
