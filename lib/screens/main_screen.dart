import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'daily_mission_screen.dart';
import 'ranking_screen.dart';
import 'statistics_screen.dart';
import '../utils/ranking_badge_helper.dart';
import '../utils/daily_mission_badge_helper.dart';
import '../l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _showRankingBadge = false;
  bool _showDailyMissionBadge = false;
  int _rankingRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadBadgeStatus();
  }

  Future<void> _loadBadgeStatus() async {
    final showRanking = await RankingBadgeHelper.shouldShowBadge();
    final showDailyMission = await DailyMissionBadgeHelper.shouldShowBadge();
    setState(() {
      _showRankingBadge = showRanking;
      _showDailyMissionBadge = showDailyMission;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) async {
    // 일일 미션 탭(index 1)으로 이동하면 배지 비활성화
    if (index == 1 && _showDailyMissionBadge) {
      await DailyMissionBadgeHelper.deactivateBadge();
      setState(() {
        _showDailyMissionBadge = false;
      });
    }

    // 랭킹 탭(index 2)으로 이동하면 배지 비활성화 및 새로고침
    if (index == 2) {
      if (_showRankingBadge) {
        await RankingBadgeHelper.deactivateBadge();
      }
      setState(() {
        _showRankingBadge = false;
        _rankingRefreshKey++; // 랭킹 화면 새로고침 트리거
      });
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 배지 상태 확인 및 랭킹 새로고침
    _loadBadgeStatus();
    // 랭킹 화면 새로고침 (유저가 게임 완료 후 돌아왔을 때)
    setState(() {
      _rankingRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 스와이프로 페이지 변경 방지
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          WelcomeScreen(
            showAppBar: false,
            onNavigate: _onTabTapped,
          ),
          const DailyMissionScreen(showAppBar: false),
          RankingScreen(
            key: ValueKey(_rankingRefreshKey),
            showAppBar: false,
          ),
          const StatisticsScreen(showAppBar: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 28),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 26),
                    if (_showDailyMissionBadge)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: l10n.dailyMission,
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 28),
                    if (_showRankingBadge)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: l10n.ranking,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart_rounded, size: 28),
                label: l10n.statistics,
              ),
            ],
            selectedItemColor: const Color(0xFFE91E63),
            unselectedItemColor: const Color(0xFF8B7580),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }
}
