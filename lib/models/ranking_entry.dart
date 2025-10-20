class RankingEntry {
  final int rank;
  final String name;
  final int score;
  final bool isBot;
  final bool isMe;

  RankingEntry({
    required this.rank,
    required this.name,
    required this.score,
    this.isBot = false,
    this.isMe = false,
  });

  RankingEntry copyWith({
    int? rank,
    String? name,
    int? score,
    bool? isBot,
    bool? isMe,
  }) {
    return RankingEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: score ?? this.score,
      isBot: isBot ?? this.isBot,
      isMe: isMe ?? this.isMe,
    );
  }
}
