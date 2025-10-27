# 국제화(i18n) 구현 가이드

## 완료된 작업

### ✅ 1. 기본 설정 완료
- `pubspec.yaml`에 `flutter_localizations`와 `intl` 패키지 추가
- `l10n.yaml` 설정 파일 생성
- `lib/l10n/app_en.arb` (영어 번역) 생성
- `lib/l10n/app_ko.arb` (한국어 번역) 생성
- `lib/l10n/app_localizations.dart` 자동 생성됨

### ✅ 2. 메인 앱 설정
- `lib/main.dart`에 국제화 설정 추가
- 한국어(ko)와 영어(en) 지원

### ✅ 3. 헬퍼 함수 생성
- `lib/utils/localization_helper.dart` 생성
  - `getDifficultyName()`: 난이도 이름 번역
  - `getDifficultyDescription()`: 난이도 설명 번역
  - `getDayName()`: 요일 이름 번역

## 사용 방법

### 화면에서 번역된 텍스트 사용하기

```dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics), // "통계" 또는 "Statistics"
      ),
      body: Column(
        children: [
          Text(l10n.difficultyBeginner), // "입문자" 또는 "Beginner"
          Text(l10n.gamesStarted), // "시작한 게임" 또는 "Games Started"
        ],
      ),
    );
  }
}
```

### 헬퍼 함수 사용하기

```dart
import '../utils/localization_helper.dart';

// 난이도 이름 가져오기
String diffName = getDifficultyName(context, 'beginner'); // "입문자" 또는 "Beginner"

// 난이도 설명 가져오기
String diffDesc = getDifficultyDescription(context, 'easy'); // "Easy - 쉬운 난이도" 또는 "Easy - Easy level"

// 요일 이름 가져오기 (1=월요일, 7=일요일)
String dayName = getDayName(context, 1); // "월" 또는 "Mon"
```

## 번역 키 목록

### 난이도
- `difficultyBeginner` - 입문자 / Beginner
- `difficultyRookie` - 초보자 / Rookie
- `difficultyEasy` - 초급 / Easy
- `difficultyMedium` - 중급 / Medium
- `difficultyHard` - 고급 / Hard

### 환영 화면
- `selectDifficulty` - 난이도 선택 / Select Difficulty
- `newGame` - 새로 시작 / New Game
- `continueGame` - 이어서 하기 / Continue
- `noSavedGame` - 저장된 게임 없음 / No Saved Game
- `cancel` - 취소 / Cancel

### 통계
- `statistics` - 통계 / Statistics
- `gamesStarted` - 시작한 게임 / Games Started
- `gamesWon` - 승리한 게임 / Games Won
- `winRate` - 승률 / Win Rate
- `perfectWins` - 실수 없이 승리 / Perfect Wins
- `bestTime` - 최고 시간 / Best Time
- `currentStreak` - 현재 연승 / Current Streak

### 일일 미션
- `dailyMission` - 일일 미션 / Daily Mission
- `completedMission` - 완료된 미션 / Completed Mission
- `clearTime` - 클리어 시간 / Clear Time
- `play` - 플레이 / Play

### 랭킹
- `ranking` - 랭킹 / Ranking
- `rankingHistory` - 랭킹 히스토리 / Ranking History

### 버튼/기능
- `smart` - 스마트 / Smart
- `memo` - 메모 / Memo
- `hint` - 힌트 / Hint
- `delete` - 삭제 / Delete

## 다음 단계: 코드에 번역 적용하기

각 화면 파일에서 하드코딩된 한글 텍스트를 `AppLocalizations`로 교체해야 합니다:

### 예시: welcome_screen.dart 수정

**변경 전:**
```dart
Text('난이도 선택')
```

**변경 후:**
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.selectDifficulty)
```

**변경 전:**
```dart
String difficultyText = '입문자';
```

**변경 후:**
```dart
String difficultyText = getDifficultyName(context, 'beginner');
```

## 수정이 필요한 주요 파일들

1. ✅ `lib/main.dart` - 완료
2. ⏳ `lib/screens/welcome_screen.dart`
3. ⏳ `lib/screens/statistics_screen.dart`
4. ⏳ `lib/screens/daily_mission_screen.dart`
5. ⏳ `lib/screens/ranking_screen.dart`
6. ⏳ `lib/screens/ranking_history_screen.dart`
7. ⏳ `lib/widgets/number_pad.dart`
8. ⏳ `lib/widgets/function_buttons.dart`
9. ⏳ `lib/utils/difficulty_unlock_storage.dart`

## 언어 변경 테스트

앱은 기기의 언어 설정을 자동으로 따릅니다:
- 기기 언어가 한국어면 → 한국어로 표시
- 기기 언어가 영어면 → 영어로 표시
- 기타 언어면 → 영어로 표시 (기본값)

### 수동으로 언어 변경하려면

`lib/main.dart`에서 `locale` 속성을 추가:

```dart
MaterialApp(
  locale: const Locale('en'), // 강제로 영어
  // 또는
  locale: const Locale('ko'), // 강제로 한국어
  localizationsDelegates: const [...],
  supportedLocales: const [...],
  ...
)
```

## 새 번역 추가하기

1. `lib/l10n/app_en.arb`에 영어 번역 추가:
```json
"myNewKey": "My New Text"
```

2. `lib/l10n/app_ko.arb`에 한국어 번역 추가:
```json
"myNewKey": "내 새 텍스트"
```

3. 코드 재생성:
```bash
flutter pub get
```

4. 코드에서 사용:
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.myNewKey)
```

## 매개변수가 있는 번역

ARB 파일에서:
```json
"welcomeMessage": "Hello, {name}!",
"@welcomeMessage": {
  "placeholders": {
    "name": {
      "type": "String"
    }
  }
}
```

코드에서:
```dart
l10n.welcomeMessage('John')  // "Hello, John!"
```
