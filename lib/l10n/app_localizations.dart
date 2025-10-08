import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': '스도쿠',
      'new_game': '새로 시작',
      'continue_game': '이어서 하기',
      'no_saved_game': '저장된 게임 없음',
      'difficulty_easy': '초급',
      'difficulty_medium': '중급',
      'difficulty_hard': '고급',
      'select_difficulty': '난이도 선택',
      'cancel': '취소',
      'game_over': '게임 오버',
      'game_over_message': '3회 실수하면 게임이 종료됩니다.',
      'watch_ad_for_heart': '광고 시청 후 하트 1개 받기',
      'new_game_button': '새 게임',
      'stage_complete': '스테이지 완료!',
      'record': '기록',
      'next_stage': '다음 스테이지',
      'first_stage': '처음으로',
      'options': '옵션',
      'sound_effects': '효과음',
      'close': '닫기',
      'ad_note': '광고를 끝까지 시청해야 하트를 받을 수 있습니다.',
      'easy_desc': 'Easy - 쉬운 난이도',
      'medium_desc': 'Medium - 보통 난이도',
      'hard_desc': 'Hard - 어려운 난이도',
      'sudoku_puzzle_game': '스도쿠 퍼즐 게임',
    },
    'en': {
      'app_title': 'Sudoku',
      'new_game': 'New Game',
      'continue_game': 'Continue',
      'no_saved_game': 'No Saved Game',
      'difficulty_easy': 'Easy',
      'difficulty_medium': 'Medium',
      'difficulty_hard': 'Hard',
      'select_difficulty': 'Select Difficulty',
      'cancel': 'Cancel',
      'game_over': 'Game Over',
      'game_over_message': 'Game ends after 3 mistakes.',
      'watch_ad_for_heart': 'Watch ad to get 1 heart',
      'new_game_button': 'New Game',
      'stage_complete': 'Stage Complete!',
      'record': 'Record',
      'next_stage': 'Next Stage',
      'first_stage': 'First Stage',
      'options': 'Options',
      'sound_effects': 'Sound Effects',
      'close': 'Close',
      'ad_note': 'You must watch the ad to the end to receive a heart.',
      'easy_desc': 'Easy - Simple difficulty',
      'medium_desc': 'Medium - Normal difficulty',
      'hard_desc': 'Hard - Difficult',
      'sudoku_puzzle_game': 'Sudoku Puzzle Game',
    },
    'ja': {
      'app_title': '数独',
      'new_game': '新しいゲーム',
      'continue_game': '続ける',
      'no_saved_game': '保存されたゲームなし',
      'difficulty_easy': '初級',
      'difficulty_medium': '中級',
      'difficulty_hard': '上級',
      'select_difficulty': '難易度選択',
      'cancel': 'キャンセル',
      'game_over': 'ゲームオーバー',
      'game_over_message': '3回のミスでゲームが終了します。',
      'watch_ad_for_heart': '広告を見てハート1個獲得',
      'new_game_button': '新しいゲーム',
      'stage_complete': 'ステージクリア！',
      'record': '記録',
      'next_stage': '次のステージ',
      'first_stage': '最初から',
      'options': 'オプション',
      'sound_effects': '効果音',
      'close': '閉じる',
      'ad_note': '広告を最後まで視聴する必要があります。',
      'easy_desc': 'Easy - 簡単な難易度',
      'medium_desc': 'Medium - 普通の難易度',
      'hard_desc': 'Hard - 難しい難易度',
      'sudoku_puzzle_game': '数独パズルゲーム',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get appTitle => translate('app_title');
  String get newGame => translate('new_game');
  String get continueGame => translate('continue_game');
  String get noSavedGame => translate('no_saved_game');
  String get difficultyEasy => translate('difficulty_easy');
  String get difficultyMedium => translate('difficulty_medium');
  String get difficultyHard => translate('difficulty_hard');
  String get selectDifficulty => translate('select_difficulty');
  String get cancel => translate('cancel');
  String get gameOver => translate('game_over');
  String get gameOverMessage => translate('game_over_message');
  String get watchAdForHeart => translate('watch_ad_for_heart');
  String get newGameButton => translate('new_game_button');
  String get stageComplete => translate('stage_complete');
  String get record => translate('record');
  String get nextStage => translate('next_stage');
  String get firstStage => translate('first_stage');
  String get options => translate('options');
  String get soundEffects => translate('sound_effects');
  String get close => translate('close');
  String get adNote => translate('ad_note');
  String get easyDesc => translate('easy_desc');
  String get mediumDesc => translate('medium_desc');
  String get hardDesc => translate('hard_desc');
  String get sudokuPuzzleGame => translate('sudoku_puzzle_game');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ko', 'en', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
