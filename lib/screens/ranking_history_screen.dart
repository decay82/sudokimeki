import 'package:flutter/material.dart';
import '../models/ranking_history.dart';
import '../utils/ranking_history_storage.dart';

class RankingHistoryScreen extends StatefulWidget {
  const RankingHistoryScreen({super.key});

  @override
  State<RankingHistoryScreen> createState() => _RankingHistoryScreenState();
}

class _RankingHistoryScreenState extends State<RankingHistoryScreen> {
  List<RankingHistory> histories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() => isLoading = true);
    final loadedHistories = await RankingHistoryStorage.getAllHistories();
    setState(() {
      histories = loadedHistories;
      isLoading = false;
    });
  }

  String _formatScore(int score) {
    String scoreStr = score.toString();
    String result = '';
    int count = 0;

    for (int i = scoreStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = scoreStr[i] + result;
      count++;
    }

    return result;
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '초급';
      case 'medium':
        return '중급';
      case 'hard':
        return '고급';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('히스토리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : histories.isEmpty
              ? const Center(
                  child: Text(
                    '랭킹 히스토리가 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    return _buildSeasonCard(history);
                  },
                ),
    );
  }

  Widget _buildSeasonCard(RankingHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시즌 헤더
            Text(
              '${history.seasonNumber}시즌',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 난이도별 결과
            _buildDifficultyRow('easy', history.records['easy']),
            const SizedBox(height: 8),
            _buildDifficultyRow('medium', history.records['medium']),
            const SizedBox(height: 8),
            _buildDifficultyRow('hard', history.records['hard']),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyRow(String difficulty, RankingRecord? record) {
    return Row(
      children: [
        // 난이도 레이블
        SizedBox(
          width: 50,
          child: Text(
            _getDifficultyLabel(difficulty),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 순위
        SizedBox(
          width: 60,
          child: Text(
            record != null ? '${record.rank}위' : '-',
            style: TextStyle(
              fontSize: 14,
              color: record != null ? Colors.blue.shade700 : Colors.grey,
            ),
          ),
        ),
        const Spacer(),
        // 점수
        Text(
          record != null ? _formatScore(record.score) : '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: record != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
