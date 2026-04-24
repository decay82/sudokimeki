# 스도쿠 문제 생성기 Dart 구현 명세서

## 개요

완성된 스도쿠 퍼즐(SEED)을 변형 알고리즘으로 새로운 완성 퍼즐을 만들고,
논리 솔버로 검증하면서 숫자를 제거해 난이도별 퍼즐을 생성한다.
외부 API 의존 없이 앱 내에서 완전히 동작해야 한다.

---

## 전체 흐름

```
SEED 풀에서 랜덤 1개 선택
→ 변형 알고리즘 적용 → 새로운 완성 퍼즐 생성
→ 난이도에 따라 목표 빈 칸 수 결정
→ 숫자 하나씩 제거 + 논리 솔버 검증 반복
→ 목표 빈 칸 수 달성 → 퍼즐 반환
→ 실패 시 while loop로 재시도 (최대 100회)
```

---

## 1. SEED 데이터

완성된 스도쿠 퍼즐 5개. 각각 9x9 행렬.

```dart
const List<List<List<int>>> sudokuSeeds = [
  // SEED 1
  [
    [5,6,2,8,9,1,7,3,4],
    [7,4,8,6,2,3,1,9,5],
    [1,3,9,7,4,5,2,8,6],
    [4,9,7,3,8,6,5,2,1],
    [3,2,1,9,5,7,6,4,8],
    [8,5,6,2,1,4,9,7,3],
    [9,7,3,5,6,8,4,1,2],
    [2,1,5,4,3,9,8,6,7],
    [6,8,4,1,7,2,3,5,9]
  ],
  // SEED 2
  [
    [8,4,7,3,9,2,1,6,5],
    [5,6,3,7,4,1,8,2,9],
    [2,9,1,8,6,5,3,7,4],
    [9,7,2,5,3,6,4,8,1],
    [3,1,6,2,8,4,9,5,7],
    [4,8,5,9,1,7,2,3,6],
    [6,2,8,1,5,9,7,4,3],
    [7,5,9,4,2,3,6,1,8],
    [1,3,4,6,7,8,5,9,2]
  ],
  // SEED 3
  [
    [2,9,4,3,1,7,5,6,8],
    [5,3,1,9,8,6,4,2,7],
    [6,7,8,2,4,5,1,3,9],
    [9,4,7,5,3,1,2,8,6],
    [1,5,2,6,9,8,7,4,3],
    [8,6,3,7,2,4,9,5,1],
    [4,2,6,1,7,3,8,9,5],
    [3,1,9,8,5,2,6,7,4],
    [7,8,5,4,6,9,3,1,2]
  ],
  // SEED 4
  [
    [3,7,2,9,5,4,8,6,1],
    [8,1,9,6,2,7,4,5,3],
    [5,6,4,8,3,1,9,7,2],
    [7,9,3,4,6,8,1,2,5],
    [4,8,5,7,1,2,3,9,6],
    [6,2,1,3,9,5,7,8,4],
    [1,4,8,5,7,6,2,3,9],
    [9,5,7,2,4,3,6,1,8],
    [2,3,6,1,8,9,5,4,7]
  ],
  // SEED 5
  [
    [7,8,5,6,2,1,9,3,4],
    [2,1,9,8,3,4,5,7,6],
    [6,3,4,7,9,5,1,8,2],
    [3,9,6,5,7,2,4,1,8],
    [5,7,2,1,4,8,6,9,3],
    [8,4,1,3,6,9,2,5,7],
    [1,5,7,4,8,6,3,2,9],
    [4,2,3,9,5,7,8,6,1],
    [9,6,8,2,1,3,7,4,5]
  ],
];
```

---

## 2. 난이도 설정

| 난이도 | 빈 칸 범위 | 허용 솔버 기법 |
|--------|-----------|--------------|
| 비기너 | 10 ~ 16 | Naked Single |
| 루키   | 25 ~ 32 | Naked Single |
| 이지   | 35 ~ 41 | Naked Single + Hidden Single |
| 미디엄 | 42 ~ 56 | Naked Single + Hidden Single |
| 하드   | 57 ~ 64 | Naked Single + Hidden Single |

