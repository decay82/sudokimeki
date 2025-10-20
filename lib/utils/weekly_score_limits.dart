class WeeklyScoreLimits {
  /// 난이도별 점수 제한 및 게임 정보 (17시간/일 기준)
  static Map<String, Map<String, int>> getLimits() {
    return {
      'beginner': {
        'avgScorePerGame': 300, // 평균 점수/판
        'gamesPerHour': 12, // 시간당 판수
        'dailyPlayHours': 17, // 하루 플레이 시간
        'user1stScore': 428400, // 300 * 12 * 17 * 7 = 428,400점
        'bot1stMax': 406980, // 428,400의 95% = 406,980점
        'weeklyMax': 428400, // 주간 최대 = 하루 최대 × 7
      },
      'rookie': {
        'avgScorePerGame': 600,
        'gamesPerHour': 7,
        'dailyPlayHours': 17,
        'user1stScore': 499800, // 600 * 7 * 17 * 7 = 499,800점
        'bot1stMax': 474810, // 95%
        'weeklyMax': 499800,
      },
      'easy': {
        'avgScorePerGame': 600,
        'gamesPerHour': 7,
        'dailyPlayHours': 17,
        'user1stScore': 499800,
        'bot1stMax': 474810,
        'weeklyMax': 499800,
      },
      'medium': {
        'avgScorePerGame': 1000,
        'gamesPerHour': 5,
        'dailyPlayHours': 17,
        'user1stScore': 595000, // 1000 * 5 * 17 * 7 = 595,000점
        'bot1stMax': 565250, // 95%
        'weeklyMax': 595000,
      },
      'hard': {
        'avgScorePerGame': 2000,
        'gamesPerHour': 3,
        'dailyPlayHours': 17,
        'user1stScore': 714000, // 2000 * 3 * 17 * 7 = 714,000점
        'bot1stMax': 678300, // 95%
        'weeklyMax': 714000,
      },
    };
  }

  /// 봇 순위별 최대 점수 계산
  static int getBotMaxScore(int rank, String difficulty) {
    final limits = getLimits()[difficulty];
    if (limits == null) return 0;

    final bot1stMax = limits['bot1stMax']!;

    // 순위별 점수 비율
    if (rank == 0) {
      // 1등: bot1stMax (95% of user target)
      return bot1stMax;
    } else if (rank == 1) {
      // 2등: 95%
      return (bot1stMax * 0.95).toInt();
    } else if (rank == 2) {
      // 3등: 90%
      return (bot1stMax * 0.90).toInt();
    } else if (rank <= 4) {
      // 4-5등: 75-85%
      return (bot1stMax * (0.85 - (rank - 2) * 0.05)).toInt();
    } else if (rank <= 9) {
      // 6-10등: 55-75%
      return (bot1stMax * (0.75 - (rank - 4) * 0.04)).toInt();
    } else if (rank <= 19) {
      // 11-20등: 35-55%
      return (bot1stMax * (0.55 - (rank - 9) * 0.02)).toInt();
    } else if (rank <= 49) {
      // 21-50등: 10-35%
      return (bot1stMax * (0.35 - (rank - 19) * 0.008)).toInt();
    } else {
      // 50등 이하: 5-10%
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      return (bot1stMax * 0.1 * (random / 100) + bot1stMax * 0.05).toInt();
    }
  }

  /// 주차 진행도에 따른 현재 봇 점수 계산
  static int getBotCurrentScore(int rank, String difficulty, DateTime weekStart) {
    final limits = getLimits()[difficulty];
    if (limits == null) return 0;

    final maxScore = getBotMaxScore(rank, difficulty);
    final avgScorePerGame = limits['avgScorePerGame']!;

    // 주차 진행도 계산 (시간 단위)
    final now = DateTime.now();
    final hoursPassed = now.difference(weekStart).inHours.toDouble();
    final totalWeekHours = 7 * 24.0;

    // 진행률 (0.0 ~ 1.0)
    final progressPercent = (hoursPassed / totalWeekHours).clamp(0.0, 1.0);

    // 현재까지 플레이한 게임 수 계산 (최대 점수 기준)
    final totalGamesNeeded = (maxScore / avgScorePerGame).ceil();
    final currentGamesPlayed = (totalGamesNeeded * progressPercent).floor();

    // 게임 수 × 평균 점수 = 기본 점수
    final baseScore = currentGamesPlayed * avgScorePerGame;

    // 봇마다 고정된 랜덤 변동 추가 (-10% ~ +10%)
    // rank를 시드로 사용하여 봇마다 일관된 변동값 생성
    final random = (rank * 12345) % 100; // 0~99
    final variationPercent = (random / 100.0) * 0.2 - 0.1; // -0.1 ~ +0.1
    final randomVariation = (baseScore * variationPercent).toInt();

    return baseScore + randomVariation;
  }
}
