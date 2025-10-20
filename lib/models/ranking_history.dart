class RankingHistory {
  final String seasonId; // "2025-W43" 형식
  final int seasonNumber; // 43
  final Map<String, RankingRecord?> records; // 'easy', 'medium', 'hard'

  RankingHistory({
    required this.seasonId,
    required this.seasonNumber,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'seasonId': seasonId,
        'seasonNumber': seasonNumber,
        'records': records.map((key, value) => MapEntry(key, value?.toJson())),
      };

  factory RankingHistory.fromJson(Map<String, dynamic> json) {
    final recordsMap = json['records'] as Map<String, dynamic>;
    return RankingHistory(
      seasonId: json['seasonId'],
      seasonNumber: json['seasonNumber'],
      records: recordsMap.map(
        (key, value) => MapEntry(
          key,
          value != null ? RankingRecord.fromJson(value) : null,
        ),
      ),
    );
  }
}

class RankingRecord {
  final int rank; // 순위
  final int score; // 점수

  RankingRecord({
    required this.rank,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'score': score,
      };

  factory RankingRecord.fromJson(Map<String, dynamic> json) => RankingRecord(
        rank: json['rank'],
        score: json['score'],
      );
}