빈 칸 수는 해당 범위에서 랜덤으로 결정한다.

```dart
enum SudokuDifficulty { beginner, rookie, easy, medium, hard }

class DifficultyConfig {
  final int minEmpty;
  final int maxEmpty;
  final bool allowHiddenSingle;

  const DifficultyConfig({
    required this.minEmpty,
    required this.maxEmpty,
    required this.allowHiddenSingle,
  });
}

const Map<SudokuDifficulty, DifficultyConfig> difficultyConfig = {
  SudokuDifficulty.beginner: DifficultyConfig(minEmpty: 10, maxEmpty: 16, allowHiddenSingle: false),
  SudokuDifficulty.rookie:   DifficultyConfig(minEmpty: 25, maxEmpty: 32, allowHiddenSingle: false),
  SudokuDifficulty.easy:     DifficultyConfig(minEmpty: 35, maxEmpty: 41, allowHiddenSingle: true),
  SudokuDifficulty.medium:   DifficultyConfig(minEmpty: 42, maxEmpty: 56, allowHiddenSingle: true),
  SudokuDifficulty.hard:     DifficultyConfig(minEmpty: 57, maxEmpty: 64, allowHiddenSingle: true),
};
```

---

## 3. 변형 알고리즘

하나의 SEED에서 아래 변형을 랜덤 적용해 새로운 완성 퍼즐을 만든다.
변형 후에도 스도쿠 규칙은 항상 유지된다.

적용 순서:

### 3-1. 숫자 재배열
1~9를 랜덤 순열로 1:1 교환한다.
예: [3,1,4,1,5,9,2,6,5] 순열이면 원래 1→3, 2→1, 3→4 ...

### 3-2. 가로 밴드 행 교환
9행을 3개씩 묶은 밴드(0~2행, 3~5행, 6~8행) 순서를 랜덤 교환.
각 밴드 내부의 3개 행도 랜덤 교환.
단, 다른 밴드끼리의 행 교환은 불가.

### 3-3. 세로 밴드 열 교환
9열을 3개씩 묶은 밴드(0~2열, 3~5열, 6~8열) 순서를 랜덤 교환.
각 밴드 내부의 3개 열도 랜덤 교환.

### 3-4. 회전
0도, 90도, 180도, 270도 중 랜덤 적용.

### 3-5. 대칭
좌우 대칭: 50% 확률로 적용.
상하 대칭: 50% 확률로 적용.

---

## 4. 논리 솔버

숫자 제거 시 검증에 사용. Bifurcation(찍기) 없이 논리만으로 풀리는지 확인한다.

### Naked Single
특정 칸의 후보 숫자가 1개만 남은 경우 확정.

```
후보 수 = 1~9 중 같은 행/열/박스에 없는 숫자
후보가 1개면 → 그 숫자로 확정
```

### Hidden Single
특정 행/열/박스에서 어떤 숫자가 들어갈 수 있는 칸이 1개뿐인 경우 확정.

```
각 행/열/박스를 순회
특정 숫자 n이 들어갈 수 있는 빈 칸이 1개뿐이면 → 그 칸을 n으로 확정
```

### 솔버 동작 방식

```dart
bool canSolve(List<List<int>> puzzle, bool allowHiddenSingle) {
  final board = deepCopy(puzzle);
  int iter = 0;
  while (iter++ < 200) {
    if (isComplete(board)) return true;
    if (hasContradiction(board)) return false; // 후보 0개인 빈 칸 존재
    if (applyNakedSingle(board)) continue;
    if (allowHiddenSingle && applyHiddenSingle(board)) continue;
    return false; // 더 이상 진행 불가 = Bifurcation 필요
  }
  return isComplete(board);
}
```

