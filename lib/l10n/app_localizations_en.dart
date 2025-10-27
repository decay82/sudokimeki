// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get difficultyBeginner => 'Beginner';

  @override
  String get difficultyRookie => 'Rookie';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyUnknown => 'Unknown';

  @override
  String get difficultyBeginnerDesc => 'Beginner - For first-time players';

  @override
  String get difficultyRookieDesc => 'Rookie - Good for practice';

  @override
  String get difficultyEasyDesc => 'Easy - Easy level';

  @override
  String get difficultyMediumDesc => 'Medium - Normal level';

  @override
  String get difficultyHardDesc => 'Hard - Difficult level';

  @override
  String get selectDifficulty => 'Select Difficulty';

  @override
  String get cancel => 'Cancel';

  @override
  String get sudokuPuzzleGame => 'Sudoku Puzzle Game';

  @override
  String get newGame => 'New Game';

  @override
  String continueGame(String info) {
    return 'Continue\n$info';
  }

  @override
  String get noSavedGame => 'No Saved Game';

  @override
  String get noSavedGameAvailable => 'No saved game available.';

  @override
  String noPuzzlesForDifficulty(String difficulty) {
    return 'No puzzles available for $difficulty difficulty.';
  }

  @override
  String get statistics => 'Statistics';

  @override
  String get games => 'Games';

  @override
  String get gamesStarted => 'Games Started';

  @override
  String get gamesWon => 'Games Won';

  @override
  String get winRate => 'Win Rate';

  @override
  String get perfectWins => 'Perfect Wins';

  @override
  String get highScore => 'High Score';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get allTime => 'All Time';

  @override
  String get time => 'Time';

  @override
  String get bestTime => 'Best Time';

  @override
  String get averageTime => 'Average Time';

  @override
  String get winStreak => 'Win Streak';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get resetStatistics => 'Reset Statistics';

  @override
  String get confirmResetStatistics =>
      'Are you sure you want to reset statistics?';

  @override
  String difficultyDataWillBeReset(String difficulty) {
    return '$difficulty data will be reset.';
  }

  @override
  String statisticsReset(String difficulty) {
    return '$difficulty statistics have been reset.';
  }

  @override
  String get reset => 'Reset';

  @override
  String get dailyMission => 'Daily Mission';

  @override
  String get completedMission => 'Completed Mission';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get clearTime => 'Clear Time';

  @override
  String get play => 'Play';

  @override
  String yearMonth(int year, int month) {
    return '$month/$year';
  }

  @override
  String get completed => 'Completed';

  @override
  String get clearAllMissions => 'Clear all missions';

  @override
  String get sunday => 'Sun';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get ranking => 'Ranking';

  @override
  String get rankingHistory => 'Ranking History';

  @override
  String get noRankingData => 'No ranking data available.';

  @override
  String get initializing => 'Initializing...';

  @override
  String timeRemaining(int days, String hours, String minutes, String seconds) {
    return '${days}d $hours:$minutes:$seconds';
  }

  @override
  String get history => 'History';

  @override
  String get noRankingHistory => 'No ranking history available.';

  @override
  String season(int number) {
    return 'Season $number';
  }

  @override
  String rankNumber(int rank) {
    return 'Rank $rank';
  }

  @override
  String get smartOn => 'Smart\nON';

  @override
  String get smart => 'Smart';

  @override
  String get memoOn => 'Memo\nON';

  @override
  String get memo => 'Memo';

  @override
  String get delete => 'Delete';

  @override
  String get hintOn => 'Hint\nON';

  @override
  String hintPlus(int count) {
    return 'Hint\n+$count';
  }

  @override
  String get hint => 'Hint';

  @override
  String get completedGamesNotSaved => 'Completed game will not be saved.';

  @override
  String get savedGameLoaded => 'Saved game loaded.';

  @override
  String difficultyProgress(String previousName, int completed, int required) {
    return '$previousName $completed/$required completed';
  }

  @override
  String get me => 'Me';

  @override
  String get options => 'Options';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get close => 'Close';

  @override
  String get gameOver => 'Game Over';

  @override
  String get watchAdToGetHeart =>
      'You must watch the ad to the end to receive a heart.';

  @override
  String get adWatchHeartRecharge => 'Watch ad to recharge 3 hearts';

  @override
  String get restart => 'Restart';

  @override
  String get home => 'Home';

  @override
  String get totalScore => 'Total Score';

  @override
  String record(String time) {
    return 'Record: $time';
  }

  @override
  String get nextStage => 'Next Stage';

  @override
  String get unknown => 'Unknown';

  @override
  String get trophyCollection => 'Trophy Collection';

  @override
  String get noDailyMissionsYet => 'No daily missions yet';

  @override
  String get inProgress => 'In Progress';

  @override
  String get confirm => 'Confirm';

  @override
  String get gameOverMessage => 'Game ends after 3 mistakes.';
}
