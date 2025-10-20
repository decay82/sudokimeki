import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ranking_entry.dart';
import '../utils/weekly_bot_ranking.dart';
import '../utils/ranking_history_storage.dart';
import 'ranking_history_screen.dart';

class RankingScreen extends StatefulWidget {
  final bool showAppBar;

  const RankingScreen({super.key, this.showAppBar = true});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  // 각 탭별 스크롤 컨트롤러 (초급, 중급, 고급만)
  final ScrollController _easyScrollController = ScrollController();
  final ScrollController _mediumScrollController = ScrollController();
  final ScrollController _hardScrollController = ScrollController();

  List<RankingEntry> easyRanking = [];
  List<RankingEntry> mediumRanking = [];
  List<RankingEntry> hardRanking = [];

  bool isLoading = true;
  int _initialTabIndex = 0;
  Timer? _timer;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _loadInitialTab();
    _startTimer();
  }

  void _startTimer() {
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    final resetTime = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 0, 0, 0);

    final difference = resetTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _timeRemaining = '초기화 중...';
      });
      return;
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    String timeText = '';
    if (days > 0) {
      timeText = '$days일 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      timeText = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    setState(() {
      _timeRemaining = timeText;
    });
  }

  Future<void> _loadInitialTab() async {
    // 마지막으로 본 탭 인덱스 불러오기
    final prefs = await SharedPreferences.getInstance();
    final lastTabIndex = prefs.getInt('last_ranking_tab') ?? 0;

    setState(() {
      _initialTabIndex = lastTabIndex;
    });

    _tabController = TabController(length: 3, vsync: this, initialIndex: _initialTabIndex);
    _tabController.addListener(_onTabChanged);
    _loadRankings();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // 탭 변경 완료 후 현재 탭의 내 순위로 스크롤
      _scrollToMyRank(_tabController.index);

      // 현재 탭 인덱스 저장
      _saveCurrentTab();
    }
  }

  Future<void> _saveCurrentTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_ranking_tab', _tabController.index);
  }

  Future<void> _loadRankings() async {
    setState(() => isLoading = true);

    // 주간 리셋 확인 및 이전 주차 히스토리 저장
    final prefs = await SharedPreferences.getInstance();
    final currentWeekId = WeeklyBotRanking.getCurrentWeekId();
    final savedWeekId = prefs.getString('current_week_id');

    if (savedWeekId != null && savedWeekId != currentWeekId) {
      // 새 주차 시작 - 이전 주차 랭킹을 히스토리에 저장
      await RankingHistoryStorage.saveCurrentWeekRanking();
    }

    await WeeklyBotRanking.checkAndResetWeek();

    // 각 난이도별 랭킹 로드 (초급, 중급, 고급만)
    final easy = await WeeklyBotRanking.generateWeeklyRanking('easy');
    final medium = await WeeklyBotRanking.generateWeeklyRanking('medium');
    final hard = await WeeklyBotRanking.generateWeeklyRanking('hard');

    setState(() {
      easyRanking = easy;
      mediumRanking = medium;
      hardRanking = hard;
      isLoading = false;
    });

    // 로딩 완료 후 현재 탭의 내 순위로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMyRank(_tabController.index);
    });
  }

  void _scrollToMyRank(int tabIndex) {
    List<RankingEntry> ranking;
    ScrollController controller;

    switch (tabIndex) {
      case 0:
        ranking = easyRanking;
        controller = _easyScrollController;
        break;
      case 1:
        ranking = mediumRanking;
        controller = _mediumScrollController;
        break;
      case 2:
        ranking = hardRanking;
        controller = _hardScrollController;
        break;
      default:
        return;
    }

    if (ranking.isEmpty || !controller.hasClients) return;

    // 내 순위 찾기
    final myIndex = ranking.take(100).toList().indexWhere((entry) => entry.isMe);
    if (myIndex == -1) return; // 내가 100위 안에 없으면 스크롤 안 함

    // ListTile 높이는 약 56
    const itemHeight = 56.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final visibleHeight = screenHeight - 200; // AppBar, TabBar 등 제외

    // 화면 중앙에 오도록 계산
    final targetOffset = (myIndex * itemHeight) - (visibleHeight / 2) + (itemHeight / 2);
    final maxScroll = controller.position.maxScrollExtent;

    // 스크롤 범위 내로 제한
    final scrollOffset = targetOffset.clamp(0.0, maxScroll);

    controller.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _easyScrollController.dispose();
    _mediumScrollController.dispose();
    _hardScrollController.dispose();
    super.dispose();
  }

  String _formatScore(int score) {
    // 3자리마다 쉼표 추가
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

  Widget _buildRankingList(List<RankingEntry> ranking, ScrollController controller) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (ranking.isEmpty) {
      return const Center(
        child: Text('랭킹 데이터가 없습니다.'),
      );
    }

    // 상위 100명만 표시
    final displayRanking = ranking.take(100).toList();

    return RefreshIndicator(
      onRefresh: _loadRankings,
      child: ListView.builder(
        controller: controller,
        itemCount: displayRanking.length,
        itemBuilder: (context, index) {
          final entry = displayRanking[index];

          return Container(
            color: entry.isMe ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: SizedBox(
                width: 40,
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontSize: entry.rank <= 3 ? 20 : 16,
                    fontWeight: entry.rank <= 3 ? FontWeight.bold : FontWeight.normal,
                    color: entry.rank == 1
                        ? Colors.amber.shade700
                        : entry.rank == 2
                            ? Colors.grey.shade600
                            : entry.rank == 3
                                ? Colors.brown.shade400
                                : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              title: Row(
                children: [
                  if (entry.rank <= 3)
                    Icon(
                      Icons.emoji_events,
                      size: 20,
                      color: entry.rank == 1
                          ? Colors.amber.shade700
                          : entry.rank == 2
                              ? Colors.grey.shade600
                              : Colors.brown.shade400,
                    ),
                  if (entry.rank <= 3) const SizedBox(width: 4),
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: entry.isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                _formatScore(entry.score),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: entry.isMe ? FontWeight.bold : FontWeight.normal,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('랭킹'),
                  Text(
                    _timeRemaining,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events),
                    tooltip: '랭킹 히스토리',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '초급'),
                  Tab(text: '중급'),
                  Tab(text: '고급'),
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
                color: Theme.of(context).colorScheme.inversePrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '랭킹',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _timeRemaining,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_events),
                      tooltip: '랭킹 히스토리',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RankingHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          // TabBar (showAppBar가 false일 때)
          if (!widget.showAppBar)
            Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '초급'),
                  Tab(text: '중급'),
                  Tab(text: '고급'),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRankingList(easyRanking, _easyScrollController),
                _buildRankingList(mediumRanking, _mediumScrollController),
                _buildRankingList(hardRanking, _hardScrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