---

## 5. 숫자 제거 로직

```dart
Map<String, dynamic>? makePuzzle(
  List<List<int>> solution,
  int targetEmpty,
  bool allowHiddenSingle,
) {
  final puzzle = deepCopy(solution);
  
  // 81칸 인덱스를 랜덤 순서로 섞기
  final cells = List.generate(81, (i) => [i ~/ 9, i % 9])..shuffle();
  
  int removed = 0;
  for (final cell in cells) {
    if (removed >= targetEmpty) break;
    final r = cell[0], c = cell[1];
    final backup = puzzle[r][c];
    puzzle[r][c] = 0;
    
    if (canSolve(puzzle, allowHiddenSingle)) {
      removed++; // 검증 통과 → 제거 유지
    } else {
      puzzle[r][c] = backup; // 검증 실패 → 복원
    }
  }
  
  // 최소 빈 칸 수 달성 여부 확인
  if (removed >= targetEmpty * 0.9) {
    return {'puzzle': puzzle, 'solution': solution, 'removed': removed};
  }
  return null; // 실패
}
```

---

## 6. 메인 생성 함수

실패 시 while loop로 재시도. 최대 100회.

```dart
Map<String, dynamic> generatePuzzle(SudokuDifficulty difficulty) {
  final config = difficultyConfig[difficulty]!;
  final random = Random();
  
  // 빈 칸 수 랜덤 결정
  final targetEmpty = config.minEmpty +
      random.nextInt(config.maxEmpty - config.minEmpty + 1);
  
  int attempts = 0;
  while (attempts++ < 100) {
    // SEED 랜덤 선택
    final seed = sudokuSeeds[random.nextInt(sudokuSeeds.length)];
    
    // 변형 적용
    final solution = applyTransforms(seed);
    
    // 숫자 제거 + 검증
    final result = makePuzzle(solution, targetEmpty, config.allowHiddenSingle);
    
    if (result != null) return result;
  }
  
  // 100회 실패 시 난이도를 한 단계 낮춰서 재시도 (예외 처리)
  throw Exception('퍼즐 생성 실패: $difficulty');
}
```

---

## 7. 반환 데이터 구조

```dart
{
  'puzzle': List<List<int>>,   // 빈 칸(0)이 포함된 문제
  'solution': List<List<int>>, // 완성된 정답
  'removed': int,              // 실제 제거된 칸 수
}
```

빈 칸은 0으로 표현한다.

---

## 8. 유틸 함수 목록

구현이 필요한 유틸 함수들.

```dart
// 2차원 배열 깊은 복사
List<List<int>> deepCopy(List<List<int>> board)

// 퍼즐 완성 여부 (빈 칸 없음)
bool isComplete(List<List<int>> board)

// 모순 여부 (후보가 0개인 빈 칸 존재)
bool hasContradiction(List<List<int>> board)

// 특정 칸의 후보 숫자 집합 반환
Set<int> getCandidates(List<List<int>> board, int row, int col)

// Naked Single 1회 적용 (적용됐으면 true)
bool applyNakedSingle(List<List<int>> board)

// Hidden Single 1회 적용 (적용됐으면 true)
bool applyHiddenSingle(List<List<int>> board)

// 변형 알고리즘 적용 후 새로운 완성 퍼즐 반환
List<List<int>> applyTransforms(List<List<int>> seed)

// 90도 회전
List<List<int>> rotate90(List<List<int>> board)
```

---

## 주의사항

- `deepCopy` 필수: 솔버 검증 시 원본 board를 변형하면 안 됨
- `canSolve` 내부에서 반드시 deepCopy한 board로 작업할 것
- 변형 알고리즘은 항상 스도쿠 규칙을 유지함 (검증 불필요)
- 생성 실패(100회 초과)는 실제로 거의 발생하지 않음
  - 비기너/루키는 거의 즉시 성공
  - 미디엄/하드는 평균 5~20회 시도로 성공
