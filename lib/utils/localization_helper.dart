import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 난이도 이름을 현재 언어로 반환하는 헬퍼 함수
String getDifficultyName(BuildContext context, String difficulty) {
  final l10n = AppLocalizations.of(context)!;

  switch (difficulty.toLowerCase()) {
    case 'beginner':
      return l10n.difficultyBeginner;
    case 'rookie':
      return l10n.difficultyRookie;
    case 'easy':
      return l10n.difficultyEasy;
    case 'medium':
      return l10n.difficultyMedium;
    case 'hard':
      return l10n.difficultyHard;
    default:
      return l10n.difficultyUnknown;
  }
}

/// 난이도 설명을 현재 언어로 반환하는 헬퍼 함수
String getDifficultyDescription(BuildContext context, String difficulty) {
  final l10n = AppLocalizations.of(context)!;

  switch (difficulty.toLowerCase()) {
    case 'beginner':
      return l10n.difficultyBeginnerDesc;
    case 'rookie':
      return l10n.difficultyRookieDesc;
    case 'easy':
      return l10n.difficultyEasyDesc;
    case 'medium':
      return l10n.difficultyMediumDesc;
    case 'hard':
      return l10n.difficultyHardDesc;
    default:
      return '';
  }
}

/// 요일 이름을 현재 언어로 반환하는 헬퍼 함수
String getDayName(BuildContext context, int dayOfWeek) {
  final l10n = AppLocalizations.of(context)!;

  switch (dayOfWeek) {
    case 1:
      return l10n.monday;
    case 2:
      return l10n.tuesday;
    case 3:
      return l10n.wednesday;
    case 4:
      return l10n.thursday;
    case 5:
      return l10n.friday;
    case 6:
      return l10n.saturday;
    case 7:
      return l10n.sunday;
    default:
      return '';
  }
}
