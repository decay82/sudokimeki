import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';
import '../utils/tutorial_storage.dart';
import '../utils/game_storage.dart';
import 'tutorial_screen.dart';
import 'sudoku_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String selectedDifficulty;

  const OnboardingScreen({super.key, required this.selectedDifficulty});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int? _selectedIndex;

  final List<String> _options = [
    '해 본 적이 없다',
    '몇 번 해 본 적이 있다',
    '주기적으로 한다',
  ];

  void _onContinue() async {
    if (_selectedIndex == null) return;

    await TutorialStorage.setOnboardingDone();

    if (!mounted) return;

    if (_selectedIndex == 0) {
      // 처음 해보는 사람 → 튜토리얼
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TutorialScreen(
            selectedDifficulty: widget.selectedDifficulty,
          ),
        ),
      );
    } else {
      // 경험자 → 선택한 난이도로 바로 게임 시작
      final game = context.read<SudokuGame>();
      await GameStorage.clearSavedGame();
      if (!mounted) return;
      game.loadStage(0, difficulty: widget.selectedDifficulty);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SudokuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              const Text(
                '스도쿠 퍼즐을 얼마나 경험해\n보셨나요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              Column(
                children: List.generate(_options.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                              : const Color(0xFFF1F3F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_list_bulleted,
                              color: isSelected
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF5C7BB5),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _options[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const Spacer(flex: 4),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedIndex != null ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor: const Color(0xFFD0D0D0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '계속하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
