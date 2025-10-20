import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';

class NumberButtons extends StatelessWidget {
  const NumberButtons({super.key});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
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
    );
  }
}
