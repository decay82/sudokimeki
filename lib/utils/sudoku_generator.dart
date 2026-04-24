import 'dart:math';

// ─────────────────────────────────────────────
// SEED 데이터 (완성된 스도쿠 5개)
// ─────────────────────────────────────────────
const List<List<List<int>>> _seeds = [
  [
    [5,6,2,8,9,1,7,3,4],
    [7,4,8,6,2,3,1,9,5],
    [1,3,9,7,4,5,2,8,6],
    [4,9,7,3,8,6,5,2,1],
    [3,2,1,9,5,7,6,4,8],
    [8,5,6,2,1,4,9,7,3],
    [9,7,3,5,6,8,4,1,2],
    [2,1,5,4,3,9,8,6,7],
    [6,8,4,1,7,2,3,5,9],
  ],
  [
    [8,4,7,3,9,2,1,6,5],
    [5,6,3,7,4,1,8,2,9],
    [2,9,1,8,6,5,3,7,4],
    [9,7,2,5,3,6,4,8,1],
    [3,1,6,2,8,4,9,5,7],
    [4,8,5,9,1,7,2,3,6],
    [6,2,8,1,5,9,7,4,3],
    [7,5,9,4,2,3,6,1,8],
    [1,3,4,6,7,8,5,9,2],
  ],
  [
    [2,9,4,3,1,7,5,6,8],
    [5,3,1,9,8,6,4,2,7],
    [6,7,8,2,4,5,1,3,9],
    [9,4,7,5,3,1,2,8,6],
    [1,5,2,6,9,8,7,4,3],
    [8,6,3,7,2,4,9,5,1],
    [4,2,6,1,7,3,8,9,5],
    [3,1,9,8,5,2,6,7,4],
    [7,8,5,4,6,9,3,1,2],
  ],
  [
    [3,7,2,9,5,4,8,6,1],
    [8,1,9,6,2,7,4,5,3],
    [5,6,4,8,3,1,9,7,2],
    [7,9,3,4,6,8,1,2,5],
    [4,8,5,7,1,2,3,9,6],
    [6,2,1,3,9,5,7,8,4],
    [1,4,8,5,7,6,2,3,9],
    [9,5,7,2,4,3,6,1,8],
    [2,3,6,1,8,9,5,4,7],
  ],
  [
    [7,8,5,6,2,1,9,3,4],
    [2,1,9,8,3,4,5,7,6],
    [6,3,4,7,9,5,1,8,2],
    [3,9,6,5,7,2,4,1,8],
    [5,7,2,1,4,8,6,9,3],
    [8,4,1,3,6,9,2,5,7],
    [1,5,7,4,8,6,3,2,9],
    [4,2,3,9,5,7,8,6,1],
    [9,6,8,2,1,3,7,4,5],
  ],
];

// ─────────────────────────────────────────────
// 난이도 설정
// ─────────────────────────────────────────────
enum SudokuDifficulty { beginner, easy, normal, hard }

class _DifficultyConfig {
  final int minEmpty;
  final int maxEmpty;
  final bool allowHiddenSingle;
  const _DifficultyConfig(this.minEmpty, this.maxEmpty, this.allowHiddenSingle);
}

const Map<SudokuDifficulty, _DifficultyConfig> _config = {
  SudokuDifficulty.beginner: _DifficultyConfig(10, 16, false),
  SudokuDifficulty.easy:     _DifficultyConfig(25, 32, false),
  SudokuDifficulty.normal:   _DifficultyConfig(35, 41, true),
  SudokuDifficulty.hard:     _DifficultyConfig(42, 56, true),
};

// ─────────────────────────────────────────────
// 공개 API
// ─────────────────────────────────────────────
class SudokuGenerator {
  static final Random _rng = Random();

