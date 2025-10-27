import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';
import '../l10n/app_localizations.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  int _getRemainingCount(SudokuGame game, int number) {
    int count = 0;

    // 보드를 순회하면서 해당 숫자 개수 카운트
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        // 초기 보드의 숫자 또는 정답으로 입력된 숫자
        if (game.initialBoard[i][j] == number ||
            (game.correctCells[i][j] && game.board[i][j] == number)) {
          count++;
        }
      }
    }

    return 9 - count;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 기능 버튼 (1줄, 4개)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 스마트 입력 버튼
                Flexible(
                  child: _buildFunctionButton(
                    onPressed: game.toggleSmartInputMode,
                    icon: Icon(
                      game.isSmartInputMode ? Icons.touch_app : Icons.touch_app_outlined,
                      size: 13,
                    ),
                    label: game.isSmartInputMode ? l10n.smartOn : l10n.smart,
                    isActive: game.isSmartInputMode,
                    activeColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 4),
                // 메모 버튼
                Flexible(
                  child: _buildFunctionButton(
                    onPressed: game.toggleMemoMode,
                    icon: Icon(
                      game.isMemoMode ? Icons.edit : Icons.edit_outlined,
                      size: 13,
                    ),
                    label: game.isMemoMode ? l10n.memoOn : l10n.memo,
                    isActive: game.isMemoMode,
                    activeColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                // 삭제 버튼
                Flexible(
                  child: _buildFunctionButton(
                    onPressed: game.clearCell,
                    icon: const Icon(Icons.clear, size: 13),
                    label: l10n.delete,
                    isActive: false,
                    activeColor: Colors.red,
                    backgroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                // 힌트 버튼
                Flexible(
                  child: _buildFunctionButton(
                    onPressed: game.toggleHintMode,
                    icon: game.hintsAvailable == 0
                        ? const Icon(Icons.play_circle_outline, size: 13)
                        : null,
                    label: game.isHintMode
                        ? l10n.hintOn
                        : game.hintsAvailable > 0
                            ? l10n.hintPlus(game.hintsAvailable)
                            : l10n.hint,
                    isActive: game.isHintMode,
                    activeColor: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 숫자 버튼 1-9 (한 줄, 최대 크기 제한)
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final spacing = 4.0;
                final totalSpacing = spacing * 8; // 9개 버튼 사이 8개 간격

                // 버튼 너비 계산 (최대 45px로 제한)
                final calculatedWidth = (totalWidth - totalSpacing) / 9;
                final buttonWidth = calculatedWidth > 45 ? 45.0 : calculatedWidth;

                // 버튼 높이 계산 (최대 60px로 제한)
                final calculatedHeight = buttonWidth * 1.8;
                final buttonHeight = calculatedHeight > 60 ? 60.0 : calculatedHeight;

                // 텍스트 크기 고정 (버튼이 최대 크기일 때 기준)
                final numberFontSize = buttonWidth >= 45 ? 24.0 : buttonWidth * 0.53;
                final remainingFontSize = buttonWidth >= 45 ? 12.0 : buttonWidth * 0.27;

                // 텍스트 간격 (최대 1.2px로 제한)
                final textSpacing = (buttonHeight * 0.03) > 1.2 ? 1.2 : buttonHeight * 0.03;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (index) {
                    final number = index + 1;
                    final remaining = _getRemainingCount(game, number);
                    final isHidden = remaining == 0;

                    final isSelected = game.isSmartInputMode && game.selectedNumber == number;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: Opacity(
                          opacity: isHidden ? 0.0 : 1.0,
                          child: ElevatedButton(
                            onPressed: isHidden
                                ? null
                                : () {
                                    if (game.isSmartInputMode) {
                                      game.selectNumber(number);
                                    } else {
                                      game.setNumber(number);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.deepPurple : Colors.blue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.blue,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  number.toString(),
                                  style: TextStyle(
                                    fontSize: numberFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: textSpacing),
                                Text(
                                  remaining.toString(),
                                  style: TextStyle(
                                    fontSize: remainingFontSize,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionButton({
    required VoidCallback onPressed,
    Widget? icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    Color? backgroundColor,
  }) {
    final bgColor = backgroundColor ?? (isActive ? activeColor : Colors.grey);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(height: 2),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}