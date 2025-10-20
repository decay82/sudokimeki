# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based Sudoku game application with multiple difficulty levels, game statistics tracking, sound effects, daily missions, and Google Mobile Ads integration. The app supports both mobile (Android/iOS) and web platforms.

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
- **SudokuGame**: Main game controller (ChangeNotifier) with game logic, timer, hearts system, hint mode, and completion checking
  - Manages 9x9 board state, initial board, memos, correct cells tracking, and conflicting cells
  - Cell selection tracking (`selectedRow`, `selectedCol`)
  - Mode toggles: `isMemoMode`, `isSmartInputMode`, `isHintMode`
  - Handles game lifecycle: start, pause, resume, restart, save/load
  - Key methods: `loadStage()`, `loadSavedGame()`, `loadDailyMissionProgress()`, `setNumber()`, `selectCell()`, `useHint()`
  - Integrates with ads (banner, rewarded for hints)
  - Line completion animation system (row, column, box) with `isCellAnimating()` checks
  - Daily mission support with specialized loading methods

#### Data (`lib/data/`)
- **PuzzleData**: Contains all sudoku puzzles and solutions (large file ~920KB)
  - Organized by difficulty levels: beginner, rookie, easy, medium, hard
  - Each puzzle has corresponding solution array
  - Difficulty labels stored in `difficulties` list
  - Stage names stored in `stageNames` list
  - Static method `getPuzzlesByDifficulty()` for filtering puzzles

#### Screens (`lib/screens/`)
- **MainScreen**: Bottom navigation container with 3 tabs (home, daily mission, statistics)
- **WelcomeScreen**: Entry point with difficulty selection and "continue game" functionality
- **SudokuScreen**: Main gameplay screen with board, number pad, timer, hearts display
  - Supports both regular games and daily missions via constructor parameters
  - Handles completion/game over dialogs
  - Heart animation overlay with flying effect
- **DailyMissionScreen**: Monthly calendar view with mission status tracking
  - Shows trophy when all missions in a month are completed
  - Supports navigation between months (starting from 2025/10)
  - Ad display for past date replays
- **StatisticsScreen**: Shows game statistics per difficulty level
- **CollectionScreen**: Trophy collection display

#### Widgets (`lib/widgets/`)
- **SudokuBoard**: 9x9 grid display with cell selection, multi-type highlighting (selected, same number, same row/col/box, conflicting, smart mode, animating), and drag gesture support
- **NumberPad**: Input control with function buttons (Smart, Memo, Delete, Hint) and number buttons (1-9) showing remaining counts
- **FunctionButtons**: Utility buttons for game modes
- **NumberButtons**: Number input grid (1-9)

#### Utils (`lib/utils/`)
- **GameStorage**: Persists game state using SharedPreferences
  - Saves: board, initialBoard, memos, correctCells, hearts, hintsUsed, elapsedSeconds, completedLines
- **StatisticsStorage**: Tracks game statistics per difficulty
  - Metrics: gamesStarted, gamesWon, perfectWins, bestTime, totalTime, currentStreak, bestStreak
  - Difficulty keys: 'beginner', 'rookie', 'easy', 'medium', 'hard'
- **DailyMissionStorage**: Manages daily mission data persistence
  - Tracks mission status: locked, available, inProgress, completed
  - Saves mission progress and completion times
  - Trophy system for completed months
- **AdHelper**: Google Mobile Ads integration
  - Preloads interstitial and rewarded ads
  - Platform-specific ad unit IDs
- **SoundHelper**: Audio playback for correct/wrong sounds
- **PlayCounter**: Tracks play count for ad frequency control (shows ads after 3 plays)

### Data Flow

1. **Game Start**: `MainScreen` → `WelcomeScreen` → User selects difficulty → `loadStage()` in `SudokuGame`
2. **Gameplay**: User interacts with `SudokuBoard` → `selectCell()` → `setNumber()` → Updates board state → `notifyListeners()`
3. **Validation**: Each number entry checks against solution → Updates `correctCells` → Checks line completions → Triggers animations
4. **Persistence**: After each valid move → `saveGame()` → SharedPreferences
5. **Completion**: `_checkIfComplete()` → Records statistics → Shows completion dialog
6. **Statistics**: Game events (start, win) → `StatisticsStorage.record*()` → Persisted to SharedPreferences
7. **Daily Missions**: Calendar selection → Mission status check → Launch game or resume progress → Completion updates mission data

### Key Features

- **Hearts System**: 3 lives, lose one per wrong answer, game over at 0 (rewarded ad can restore 1 heart)
- **Hint Mode**: Watch rewarded ad to reveal correct answer for selected cell
- **Memo Mode**: Toggle to enter/remove candidate numbers (1-9) in cells, displayed in 3x3 grid
- **Smart Input Mode**: Select number first, then tap/drag cells to populate (works with both numbers and memos)
- **Timer**: Tracks elapsed time with pause/resume capability
- **Line Completion Animation**: Visual feedback when row/column/box completes (sequential cell animation)
- **Game Persistence**: Auto-save after each move, resume on app restart
- **Statistics Tracking**: Per-difficulty stats including win rate, streaks, best time, perfect wins (no hints + 3 hearts)
- **Sound Effects**: Correct/wrong answer audio feedback (toggleable in settings)
- **Daily Missions**: Calendar-based daily challenges with trophy collection (separate progress tracking)
- **Ad Integration**: Play counter system shows ads every 3 games (interstitial), banner ads on game screen, rewarded ads for hints/hearts
- **In-App Updates**: Automatic update checking with force/flexible update support