  /// 난이도에 맞는 퍼즐 생성. 반환값: {'puzzle': ..., 'solution': ...}
  static Map<String, List<List<int>>> generate(SudokuDifficulty difficulty) {
    final cfg = _config[difficulty]!;
    final targetEmpty =
        cfg.minEmpty + _rng.nextInt(cfg.maxEmpty - cfg.minEmpty + 1);

    for (int attempt = 0; attempt < 100; attempt++) {
      final seed = _seeds[_rng.nextInt(_seeds.length)];
      final solution = _applyTransforms(seed);
      final puzzle = _makePuzzle(solution, targetEmpty, cfg.allowHiddenSingle);
      if (puzzle != null) {
        return {'puzzle': puzzle, 'solution': solution};
      }
    }
    // 100회 실패 시 beginner 수준으로 폴백
    final seed = _seeds[_rng.nextInt(_seeds.length)];
    final solution = _applyTransforms(seed);
    return {
      'puzzle': _makePuzzle(solution, cfg.minEmpty, false) ??
          _forcePuzzle(solution, cfg.minEmpty),
      'solution': solution,
    };
  }

  /// difficulty 문자열 → enum 변환
  static SudokuDifficulty difficultyFromString(String s) {
    switch (s) {
      case 'beginner': return SudokuDifficulty.beginner;
      case 'easy':     return SudokuDifficulty.easy;
      case 'normal':   return SudokuDifficulty.normal;
      case 'hard':     return SudokuDifficulty.hard;
      default:         return SudokuDifficulty.beginner;
    }
  }
}

// ─────────────────────────────────────────────
// 변형 알고리즘
// ─────────────────────────────────────────────
List<List<int>> _applyTransforms(List<List<int>> seed) {
  var board = _deepCopy(seed);

  // 1. 숫자 재배열
  final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(SudokuGenerator._rng);
  board = board
      .map((row) => row.map((v) => v == 0 ? 0 : digits[v - 1]).toList())
      .toList();

  // 2. 가로 밴드 행 교환
  final bandOrder = [0, 1, 2]..shuffle(SudokuGenerator._rng);
  final newBoard = List.generate(9, (_) => List.filled(9, 0));
  for (int b = 0; b < 3; b++) {
    final srcBand = bandOrder[b];
    final rowOrder = [0, 1, 2]..shuffle(SudokuGenerator._rng);
    for (int r = 0; r < 3; r++) {
      newBoard[b * 3 + r] = List.from(board[srcBand * 3 + rowOrder[r]]);
    }
  }
  board = newBoard;

  // 3. 세로 밴드 열 교환
  final colBandOrder = [0, 1, 2]..shuffle(SudokuGenerator._rng);
  final colBoard = List.generate(9, (_) => List.filled(9, 0));
  for (int b = 0; b < 3; b++) {
    final srcBand = colBandOrder[b];
    final colOrder = [0, 1, 2]..shuffle(SudokuGenerator._rng);
    for (int c = 0; c < 3; c++) {
      for (int r = 0; r < 9; r++) {
        colBoard[r][b * 3 + c] = board[r][srcBand * 3 + colOrder[c]];
      }
    }
  }
  board = colBoard;

  // 4. 회전 (0/90/180/270도)
  final rotations = SudokuGenerator._rng.nextInt(4);
  for (int i = 0; i < rotations; i++) {
    board = _rotate90(board);
  }

  // 5. 좌우 대칭
  if (SudokuGenerator._rng.nextBool()) {
    board = board.map((row) => row.reversed.toList()).toList();
  }

  // 6. 상하 대칭
  if (SudokuGenerator._rng.nextBool()) {
    board = board.reversed.toList();
  }

  return board;
}

List<List<int>> _rotate90(List<List<int>> board) {
  final n = board.length;
  return List.generate(
    n,
    (r) => List.generate(n, (c) => board[n - 1 - c][r]),
  );
}

// ─────────────────────────────────────────────
// 숫자 제거 로직
// ─────────────────────────────────────────────
List<List<int>>? _makePuzzle(
  List<List<int>> solution,
  int targetEmpty,
  bool allowHiddenSingle,
) {
  final puzzle = _deepCopy(solution);
  final cells = List.generate(81, (i) => [i ~/ 9, i % 9])
    ..shuffle(SudokuGenerator._rng);

  int removed = 0;
  for (final cell in cells) {
    if (removed >= targetEmpty) break;
    final r = cell[0], c = cell[1];
    final backup = puzzle[r][c];
    puzzle[r][c] = 0;

    if (_canSolve(puzzle, allowHiddenSingle)) {
      removed++;
    } else {
      puzzle[r][c] = backup;
    }
  }

  // 목표의 90% 이상 달성하면 성공
  return removed >= (targetEmpty * 0.9).ceil() ? puzzle : null;
}

