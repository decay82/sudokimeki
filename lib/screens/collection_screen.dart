import 'package:flutter/material.dart';
import '../utils/daily_mission_storage.dart';
import '../l10n/app_localizations.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Set<String> _trophies = {};
  Map<String, Map<String, int>> _monthlyStats = {}; // year-month -> {completed, total}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final trophies = await DailyMissionStorage.loadTrophies();
    final stats = await _loadMonthlyStats();

    setState(() {
      _trophies = trophies;
      _monthlyStats = stats;
      _isLoading = false;
    });
  }

  Future<Map<String, Map<String, int>>> _loadMonthlyStats() async {
    final now = DateTime.now();
    final startMonth = DateTime(2025, 10); // 일일 미션 시작: 2025년 10월
    final stats = <String, Map<String, int>>{};

    DateTime current = startMonth;
    while (current.isBefore(now) ||
           (current.year == now.year && current.month == now.month)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}';
      final missions = await DailyMissionStorage.loadMonthMissions(
        current.year,
        current.month,
      );

      int completed = 0;
      int total = 0;

      // 해당 월의 모든 날짜 확인 (완료된 미션 수를 정확히 계산)
      final daysInMonth = DateTime(current.year, current.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final dateString = '${current.year}-${current.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final mission = missions[dateString];
        if (mission != null && mission.status == DayStatus.completed) {
          completed++;
        }
      }

      total = daysInMonth;

      stats[key] = {'completed': completed, 'total': total};
      current = DateTime(current.year, current.month + 1);
    }

    return stats;
  }

  Map<int, List<String>> _groupMonthsByYear() {
    final now = DateTime.now();
    final startMonth = DateTime(2025, 10); // 일일 미션 시작: 2025년 10월
    final grouped = <int, List<String>>{};

    DateTime current = startMonth;
    while (current.isBefore(now) ||
           (current.year == now.year && current.month == now.month)) {
      final year = current.year;
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(year)) {
        grouped[year] = [];
      }
      grouped[year]!.add(key);

      current = DateTime(current.year, current.month + 1);
    }

    // 각 년도의 월을 최신순으로 정렬
    grouped.forEach((year, months) {
      months.sort((a, b) => b.compareTo(a));
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.trophyCollection),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final groupedMonths = _groupMonthsByYear();
    final years = groupedMonths.keys.toList()..sort((a, b) => b.compareTo(a)); // 최신 년도 먼저

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trophyCollection),
      ),
      body: years.isEmpty
          ? Center(
              child: Text(
                l10n.noDailyMissionsYet,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: years.length,
              itemBuilder: (context, yearIndex) {
                final year = years[yearIndex];
                final months = groupedMonths[year]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 년도 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '$year년',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 월별 트로피 그리드
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: months.length,
                      itemBuilder: (context, monthIndex) {
                        final monthKey = months[monthIndex];
                        final hasTrophy = _trophies.contains(monthKey);
                        final parts = monthKey.split('-');
                        final month = int.parse(parts[1]);
                        final stats = _monthlyStats[monthKey] ?? {'completed': 0, 'total': 0};
                        final completed = stats['completed'] ?? 0;
                        final total = stats['total'] ?? 0;

                        return Card(
                          elevation: hasTrophy ? 8 : 2,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final dialogL10n = AppLocalizations.of(context)!;
                                  return AlertDialog(
                                    title: Text(dialogL10n.yearMonth(year, month)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 80,
                                          color: hasTrophy ? Colors.amber : Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          hasTrophy ? dialogL10n.completed : dialogL10n.inProgress,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$completed / $total ${dialogL10n.completedMission}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        if (hasTrophy) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '${dialogL10n.yearMonth(year, month)}의 모든 일일 미션을\n완료했습니다!',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(dialogL10n.confirm),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 50,
                                    color: hasTrophy ? Colors.amber : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$month월',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: hasTrophy ? Colors.black87 : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completed / $total',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: hasTrophy ? Colors.green : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (yearIndex < years.length - 1) const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }
}
