# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based Sudoku game application with multiple difficulty levels, game statistics tracking, sound effects, and Google Mobile Ads integration. The app supports both mobile (Android/iOS) and web platforms.

## Development Commands

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on web browser
flutter run -d windows         # Run on Windows desktop
```

### Building
```bash
flutter build apk              # Build Android APK
flutter build appbundle        # Build Android App Bundle
flutter build ios              # Build iOS app
flutter build web              # Build web app
```

### Testing & Maintenance
```bash
flutter test                   # Run tests
flutter analyze                # Analyze code for issues
flutter pub get                # Install dependencies
flutter clean                  # Clean build artifacts
```

### App Icon Generation
```bash
flutter pub run flutter_launcher_icons
```

## Architecture Overview

### State Management
- Uses **Provider** pattern for state management
- Main game state is in `SudokuGame` class (`lib/models/sudoku_game.dart`)
- `ChangeNotifier` updates UI reactively when game state changes

### Core Components

#### Models (`lib/models/`)
- **SudokuGame**: Main game controller with game logic, timer, hearts system, hint mode, and completion checking
  - Manages 9x9 board state, initial board, memos, and correct cells tracking
  - Handles game lifecycle: start, pause, resume, restart, save/load
  - Integrates with ads (banner, rewarded for hints)
  - Line completion animation system (row, column, box)

#### Data (`lib/data/`)
- **PuzzleData**: Contains all sudoku puzzles and solutions (large file ~920KB)
  - Organized by difficulty levels: beginner, rookie, easy, medium, hard
  - Each puzzle has corresponding solution array
  - Difficulty labels stored in `difficulties` list
  - Stage names stored in `stageNames` list

#### Screens (`lib/screens/`)
- **WelcomeScreen**: Entry point with difficulty selection
- **SudokuScreen**: Main gameplay screen with board, number pad, timer, hearts display
- **StatisticsScreen**: Shows game statistics per difficulty level

#### Widgets (`lib/widgets/`)
- **SudokuBoard**: 9x9 grid display with cell selection, highlighting, and animations
- **NumberPad**: Input control for entering numbers and memo mode

#### Utils (`lib/utils/`)
- **GameStorage**: Persists game state using SharedPreferences
  - Saves: board, initialBoard, memos, correctCells, hearts, hintsUsed, elapsedSeconds, completedLines
- **StatisticsStorage**: Tracks game statistics per difficulty
  - Metrics: gamesStarted, gamesWon, perfectWins, bestTime, totalTime, currentStreak, bestStreak
  - Difficulty keys: 'easy', 'medium', 'hard' (note: 'beginner' and 'rookie' may need mapping)
- **AdHelper**: Google Mobile Ads integration
  - Preloads interstitial and rewarded ads
  - Platform-specific ad unit IDs
- **SoundHelper**: Audio playback for correct/wrong sounds
- **PlayCounter**: Tracks play count for ad frequency control

### Data Flow

1. **Game Start**: `WelcomeScreen` → User selects difficulty → `loadStage()` in `SudokuGame`
2. **Gameplay**: User interacts with `SudokuBoard` → `selectCell()` → `setNumber()` → Updates board state → `notifyListeners()`
3. **Validation**: Each number entry checks against solution → Updates `correctCells` → Checks line completions → Triggers animations
4. **Persistence**: After each valid move → `saveGame()` → SharedPreferences
5. **Completion**: `_checkIfComplete()` → Records statistics → Shows completion dialog
6. **Statistics**: Game events (start, win) → `StatisticsStorage.record*()` → Persisted to SharedPreferences

### Key Features

- **Hearts System**: 3 lives, lose one per wrong answer, game over at 0
- **Hint Mode**: Watch rewarded ad to reveal correct answer for selected cell
- **Memo Mode**: Toggle to enter/remove candidate numbers in cells
- **Timer**: Tracks elapsed time with pause/resume capability
- **Line Completion Animation**: Visual feedback when row/column/box completes
- **Game Persistence**: Auto-save after each move, resume on app restart
- **Statistics Tracking**: Per-difficulty stats including win rate, streaks, best time
- **Sound Effects**: Correct/wrong answer audio feedback

### Difficulty System

The game supports 5 difficulty levels in this order:
- **beginner** (입문자) - Puzzles 1-3
- **rookie** (초보자) - Puzzles 4-6
- **easy** - Puzzles 7-9
- **medium** - Puzzles 10-12
- **hard** - Puzzles 13-15

Note: Statistics storage currently only has keys for 'easy', 'medium', 'hard'. When adding beginner/rookie support, update `StatisticsStorage._getKey()` to map these difficulties appropriately.

## Platform Considerations

- **Web**: Ads are disabled (`kIsWeb` check)
- **Mobile**: Full ad integration with Google Mobile Ads SDK
- **Assets**: Icon and sound files in `assets/` directory

## Important Files to Know

- `lib/main.dart`: App entry point, Provider setup
- `lib/models/sudoku_game.dart`: Core game logic (517 lines)
- `lib/data/puzzle_data.dart`: All puzzle data (very large file, read with offset/limit)
- `lib/utils/game_storage.dart`: Game save/load implementation
- `lib/utils/statistics_storage.dart`: Statistics persistence
- `pubspec.yaml`: Dependencies and asset declarations