// 폴백: 솔버 검증 없이 강제 제거 (100회 실패 시 사용)
List<List<int>> _forcePuzzle(List<List<int>> solution, int targetEmpty) {
  final puzzle = _deepCopy(solution);
  final cells = List.generate(81, (i) => [i ~/ 9, i % 9])
    ..shuffle(SudokuGenerator._rng);
  int removed = 0;
  for (final cell in cells) {
    if (removed >= targetEmpty) break;
    puzzle[cell[0]][cell[1]] = 0;
    removed++;
  }
  return puzzle;
}

// ─────────────────────────────────────────────
// 논리 솔버
// ─────────────────────────────────────────────
bool _canSolve(List<List<int>> puzzle, bool allowHiddenSingle) {
  final board = _deepCopy(puzzle);
  for (int iter = 0; iter < 200; iter++) {
    if (_isComplete(board)) return true;
    if (_hasContradiction(board)) return false;
    if (_applyNakedSingle(board)) continue;
    if (allowHiddenSingle && _applyHiddenSingle(board)) continue;
    return false; // 더 이상 진행 불가 = Bifurcation 필요
  }
  return _isComplete(board);
}

bool _isComplete(List<List<int>> board) {
  for (final row in board) {
    for (final v in row) {
      if (v == 0) return false;
    }
  }
  return true;
}

bool _hasContradiction(List<List<int>> board) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] == 0 && _getCandidates(board, r, c).isEmpty) return true;
    }
  }
  return false;
}

bool _applyNakedSingle(List<List<int>> board) {
  bool applied = false;
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (board[r][c] != 0) continue;
      final candidates = _getCandidates(board, r, c);
      if (candidates.length == 1) {
        board[r][c] = candidates.first;
        applied = true;
      }
    }
  }
  return applied;
}

bool _applyHiddenSingle(List<List<int>> board) {
  bool applied = false;

  // 행 검사
  for (int r = 0; r < 9; r++) {
    for (int n = 1; n <= 9; n++) {
      final positions = <int>[];
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0 && _getCandidates(board, r, c).contains(n)) {
          positions.add(c);
        }
      }
      if (positions.length == 1) {
        board[r][positions[0]] = n;
        applied = true;
      }
    }
  }

  // 열 검사
  for (int c = 0; c < 9; c++) {
    for (int n = 1; n <= 9; n++) {
      final positions = <int>[];
      for (int r = 0; r < 9; r++) {
        if (board[r][c] == 0 && _getCandidates(board, r, c).contains(n)) {
          positions.add(r);
        }
      }
      if (positions.length == 1) {
        board[positions[0]][c] = n;
        applied = true;
      }
    }
  }

  // 박스 검사
  for (int br = 0; br < 3; br++) {
    for (int bc = 0; bc < 3; bc++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <List<int>>[];
        for (int r = br * 3; r < br * 3 + 3; r++) {
          for (int c = bc * 3; c < bc * 3 + 3; c++) {
            if (board[r][c] == 0 && _getCandidates(board, r, c).contains(n)) {
              positions.add([r, c]);
            }
          }
        }
        if (positions.length == 1) {
          board[positions[0][0]][positions[0][1]] = n;
          applied = true;
        }
      }
    }
  }

  return applied;
}

Set<int> _getCandidates(List<List<int>> board, int row, int col) {
  final used = <int>{};
  // 행
  for (int c = 0; c < 9; c++) { used.add(board[row][c]); }
  // 열
  for (int r = 0; r < 9; r++) { used.add(board[r][col]); }
  // 박스
  final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
  for (int r = br; r < br + 3; r++) {
    for (int c = bc; c < bc + 3; c++) {
      used.add(board[r][c]);
    }
  }
  return {1, 2, 3, 4, 5, 6, 7, 8, 9}.difference(used);
}

// ─────────────────────────────────────────────
// 유틸
// ─────────────────────────────────────────────
List<List<int>> _deepCopy(List<List<int>> board) =>
    board.map((row) => List<int>.from(row)).toList();
