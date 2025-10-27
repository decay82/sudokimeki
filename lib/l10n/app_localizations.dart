import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// Beginner difficulty level
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// Rookie difficulty level
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get difficultyRookie;

  /// Easy difficulty level
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// Medium difficulty level
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// Hard difficulty level
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// Unknown difficulty level
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get difficultyUnknown;

  /// No description provided for @difficultyBeginnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Beginner - For first-time players'**
  String get difficultyBeginnerDesc;

  /// No description provided for @difficultyRookieDesc.
  ///
  /// In en, this message translates to:
  /// **'Rookie - Good for practice'**
  String get difficultyRookieDesc;

  /// No description provided for @difficultyEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy - Easy level'**
  String get difficultyEasyDesc;

  /// No description provided for @difficultyMediumDesc.
  ///
  /// In en, this message translates to:
  /// **'Medium - Normal level'**
  String get difficultyMediumDesc;

  /// No description provided for @difficultyHardDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard - Difficult level'**
  String get difficultyHardDesc;

  /// No description provided for @selectDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Select Difficulty'**
  String get selectDifficulty;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sudokuPuzzleGame.
  ///
  /// In en, this message translates to:
  /// **'Sudoku Puzzle Game'**
  String get sudokuPuzzleGame;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue\n{info}'**
  String continueGame(String info);

  /// No description provided for @noSavedGame.
  ///
  /// In en, this message translates to:
  /// **'No Saved Game'**
  String get noSavedGame;

  /// No description provided for @noSavedGameAvailable.
  ///
  /// In en, this message translates to:
  /// **'No saved game available.'**
  String get noSavedGameAvailable;

  /// No description provided for @noPuzzlesForDifficulty.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available for {difficulty} difficulty.'**
  String noPuzzlesForDifficulty(String difficulty);

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gamesStarted.
  ///
  /// In en, this message translates to:
  /// **'Games Started'**
  String get gamesStarted;

  /// No description provided for @gamesWon.
  ///
  /// In en, this message translates to:
  /// **'Games Won'**
  String get gamesWon;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @perfectWins.
  ///
  /// In en, this message translates to:
  /// **'Perfect Wins'**
  String get perfectWins;

  /// No description provided for @highScore.
  ///
  /// In en, this message translates to:
  /// **'High Score'**
  String get highScore;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @bestTime.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get bestTime;

  /// No description provided for @averageTime.
  ///
  /// In en, this message translates to:
  /// **'Average Time'**
  String get averageTime;

  /// No description provided for @winStreak.
  ///
  /// In en, this message translates to:
  /// **'Win Streak'**
  String get winStreak;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @resetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get resetStatistics;

  /// No description provided for @confirmResetStatistics.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset statistics?'**
  String get confirmResetStatistics;

  /// No description provided for @difficultyDataWillBeReset.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} data will be reset.'**
  String difficultyDataWillBeReset(String difficulty);

  /// No description provided for @statisticsReset.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} statistics have been reset.'**
  String statisticsReset(String difficulty);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @dailyMission.
  ///
  /// In en, this message translates to:
  /// **'Daily Mission'**
  String get dailyMission;

  /// No description provided for @completedMission.
  ///
  /// In en, this message translates to:
  /// **'Completed Mission'**
  String get completedMission;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear Time'**
  String get clearTime;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @yearMonth.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String yearMonth(int year, int month);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @clearAllMissions.
  ///
  /// In en, this message translates to:
  /// **'Clear all missions'**
  String get clearAllMissions;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @rankingHistory.
  ///
  /// In en, this message translates to:
  /// **'Ranking History'**
  String get rankingHistory;

  /// No description provided for @noRankingData.
  ///
  /// In en, this message translates to:
  /// **'No ranking data available.'**
  String get noRankingData;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}:{minutes}:{seconds}'**
  String timeRemaining(int days, String hours, String minutes, String seconds);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noRankingHistory.
  ///
  /// In en, this message translates to:
  /// **'No ranking history available.'**
  String get noRankingHistory;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String season(int number);

  /// No description provided for @rankNumber.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String rankNumber(int rank);

  /// No description provided for @smartOn.
  ///
  /// In en, this message translates to:
  /// **'Smart\nON'**
  String get smartOn;

  /// No description provided for @smart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get smart;

  /// No description provided for @memoOn.
  ///
  /// In en, this message translates to:
  /// **'Memo\nON'**
  String get memoOn;

  /// No description provided for @memo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get memo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @hintOn.
  ///
  /// In en, this message translates to:
  /// **'Hint\nON'**
  String get hintOn;

  /// No description provided for @hintPlus.
  ///
  /// In en, this message translates to:
  /// **'Hint\n+{count}'**
  String hintPlus(int count);

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @completedGamesNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Completed game will not be saved.'**
  String get completedGamesNotSaved;

  /// No description provided for @savedGameLoaded.
  ///
  /// In en, this message translates to:
  /// **'Saved game loaded.'**
  String get savedGameLoaded;

  /// No description provided for @difficultyProgress.
  ///
  /// In en, this message translates to:
  /// **'{previousName} {completed}/{required} completed'**
  String difficultyProgress(String previousName, int completed, int required);

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @watchAdToGetHeart.
  ///
  /// In en, this message translates to:
  /// **'You must watch the ad to the end to receive a heart.'**
  String get watchAdToGetHeart;

  /// No description provided for @adWatchHeartRecharge.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to recharge 3 hearts'**
  String get adWatchHeartRecharge;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScore;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record: {time}'**
  String record(String time);

  /// No description provided for @nextStage.
  ///
  /// In en, this message translates to:
  /// **'Next Stage'**
  String get nextStage;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @trophyCollection.
  ///
  /// In en, this message translates to:
  /// **'Trophy Collection'**
  String get trophyCollection;

  /// No description provided for @noDailyMissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No daily missions yet'**
  String get noDailyMissionsYet;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @gameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'Game ends after 3 mistakes.'**
  String get gameOverMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
