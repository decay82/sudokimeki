import 'package:flutter/material.dart';
import '../utils/daily_mission_storage.dart';
import '../utils/ad_helper.dart';
import '../data/puzzle_data.dart';
import 'dart:math';
import 'sudoku_screen.dart';
import 'collection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyMissionScreen extends StatefulWidget {
  final bool showAppBar;

  const DailyMissionScreen({super.key, this.showAppBar = true});

  @override
  State<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _DailyMissionScreenState extends State<DailyMissionScreen> {
  late DateTime _currentMonth;
  Map<String, DailyMissionData> _missions = {};
  String? _selectedDate;
  bool _isLoading = true;
  bool _hasTrophy = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 마지막 방문 월 불러오기
    final lastVisitedYear = prefs.getInt('last_visited_year');
    final lastVisitedMonth = prefs.getInt('last_visited_month');

    if (lastVisitedYear != null && lastVisitedMonth != null) {
      _currentMonth = DateTime(lastVisitedYear, lastVisitedMonth, 1);
    } else {
      // 처음 접속 시 오늘이 속한 월로 시작
      _currentMonth = DateTime(now.year, now.month, 1);
    }

    await _loadMissions();

    // 선택된 날짜 설정 로직
    await _setInitialSelectedDate(prefs, now);
  }

  Future<void> _setInitialSelectedDate(SharedPreferences prefs, DateTime now) async {
    final lastSelectedDate = prefs.getString('last_selected_date');

    // 마지막으로 선택했던 날짜가 완료된 미션인지 확인
    if (lastSelectedDate != null) {
      final lastMission = _missions[lastSelectedDate];
      if (lastMission != null && lastMission.status == DayStatus.completed) {
        setState(() => _selectedDate = lastSelectedDate);
        return;
      }
    }

    // 완료된 미션이 없으면 오늘 날짜가 현재 월에 있는지 확인
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
      final todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      setState(() => _selectedDate = todayString);
      await prefs.setString('last_selected_date', todayString);
    }
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);

    final missions = await DailyMissionStorage.loadMonthMissions(
      _currentMonth.year,
      _currentMonth.month,
    );

    final hasTrophy = await DailyMissionStorage.hasTrophy(
      _currentMonth.year,
      _currentMonth.month,
    );

    // 월 완료 확인 및 트로피 자동 부여
    if (!hasTrophy) {
      final isCompleted = await DailyMissionStorage.isMonthCompleted(
        _currentMonth.year,
        _currentMonth.month,
      );
      if (isCompleted) {
        await DailyMissionStorage.saveTrophy(_currentMonth.year, _currentMonth.month);
        setState(() => _hasTrophy = true);
      } else {
        setState(() => _hasTrophy = false);
      }
    } else {
      setState(() => _hasTrophy = hasTrophy);
    }

    // 마지막 방문 월 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_visited_year', _currentMonth.year);
    await prefs.setInt('last_visited_month', _currentMonth.month);

    setState(() {
      _missions = missions;
      _isLoading = false;
    });
  }

  // 테스트용: 현재 월 전체 완료 처리
  // Future<void> _fillCurrentMonthForTest() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('테스트 데이터 생성'),
  //       content: Text(
  //         '${_currentMonth.year}년 ${_currentMonth.month}월의\n모든 일일 미션을 완료 처리하시겠습니까?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('취소'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('확인'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed != true) return;

  //   setState(() => _isLoading = true);

  //   final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  //   // 모든 날짜를 완료 처리
  //   for (int day = 1; day <= daysInMonth; day++) {
  //     final dateString = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  //     await DailyMissionStorage.completeMission(dateString, 'easy', 0);
  //   }

  //   // 트로피 부여
  //   await DailyMissionStorage.saveTrophy(_currentMonth.year, _currentMonth.month);

  //   // 데이터 새로고침
  //   await _loadMissions();

  //   if (!mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('${_currentMonth.year}년 ${_currentMonth.month}월 전체 완료 처리되었습니다!'),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  // }

  void _previousMonth() {
    // 2025년 10월 이전으로 갈 수 없음 (일일 미션 시작 월)
    if (_currentMonth.year == 2025 && _currentMonth.month == 10) {
      return;
    }

    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDate = null;
    });
    _loadMissions();
  }

  void _nextMonth() {
    final now = DateTime.now();
    // 현재 월 이후로 갈 수 없음
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
      return;
    }

    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDate = null;
    });
    _loadMissions();
  }

  DayStatus _getDayStatus(int day) {
    final dateString = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final mission = _missions[dateString];

    if (mission != null) {
      return mission.status;
    }

    // 일일 미션 시작 날짜: 2025년 10월 1일
    final missionStartDate = DateTime(2025, 10, 1);
    final now = DateTime.now();
    final currentDate = DateTime(_currentMonth.year, _currentMonth.month, day);

    // 미션 시작일 이전은 locked
    if (currentDate.isBefore(missionStartDate)) {
      return DayStatus.locked;
    }

    // 오늘 이후는 locked
    if (currentDate.isAfter(now)) {
      return DayStatus.locked;
    }

    return DayStatus.available;
  }

  Color _getStatusColor(DayStatus status) {
    switch (status) {
      case DayStatus.locked:
        return Colors.transparent;
      case DayStatus.available:
        return Colors.transparent;
      case DayStatus.inProgress:
        return Colors.purple;
      case DayStatus.completed:
        return Colors.blue;
    }
  }

  Color _getTextColor(DayStatus status) {
    switch (status) {
      case DayStatus.locked:
        return const Color(0xFFD4D5DA);
      case DayStatus.available:
        return const Color(0xFF25292E);
      case DayStatus.inProgress:
        return Colors.white;
      case DayStatus.completed:
        return Colors.white;
    }
  }

  void _onDayTapped(int day) async {
    final status = _getDayStatus(day);

    if (status == DayStatus.locked) {
      return;
    }

    final dateString = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    setState(() {
      _selectedDate = dateString;
    });

    // 선택한 날짜 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_date', dateString);
  }

  Future<void> _onPlayButtonPressed() async {
    if (_selectedDate == null) return;

    final mission = _missions[_selectedDate!];
    final now = DateTime.now();
    final selectedDateTime = DateTime.parse(_selectedDate!.replaceAll('-', ''));
    final isToday = selectedDateTime.year == now.year &&
        selectedDateTime.month == now.month &&
        selectedDateTime.day == now.day;

    // 과거 일자면 광고 먼저 표시
    if (!isToday) {
      final interstitialAd = AdHelper.getPreloadedInterstitialAd();
      if (interstitialAd != null) {
        await interstitialAd.show();
      }
    }

    // 진행중인 미션이 있으면 이어하기
    if (mission != null && mission.status == DayStatus.inProgress) {
      if (!mounted) return;
      _resumeMission(mission);
      return;
    }

    // 새로 시작하면 난이도 선택
    if (!mounted) return;
    _showDifficultyDialog();
  }

  void _resumeMission(DailyMissionData mission) {
    // 저장된 게임 상태로 SudokuScreen 열기
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuScreen(
          difficulty: mission.difficulty!,
          isDailyMission: true,
          dailyMissionDate: mission.date,
          puzzleNumber: mission.puzzleNumber,
          savedBoard: mission.savedBoard,
          savedCorrectCells: mission.savedCorrectCells,
          savedElapsedSeconds: mission.elapsedSeconds ?? 0,
        ),
      ),
    ).then((_) => _loadMissions());
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyButton('입문자', 'beginner', Colors.lightBlue),
            const SizedBox(height: 8),
            _buildDifficultyButton('초보자', 'rookie', Colors.cyan),
            const SizedBox(height: 8),
            _buildDifficultyButton('초급', 'easy', Colors.green),
            const SizedBox(height: 8),
            _buildDifficultyButton('중급', 'medium', Colors.orange),
            const SizedBox(height: 8),
            _buildDifficultyButton('고급', 'hard', Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyButton(String label, String difficulty, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.pop(context);
          _startMission(difficulty);
        },
        child: Text(label),
      ),
    );
  }

  void _startMission(String difficulty) async {
    if (_selectedDate == null) return;

    // 해당 난이도의 퍼즐 중 랜덤 선택
    final puzzleNumbers = PuzzleData.getPuzzlesByDifficulty(difficulty);
    final random = Random();
    final puzzleNumber = puzzleNumbers[random.nextInt(puzzleNumbers.length)];

    // 미션 시작 저장
    await DailyMissionStorage.startMission(_selectedDate!, difficulty, puzzleNumber);

    if (!mounted) return;

    // SudokuScreen으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuScreen(
          difficulty: difficulty,
          isDailyMission: true,
          dailyMissionDate: _selectedDate,
          puzzleNumber: puzzleNumber,
        ),
      ),
    ).then((_) => _loadMissions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('일일 미션'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.emoji_events),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CollectionScreen(),
                      ),
                    ).then((_) => _loadMissions());
                  },
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // 상단 타이틀 및 콜렉션 버튼
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '일일 미션',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 디버그 버튼 (테스트용)
                          // IconButton(
                          //   icon: const Icon(Icons.bug_report, size: 20, color: Colors.grey),
                          //   onPressed: _fillCurrentMonthForTest,
                          //   tooltip: '테스트: 현재 월 전체 완료',
                          // ),
                          IconButton(
                            icon: const Icon(Icons.emoji_events, size: 28),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CollectionScreen(),
                                ),
                              ).then((_) => _loadMissions());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 트로피 표시 영역
                Builder(
                  builder: (context) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final isSmallScreen = screenHeight < 700;
                    final iconSize = isSmallScreen ? 80.0 : 128.0;
                    final verticalPadding = 16.0;
                    final spacingHeight = 16.0;
                    final bottomSpacing = 8.0;

                    return Container(
                      padding: EdgeInsets.all(verticalPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 이전 월 버튼
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: (_currentMonth.year == 2025 && _currentMonth.month == 10)
                                    ? null
                                    : _previousMonth,
                              ),
                              // 월 표시
                              Text(
                                '${_currentMonth.year}년 ${_currentMonth.month}월',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              // 다음 월 버튼
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  final now = DateTime.now();
                                  if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
                                    return;
                                  }
                                  _nextMonth();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: spacingHeight),
                          // 트로피 (화면 크기에 따라 동적 크기)
                          Icon(
                            Icons.emoji_events,
                            size: iconSize,
                            color: _hasTrophy ? Colors.amber : Colors.grey.shade300,
                          ),
                          SizedBox(height: bottomSpacing),
                          Text(
                            _hasTrophy ? '완료' : '모든 미션을 클리어하세요',
                            style: TextStyle(
                              fontSize: 16,
                              color: _hasTrophy ? Colors.amber : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // 달력
                Expanded(
                  child: _buildCalendar(),
                ),
                // 플레이 버튼
                if (_selectedDate != null) _buildPlayButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비가 350px를 넘으면 더 이상 커지지 않도록 제한
        final screenWidth = constraints.maxWidth;
        final maxCalendarWidth = screenWidth > 350 ? 350.0 : screenWidth * 0.9;
        final cellSize = maxCalendarWidth / 7;

        return Center(
          child: SizedBox(
            width: maxCalendarWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 요일 헤더
                SizedBox(
                  height: cellSize * 0.8, // 요일 헤더 높이 조정
                  child: Row(
                    children: [
                      for (final day in ['일', '월', '화', '수', '목', '금', '토'])
                        Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB0B2B7),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 날짜 그리드
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: cellSize, // 셀의 높이를 명시적으로 설정
                  ),
                  itemCount: firstWeekday % 7 + daysInMonth,
                  itemBuilder: (context, index) {
                    final offset = firstWeekday % 7;

                    if (index < offset) {
                      return const SizedBox();
                    }

                    final day = index - offset + 1;
                    final status = _getDayStatus(day);
                    final dateString = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final isSelected = _selectedDate == dateString;

                    return GestureDetector(
                      onTap: () => _onDayTapped(day),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(status),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDifficultyText(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return '입문자';
      case 'rookie':
        return '초보자';
      case 'easy':
        return '초급';
      case 'medium':
        return '중급';
      case 'hard':
        return '고급';
      default:
        return '알 수 없음';
    }
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayButton() {
    final now = DateTime.now();
    final selectedDateTime = DateTime.parse(_selectedDate!.replaceAll('-', ''));
    final isToday = selectedDateTime.year == now.year &&
        selectedDateTime.month == now.month &&
        selectedDateTime.day == now.day;

    final mission = _missions[_selectedDate!];
    final isCompleted = mission?.status == DayStatus.completed;

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(top: BorderSide(color: Colors.blue.shade200, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '완료된 미션',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      '난이도',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDifficultyText(mission?.difficulty),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Column(
                  children: [
                    const Text(
                      '클리어 시간',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(mission?.elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _onPlayButtonPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isToday) ...[
              const Icon(Icons.play_circle_outline),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.play_arrow),
            const SizedBox(width: 8),
            const Text('플레이', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