### Difficulty System

The game supports 5 difficulty levels in this order:
- **beginner** (입문자) - Puzzles 0-239 (240 puzzles)
- **rookie** (초보자) - Puzzles 240-479 (240 puzzles)
- **easy** (초급) - Puzzles 480-719 (240 puzzles)
- **medium** (중급) - Puzzles 720-959 (240 puzzles)
- **hard** (고급) - Puzzles 960-1199 (240 puzzles)

Total: 1,200 puzzles. Each difficulty has dedicated statistics tracking with proper Korean labels in the UI.

### Daily Mission System

- Missions start from October 1, 2025
- Calendar shows status: locked (future/before start), available (playable), inProgress (started), completed (finished)
- Trophy awarded when all days in a month are completed
- Past dates can be replayed with ads
- Progress is saved independently from regular game saves
- Monthly navigation bounded by mission start date and current month

## Platform Considerations

- **Web**: Ads are disabled (`kIsWeb` check)
- **Mobile**: Full ad integration with Google Mobile Ads SDK
- **Assets**: Icon and sound files in `assets/` directory

## Important Files to Know

- `lib/main.dart`: App entry point, Provider setup, ChangeNotifierProvider wrapper
- `lib/models/sudoku_game.dart`: Core game logic (~676 lines, ChangeNotifier pattern)
- `lib/data/puzzle_data.dart`: All puzzle data (very large file ~920KB, read with offset/limit)
- `lib/screens/main_screen.dart`: Bottom navigation container with PageView
- `lib/screens/sudoku_screen.dart`: Main gameplay UI with board and controls
- `lib/widgets/sudoku_board.dart`: Board rendering with complex highlighting logic
- `lib/utils/game_storage.dart`: Game save/load implementation (SharedPreferences)
- `lib/utils/statistics_storage.dart`: Statistics persistence (per-difficulty tracking)
- `lib/utils/daily_mission_storage.dart`: Daily mission data management (calendar-based)
- `lib/utils/ad_helper.dart`: Google Mobile Ads preloading and display
- `pubspec.yaml`: Dependencies and asset declarations

## Key Data Structures

### Board State (in SudokuGame)
```dart
List<List<int>> board              // Current player input (9x9, values 0-9)
List<List<int>> initialBoard       // Original puzzle (9x9, 0=empty)
List<List<Set<int>>> memos         // Candidate numbers per cell (9x9 of Sets)
List<List<bool>> correctCells      // Validation tracking (9x9 booleans)
Set<String> completedLines         // Completed row/col/box (e.g., "row_5", "col_3", "box_2")
Set<String> conflictingCells       // Wrong cells for blink animation (e.g., "5_3" for row_col)
```

### Validation & Animation
- Each `setNumber()` call validates against solution array
- Correct answers → update `correctCells`, check for line completions, trigger animations
- Wrong answers → hearts--, add to `conflictingCells`, trigger blink animation
- Line completion: Sequential cell animation (50ms per cell) with blue highlight

## Animation Systems

1. **Line Completion Animation**: `isCellAnimating(row, col)` checks if cell is in current animation sequence
2. **Heart Flying Animation**: 1000ms animation from screen center to app bar heart icon
3. **Conflicting Cell Blink**: 3 blink cycles (200ms on/off) for wrong answers

## Persistence Keys (SharedPreferences)

### Game State
- `'saved_game'`: Current game progress (board, initialBoard, memos, correctCells, hearts, hintsUsed, elapsedSeconds, completedLines)

### Statistics (per difficulty)
- `'stats_beginner'`, `'stats_rookie'`, `'stats_easy'`, `'stats_medium'`, `'stats_hard'`: Game statistics (gamesStarted, gamesWon, perfectWins, bestTime, totalTime, currentStreak, bestStreak)

### Daily Missions
- `'daily_mission_YYYY-MM-DD'`: Mission data for specific date (date, status, difficulty, puzzleNumber, savedBoard, savedCorrectCells, elapsedSeconds)
- `'daily_mission_trophies'`: List of completed months (format: "YYYY-MM")

### Settings & Counters
- `'sound_enabled'`: Audio toggle (default: true)
- `'play_count'`: Play counter for ad frequency (shows ad every 3 plays)

## Ad Integration Flow

1. **App Launch**: `AdHelper.preloadInterstitialAd()` called in WelcomeScreen
2. **Game Start**:
   - `PlayCounter.incrementPlayCount()` increments counter
   - If count % 3 == 0: Show interstitial ad
   - `AdHelper.preloadRewardedAd()` called in SudokuScreen
3. **Hint Request**: Watch rewarded ad → `useHint()` reveals answer
4. **Game Over**: Rewarded ad option to restore 1 heart
5. **Banner Ad**: Displayed at bottom of SudokuScreen (mobile only, not on web)
