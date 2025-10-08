import 'package:flutter/material.dart';
import '../utils/statistics_storage.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  GameStatistics beginnerStats = GameStatistics();
  GameStatistics rookieStats = GameStatistics();
  GameStatistics easyStats = GameStatistics();
  GameStatistics mediumStats = GameStatistics();
  GameStatistics hardStats = GameStatistics();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final beginner = await StatisticsStorage.getStatistics('beginner');
    final rookie = await StatisticsStorage.getStatistics('rookie');
    final easy = await StatisticsStorage.getStatistics('easy');
    final medium = await StatisticsStorage.getStatistics('medium');
    final hard = await StatisticsStorage.getStatistics('hard');

    setState(() {
      beginnerStats = beginner;
      rookieStats = rookie;
      easyStats = easy;
      mediumStats = medium;
      hardStats = hard;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds == 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    return number.toString().padLeft(5, '0');
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(String difficulty, String difficultyKorean) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('통계를 초기화 하시겠습니까?'),
          content: Text('$difficultyKorean 데이터가 초기화 됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await StatisticsStorage.resetStatistics(difficulty);
                Navigator.of(context).pop();
                await _loadStatistics();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$difficultyKorean 통계가 초기화되었습니다.')),
                  );
                }
              },
              child: const Text(
                '재설정',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsContent(GameStatistics stats, String difficulty, String difficultyKorean) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildStatRow('시작한 게임', _formatNumber(stats.gamesStarted)),
                const Divider(),
                _buildStatRow('이긴 게임', _formatNumber(stats.gamesWon)),
                const Divider(),
                _buildStatRow('승률', '${stats.winRate.toStringAsFixed(2)}%'),
                const Divider(),
                _buildStatRow('실수 없는 승리', _formatNumber(stats.perfectWins)),
                const Divider(),
                _buildStatRow('최고 시간', _formatTime(stats.bestTime)),
                const Divider(),
                _buildStatRow('평균 시간', _formatTime(stats.averageTime)),
                const Divider(),
                _buildStatRow('현재 연승', _formatNumber(stats.currentStreak)),
                const Divider(),
                _buildStatRow('최고 연승', _formatNumber(stats.bestStreak)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showResetConfirmDialog(difficulty, difficultyKorean),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '통계 초기화',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '입문자'),
            Tab(text: '초보자'),
            Tab(text: '초급'),
            Tab(text: '중급'),
            Tab(text: '고급'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsContent(beginnerStats, 'beginner', '입문자'),
          _buildStatsContent(rookieStats, 'rookie', '초보자'),
          _buildStatsContent(easyStats, 'easy', '초급'),
          _buildStatsContent(mediumStats, 'medium', '중급'),
          _buildStatsContent(hardStats, 'hard', '고급'),
        ],
      ),
    );
  }
}