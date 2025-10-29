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

                      // 스마트 입력 모드에서 선택된 숫자와 같은 숫자 하이라이트
                      // 단, 초기 숫자이거나 정답으로 입력된 숫자만 하이라이트
                      final isSmartHighlight = game.isSmartInputMode &&
                                               game.selectedNumber != null &&
                                               value == game.selectedNumber &&
                                               (isInitial || isCorrect);

                      // 충돌하는 셀인지 확인
                      final isConflicting = game.conflictingCells.contains('${row}_$col');

                      Color bgColor = Colors.white;
                      if (isAnimating) {
                        bgColor = Colors.blue.withOpacity(0.5);
                      } else if (isSelected && !game.isSmartInputMode) {
                        // 일반 모드에서만 선택된 셀 하이라이트
                        bgColor = Colors.blue.withOpacity(0.8);
                      } else if (isConflicting && game.isBlinking) {
                        // 점멸 효과: 빨간색으로 깜빡임
                        bgColor = Colors.red.withOpacity(0.6);
                      } else if (isSmartHighlight) {
                        bgColor = Colors.purple.withOpacity(0.3);
                      } else if (isSameNumber && !game.isSmartInputMode) {
                        // 일반 모드에서만 같은 숫자 하이라이트
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
                          onTap: () {
                            if (game.isHintMode) {
                              game.useHint(row, col);
                            } else if (game.isSmartInputMode && game.selectedNumber != null) {
                              game.selectCell(row, col);
                              game.smartInputCell(row, col);
                            } else {
                              game.selectCell(row, col);
                            }
                          },
                          onPanUpdate: game.isSmartInputMode && game.selectedNumber != null && game.isMemoMode
                              ? (details) {
                                  // 드래그 중 해당 셀 위에 있으면 메모 추가
                                  final RenderBox box = context.findRenderObject() as RenderBox;
                                  final localPosition = box.globalToLocal(details.globalPosition);

                                  if (localPosition.dx >= 0 &&
                                      localPosition.dx < box.size.width &&
                                      localPosition.dy >= 0 &&
                                      localPosition.dy < box.size.height) {
                                    game.smartInputCell(row, col);
                                  }
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border(
                                left: BorderSide(
                                  color: col % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: col % 3 == 0 ? 1.0 : 0.5,
                                ),
                                right: BorderSide(
                                  color: (col + 1) % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: (col + 1) % 3 == 0 ? 1.0 : 0.5,
                                ),
                                top: BorderSide(
                                  color: row % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: row % 3 == 0 ? 1.0 : 0.5,
                                ),
                                bottom: BorderSide(
                                  color: (row + 1) % 3 == 0
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  width: (row + 1) % 3 == 0 ? 1.0 : 0.5,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: value != 0
                                      ? Text(
                                          value.toString(),
                                          style: TextStyle(
                                            fontSize: cellSize * 0.7,
                                            fontWeight: FontWeight.normal,
                                            color: isInitial
                                                ? const Color(0xFF20252B)
                                                : (isCorrect
                                                    ? const Color.fromRGBO(12, 65, 173, 1)
                                                    : const Color.fromRGBO(206, 49, 85, 1)),
                                          ),
                                        )
                                      : (game.memos[row][col].isNotEmpty
                                          ? _buildMemoGrid(
                                              game.memos[row][col],
                                              cellSize,
                                              game.isSmartInputMode ? game.selectedNumber : null)
                                          : null),
                                ),
                                // 점수 표시 애니메이션
                                if (game.scoreDisplayRow == row &&
                                    game.scoreDisplayCol == col &&
                                    game.scoreDisplayValue != null)
                                  AnimatedScoreDisplay(
                                    key: ValueKey(game.scoreDisplayTime),
                                    score: game.scoreDisplayValue!,
                                    cellSize: cellSize,
                                  ),
                              ],
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

  Widget _buildMemoGrid(Set<int> memos, double cellSize, int? highlightNumber) {
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
        final isHighlighted = hasMemo && highlightNumber != null && number == highlightNumber;

        return Center(
          child: Container(
            decoration: isHighlighted
                ? BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  )
                : null,
            padding: isHighlighted ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1) : null,
            child: Text(
              hasMemo ? number.toString() : '',
              style: TextStyle(
                fontSize: cellSize * 0.2,
                color: isHighlighted ? Colors.purple : const Color(0xFF20252B),
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}

// 점수 애니메이션 위젯
class AnimatedScoreDisplay extends StatefulWidget {
  final int score;
  final double cellSize;

  const AnimatedScoreDisplay({
    super.key,
    required this.score,
    required this.cellSize,
  });

  @override
  State<AnimatedScoreDisplay> createState() => _AnimatedScoreDisplayState();
}

class _AnimatedScoreDisplayState extends State<AnimatedScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 위로 올라가는 애니메이션 (0에서 -10까지)
    _slideAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 페이드아웃 애니메이션
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
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
          bottom: widget.cellSize + 10 + _slideAnimation.value,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Center(
              child: Text(
                '${widget.score}',
                style: TextStyle(
                  fontSize: widget.cellSize * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  shadows: [
                    Shadow(
                      color: Colors.white.withAlpha(200),
                      blurRadius: 3,
                    ),
                    Shadow(
                      color: Colors.black.withAlpha(76),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
