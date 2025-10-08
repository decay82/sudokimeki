import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기 계산
        double size = constraints.maxWidth > constraints.maxHeight
            ? constraints.maxHeight * 0.95
            : constraints.maxWidth * 0.95;

        // 최대 크기 제한
        if (size > 600) size = 600;

        double cellSize = size / 9;

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              children: List.generate(9, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(9, (col) {
                      final isSelected =
                          game.selectedRow == row && game.selectedCol == col;
                      final isInitial = game.isInitialCell(row, col);
                      final isCorrect = game.correctCells[row][col];
                      final value = game.board[row][col];
                      final isAnimating = game.isCellAnimating(row, col);

                      // 선택된 셀의 숫자 가져오기
                      final selectedValue =
                          game.selectedRow != null && game.selectedCol != null
                              ? game.board[game.selectedRow!][game.selectedCol!]
                              : 0;
                      final isSameNumber = value != 0 && value == selectedValue;

                      Color bgColor = Colors.white;
                      if (isAnimating) {
                        bgColor = Colors.blue.withOpacity(0.5);
                      } else if (isSelected) {
                        bgColor = Colors.blue.withOpacity(0.8);
                      } else if (isSameNumber) {
                        bgColor = const Color.fromRGBO(135, 174, 253, 1);
                      } else if (game.selectedRow == row ||
                          game.selectedCol == col) {
                        bgColor = const Color.fromRGBO(241, 242, 247, 1);
                      }

                      final boxRow = row ~/ 3;
                      final boxCol = col ~/ 3;
                      if (game.selectedRow != null && game.selectedCol != null) {
                        final selectedBoxRow = game.selectedRow! ~/ 3;
                        final selectedBoxCol = game.selectedCol! ~/ 3;
                        if (boxRow == selectedBoxRow && boxCol == selectedBoxCol) {
                          if (bgColor == Colors.white) {
                            bgColor = const Color.fromRGBO(241, 242, 247, 1);
                          }
                        }
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: game.isHintMode
                              ? () => game.useHint(row, col)
                              : () => game.selectCell(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border(
                                right: BorderSide(
                                  color: (col + 1) % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: (col + 1) % 3 == 0 ? 2 : 1,
                                ),
                                bottom: BorderSide(
                                  color: (row + 1) % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: (row + 1) % 3 == 0 ? 2 : 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: value != 0
                                  ? Text(
                                      value.toString(),
                                      style: TextStyle(
                                        fontSize: cellSize * 0.7,
                                        fontWeight: FontWeight.normal,
                                        color: isInitial
                                            ? Colors.black
                                            : (isCorrect
                                                ? const Color.fromRGBO(12, 65, 173, 1)
                                                : const Color.fromRGBO(206, 49, 85, 1)),
                                      ),
                                    )
                                  : (game.memos[row][col].isNotEmpty
                                      ? _buildMemoGrid(
                                          game.memos[row][col], cellSize)
                                      : null),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemoGrid(Set<int> memos, double cellSize) {
    return GridView.builder(
      padding: EdgeInsets.all(cellSize * 0.05),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final number = index + 1;
        final hasMemo = memos.contains(number);
        return Center(
          child: Text(
            hasMemo ? number.toString() : '',
            style: TextStyle(
              fontSize: cellSize * 0.2,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }
}
