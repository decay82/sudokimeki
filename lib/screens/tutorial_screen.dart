import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sudoku_game.dart';
import '../utils/tutorial_storage.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../l10n/app_localizations.dart';
import 'sudoku_screen.dart';

// 튜토리얼 단계 정의
// 0: 가로줄 규칙 설명 (툴팁)
// 1: 스마트 버튼 탭 유도
// 2: 숫자 5 탭 유도
// 3: 빈 셀 (4,4) 탭 유도
// 4: 가로줄 완성! (툴팁)
// 5: 세로줄 규칙 설명 (툴팁)
// 6: 숫자 9 탭 유도
// 7: 빈 셀 (1,7) 탭 유도
// 8: 완료 다이얼로그

const int _rowTargetRow = 4;
const int _rowTargetCol = 4;
const int _rowTargetNumber = 1;

const int _colTargetRow = 1;
const int _colTargetCol = 7;
const int _colTargetNumber = 3;

const int _boxTargetRow = 2;
const int _boxTargetCol = 6;
const int _boxTargetNumber = 6;
const int _boxIndex = 2; // 우측 상단 3×3 (rows 0-2, cols 6-8)

class TutorialScreen extends StatefulWidget {
  final String selectedDifficulty;
  const TutorialScreen({super.key, required this.selectedDifficulty});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  bool _showCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTutorial();
    });
  }

  void _initTutorial() {
    final game = context.read<SudokuGame>();
    game.loadTutorialBoard();
    _applyConstraintsForStep(0);
  }

  void _applyConstraintsForStep(int step) {
    final game = context.read<SudokuGame>();
    switch (step) {
      case 0: // 가로줄 설명 - 아무것도 못 누름 (행 4 빨간 박스 표시)
        game.setTutorialConstraints(highlightRow: _rowTargetRow);
        break;
      case 1: // 스마트 버튼만 (숫자 버튼 표시는 하되 비활성)
        game.setTutorialConstraints(allowSmartButton: true);
        break;
      case 2: // 숫자 1만 활성 (전체 노출)
        game.setTutorialConstraints(allowedNumber: _rowTargetNumber);
        break;
      case 3: // 셀 (4,4)만
        game.setTutorialConstraints(
          allowedRow: _rowTargetRow,
          allowedCol: _rowTargetCol,
        );
        break;
      case 4: // 가로 완성 설명 - 아무것도 못 누름
        game.setTutorialConstraints();
        break;
      case 5: // 세로줄 설명 - 아무것도 못 누름
        game.setTutorialConstraints();
        break;
      case 6: // 숫자 3만 활성, 행 4 완성 표시, 열 7 빨간 박스, 셀 선택만 초기화
        game.setTutorialConstraints(
          allowedNumber: _colTargetNumber,
          completedRow: _rowTargetRow,
          highlightCol: _colTargetCol,
          clearSelection: true,
          keepSmartMode: true,
        );
        break;
      case 7: // 셀 (1,7)만, 행 4 완성 표시
        game.setTutorialConstraints(
          allowedRow: _colTargetRow,
          allowedCol: _colTargetCol,
          completedRow: _rowTargetRow,
        );
        break;
      case 8: // 중간 완료 팝업 - 아무것도 못 누름
        game.setTutorialConstraints(clearSelection: true);
        break;
      case 9: // 3×3 규칙 설명 - 우측 상단 3×3 빨간 박스, 아무것도 못 누름
        game.setTutorialConstraints(highlightBoxes: {_boxIndex});
        break;
      case 10: // 숫자 6 탭 유도
        game.setTutorialConstraints(
          allowedNumber: _boxTargetNumber,
          highlightBoxes: {_boxIndex},
          setSmartMode: true,
        );
        break;
      case 11: // 셀 (2,6) 탭 유도
        game.setTutorialConstraints(
          allowedRow: _boxTargetRow,
          allowedCol: _boxTargetCol,
          highlightBoxes: {_boxIndex},
          keepSmartMode: true,
        );
        break;
    }
  }

  void _nextStep() {
    final next = _step + 1;
    setState(() => _step = next);
    _applyConstraintsForStep(next);
  }

  void _onMidCompleteNext() {
    setState(() {
      _showCompletion = false;
      _step = 9;
    });
    _applyConstraintsForStep(9);
  }

  Future<void> _onFinishToGame() async {
    final game = context.read<SudokuGame>();
    game.exitTutorialMode();
    await TutorialStorage.setTutorialDone();
    if (!mounted) return;
    game.loadStage(0, difficulty: 'beginner');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SudokuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SudokuGame>(
      builder: (context, game, _) {
        // 게임 상태 변화 감지 → 자동 단계 전진
        _checkAutoAdvance(game);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // 실제 게임 UI
                Column(
                  children: [
                    _buildHeader(context),
                    const Expanded(flex: 3, child: Center(child: SudokuBoard())),
                    const NumberPad(),
                    const SizedBox(height: 8),
                  ],
                ),
                // 튜토리얼 오버레이
                if (!_showCompletion) _buildOverlay(context),
                // 완료 다이얼로그
                if (_showCompletion) _buildCompletionDialog(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkAutoAdvance(SudokuGame game) {
    // 다음 프레임에서 처리 (build 중 setState 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_step == 1 && game.isSmartInputMode) {
        setState(() => _step = 2);
        _applyConstraintsForStep(2);
      } else if (_step == 2 && game.selectedNumber == _rowTargetNumber) {
        setState(() => _step = 3);
        _applyConstraintsForStep(3);
      } else if (_step == 3 && game.board[_rowTargetRow][_rowTargetCol] == _rowTargetNumber) {
        setState(() => _step = 4);
        _applyConstraintsForStep(4);
      } else if (_step == 6 && game.selectedNumber == _colTargetNumber) {
        setState(() => _step = 7);
        _applyConstraintsForStep(7);
      } else if (_step == 7 && game.board[_colTargetRow][_colTargetCol] == _colTargetNumber) {
        setState(() {
          _step = 8;
          _showCompletion = true;
        });
        final g = context.read<SudokuGame>();
        g.setTutorialConstraints(clearSelection: true);
      } else if (_step == 10 && game.selectedNumber == _boxTargetNumber) {
        setState(() => _step = 11);
        _applyConstraintsForStep(11);
      } else if (_step == 11 && game.board[_boxTargetRow][_boxTargetCol] == _boxTargetNumber) {
        setState(() {
          _step = 12;
          _showCompletion = true;
        });
        final g = context.read<SudokuGame>();
        g.setTutorialConstraints();
      }
    });
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Text(
              _step <= 4 ? l10n.tutorialRowRule : (_step <= 7 ? l10n.tutorialColRule : l10n.tutorialBoxRule),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_step) {
      case 0:
        return _buildTooltip(
          message: l10n.tutorialStep0Message,
          sub: l10n.tutorialStep0Sub,
          buttonLabel: l10n.tutorialGotIt,
          onButton: _nextStep,
        );
      case 1:
        return _buildGuideWithArrow(l10n.tutorialTapSmartButton);
      case 2:
        return _buildNumberGuide(l10n.tutorialTapNumber);
      case 3:
        return _buildCellTargetGuide(l10n.tutorialTapCell);
      case 4:
        return _buildTooltip(
          message: l10n.tutorialStep4Message,
          sub: l10n.tutorialStep4Sub,
          buttonLabel: l10n.tutorialNext,
          onButton: _nextStep,
        );
      case 5:
        return _buildTooltip(
          message: l10n.tutorialStep5Message,
          sub: l10n.tutorialStep5Sub,
          buttonLabel: l10n.tutorialGotIt,
          onButton: _nextStep,
        );
      case 6:
        return _buildNumberGuide(l10n.tutorialTapNumber, targetButtonIndex: 2);
      case 7:
        return _buildCellArrowGuide(l10n.tutorialTapCell, _colTargetRow, _colTargetCol);
      case 8:
        return const SizedBox.shrink();
      case 9:
        return _buildTooltip(
          message: l10n.tutorialStep9Message,
          sub: l10n.tutorialStep9Sub,
          buttonLabel: l10n.tutorialGotIt,
          onButton: _nextStep,
        );
      case 10:
        return _buildNumberGuide(l10n.tutorialTapNumber, targetButtonIndex: 5);
      case 11:
        return _buildCellArrowGuide(l10n.tutorialTapCell, _boxTargetRow, _boxTargetCol);
      default:
        return const SizedBox.shrink();
    }
  }

  // 툴팁 오버레이 (단계 설명 + 버튼)
  Widget _buildTooltip({
    required String message,
    required String sub,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    return Positioned(
      top: 70,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 숫자 버튼 위 말풍선
  Widget _buildNumberGuide(String message, {int targetButtonIndex = 0}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 셀 탭 안내 말풍선
  Widget _buildCellTargetGuide(String message) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const headerH = 42.0;
          const numPadH = 134.0;
          const bottomH = 8.0;
          final totalH = constraints.maxHeight;
          final totalW = constraints.maxWidth;
          final boardAreaH = totalH - headerH - numPadH - bottomH;
          final boardSize = (totalW * 0.95).clamp(0.0, 600.0);
          final boardOffsetY = ((boardAreaH - boardSize) / 2).clamp(0.0, double.infinity);
          final boardTop = headerH + boardOffsetY;
          final cellSize = boardSize / 9;

          final textTop = boardTop + cellSize * 0.5;

          return IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: textTop,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 스마트 버튼 안내 말풍선
  Widget _buildGuideWithArrow(String message) {
    return Positioned(
      top: 70,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // 보드 셀 탭 안내 말풍선 (상단 고정)
  Widget _buildCellArrowGuide(String message, int targetRow, int targetCol) {
    return Positioned(
      top: 70,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/smile.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sentiment_very_satisfied,
                    size: 80,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tutorialGreat,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 8 ? l10n.tutorialAllNumbers : l10n.tutorialBox3x3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tutorialSolvedMethod,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _step == 8 ? _onMidCompleteNext : _onFinishToGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _step == 8 ? l10n.tutorialNext : l10n.tutorialStartGame,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
