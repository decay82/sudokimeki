import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';

class FunctionButtons extends StatelessWidget {
  const FunctionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: game.toggleSmartInputMode,
                icon: Icon(
                  game.isSmartInputMode ? Icons.touch_app : Icons.touch_app_outlined,
                  size: 14,
                ),
                label: Text(
                  game.isSmartInputMode ? 'ON' : '',
                  style: const TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      game.isSmartInputMode ? Colors.purple : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: game.toggleMemoMode,
                icon: Icon(
                  game.isMemoMode ? Icons.edit : Icons.edit_outlined,
                  size: 14,
                ),
                label: Text(
                  game.isMemoMode ? 'ON' : '',
                  style: const TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      game.isMemoMode ? Colors.orange : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: game.clearCell,
                icon: const Icon(Icons.clear, size: 14),
                label: const Text(
                  '',
                  style: TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton(
                onPressed: game.toggleHintMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      game.isHintMode ? Colors.amber : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  game.isHintMode
                      ? '힌트 ON'
                      : game.hintsAvailable > 0
                          ? '힌트 +${game.hintsAvailable}'
                          : '힌트',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
