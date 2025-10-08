import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 메모, 삭제, 힌트 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: game.toggleMemoMode,
                  icon: Icon(
                    game.isMemoMode ? Icons.edit : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(
                    game.isMemoMode ? '메모 ON' : '메모',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        game.isMemoMode ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: game.clearCell,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text(
                    '삭제',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: game.toggleHintMode,
                  icon: Icon(
                    game.isHintMode ? Icons.lightbulb : Icons.play_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    game.isHintMode ? '힌트 ON' : '힌트',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        game.isHintMode ? Colors.amber : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 숫자 버튼 1-9 (한 줄)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (index) {
              final number = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 38,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => game.setNumber(number),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}