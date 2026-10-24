import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';
import '../l10n/app_localizations.dart';
import '../utils/ad_helper.dart';

class FunctionButtons extends StatelessWidget {
  final GlobalKey? smartInputButtonKey;

  const FunctionButtons({super.key, this.smartInputButtonKey});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<SudokuGame>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              key: smartInputButtonKey,
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
                onPressed: () async {
                  // 힌트가 없으면 보상형 광고 시청으로 힌트 획득
                  if (!game.isHintMode && game.hintsAvailable <= 0) {
                    await AdHelper.showRewardedAd(
                      onRewarded: () {
                        // 광고 시청 완료 - 힌트 1개 지급하고 힌트 모드 활성화
                        game.addHintFromAd();
                      },
                      onAdFailed: () {
                        // 광고 실패 시 아무 동작 안함
                      },
                    );
                  } else {
                    // 힌트가 있으면 일반 토글
                    game.toggleHintMode();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      game.isHintMode ? Colors.amber : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  game.isHintMode
                      ? l10n.hintOn
                      : game.hintsAvailable > 0
                          ? l10n.hintPlus(game.hintsAvailable)
                          : l10n.hint,
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
