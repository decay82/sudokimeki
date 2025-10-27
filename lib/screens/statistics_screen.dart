import 'package:flutter/material.dart';
import '../utils/statistics_storage.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  final bool showAppBar;

  const StatisticsScreen({super.key, this.showAppBar = true});

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
    // 3자리마다 쉼표 추가
    String numberStr = number.toString();
    String result = '';
    int count = 0;

    for (int i = numberStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = numberStr[i] + result;
      count++;
    }

    return result;
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
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmResetStatistics),
          content: Text(l10n.difficultyDataWillBeReset(difficultyKorean)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                await StatisticsStorage.resetStatistics(difficulty);
                Navigator.of(context).pop();
                await _loadStatistics();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.statisticsReset(difficultyKorean))),
                  );
                }
              },
              child: Text(
                l10n.reset,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.grey.shade200,
      width: double.infinity,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatsContent(GameStatistics stats, String difficulty, String difficultyKorean, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 게임 카테고리
                _buildCategoryHeader(l10n.games),
                _buildStatRow(l10n.gamesStarted, _formatNumber(stats.gamesStarted)),
                const Divider(height: 1),
                _buildStatRow(l10n.gamesWon, _formatNumber(stats.gamesWon)),
                const Divider(height: 1),
                _buildStatRow(l10n.winRate, '${stats.winRate.toStringAsFixed(2)}%'),
                const Divider(height: 1),
                _buildStatRow(l10n.perfectWins, _formatNumber(stats.perfectWins)),
                const SizedBox(height: 20),

                // 최고 점수 카테고리
                _buildCategoryHeader(l10n.highScore),
                _buildStatRow(l10n.today, _formatNumber(stats.todayHighScore)),
                const Divider(height: 1),
                _buildStatRow(l10n.thisWeek, _formatNumber(stats.weekHighScore)),
                const Divider(height: 1),
                _buildStatRow(l10n.thisMonth, _formatNumber(stats.monthHighScore)),
                const Divider(height: 1),
                _buildStatRow(l10n.allTime, _formatNumber(stats.totalScore)),
                const SizedBox(height: 20),

                // 시간 카테고리
                _buildCategoryHeader(l10n.time),
                _buildStatRow(l10n.bestTime, _formatTime(stats.bestTime)),
                const Divider(height: 1),
                _buildStatRow(l10n.averageTime, _formatTime(stats.averageTime)),
                const SizedBox(height: 20),

                // 연승 카테고리
                _buildCategoryHeader(l10n.winStreak),
                _buildStatRow(l10n.currentStreak, _formatNumber(stats.currentStreak)),
                const Divider(height: 1),
                _buildStatRow(l10n.bestStreak, _formatNumber(stats.bestStreak)),
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
              child: Text(
                l10n.resetStatistics,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(l10n.statistics),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.difficultyBeginner),
                  Tab(text: l10n.difficultyRookie),
                  Tab(text: l10n.difficultyEasy),
                  Tab(text: l10n.difficultyMedium),
                  Tab(text: l10n.difficultyHard),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          // 상단 타이틀 (showAppBar가 false일 때만 표시)
          if (!widget.showAppBar)
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.statistics,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          // TabBar (showAppBar가 false일 때)
          if (!widget.showAppBar)
            Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.difficultyBeginner),
                  Tab(text: l10n.difficultyRookie),
                  Tab(text: l10n.difficultyEasy),
                  Tab(text: l10n.difficultyMedium),
                  Tab(text: l10n.difficultyHard),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsContent(beginnerStats, 'beginner', l10n.difficultyBeginner, context),
                _buildStatsContent(rookieStats, 'rookie', l10n.difficultyRookie, context),
                _buildStatsContent(easyStats, 'easy', l10n.difficultyEasy, context),
                _buildStatsContent(mediumStats, 'medium', l10n.difficultyMedium, context),
                _buildStatsContent(hardStats, 'hard', l10n.difficultyHard, context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}