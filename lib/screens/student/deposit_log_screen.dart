// lib/screens/student/deposit_log_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/deposit_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import '../../utils/formatters.dart';
import '../../widgets/deposit_tile.dart';

class DepositLogScreen extends ConsumerStatefulWidget {
  const DepositLogScreen({super.key});

  @override
  ConsumerState<DepositLogScreen> createState() => _DepositLogScreenState();
}

class _DepositLogScreenState extends ConsumerState<DepositLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterSource = 'all';

  final _sources = [
    {'value': 'all',       'label': 'Lahat',     'emoji': '📊'},
    {'value': 'baon',      'label': 'Baon',       'emoji': '🍱'},
    {'value': 'allowance', 'label': 'Allowance',  'emoji': '💵'},
    {'value': 'gift',      'label': 'Regalo',     'emoji': '🎁'},
    {'value': 'other',     'label': 'Iba pa',     'emoji': '💰'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());

        final depositsAsync = ref.watch(depositNotifierProvider(user.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Deposit Log 📋'),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.philippineBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.philippineBlue,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
          body: depositsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (deposits) {
              final filtered = _filterSource == 'all'
                  ? deposits
                  : deposits
                      .where((d) => d.source == _filterSource)
                      .toList();

              return CustomScrollView(
                slivers: [
                  // ── Chart ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _WeeklyChart(deposits: deposits),
                                _MonthlyChart(deposits: deposits),
                              ],
                            ),
                          ),
                          // Total summary
                          _TotalSummary(deposits: filtered),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Source Filter ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _SourceFilter(
                      sources: _sources,
                      selected: _filterSource,
                      onChanged: (v) =>
                          setState(() => _filterSource = v),
                    ),
                  ),

                  // ── Deposit List ───────────────────────────────────
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      child: _EmptyDeposits(),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filtered.length} deposits',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              _filterSource == 'all'
                                  ? 'Lahat'
                                  : _sources.firstWhere((s) =>
                                      s['value'] ==
                                      _filterSource)['label']!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: DepositTile(deposit: filtered[i]),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 100)),
                  ],
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.addDeposit),
            backgroundColor: AppColors.philippineBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Mag-ipon',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final List<DepositModel> deposits;
  const _WeeklyChart({required this.deposits});

  @override
  Widget build(BuildContext context) {
    // Build last 7 days data
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return DateTime(day.year, day.month, day.day);
    });

    final Map<DateTime, double> totals = {for (var d in days) d: 0.0};
    for (final dep in deposits) {
      final key = DateTime(dep.date.year, dep.date.month, dep.date.day);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + dep.amount;
      }
    }

    final maxY = totals.values.isEmpty
        ? 100.0
        : (totals.values.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(100.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                PesoFormatter.format(rod.toY),
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final day = days[value.toInt()];
                  final isToday = day ==
                      DateTime(now.year, now.month, now.day);
                  return Text(
                    isToday ? 'Today' : DateFormatter.dayLabel(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isToday
                          ? AppColors.philippineBlue
                          : AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (i) {
            final amount = totals[days[i]] ?? 0;
            final isToday = days[i] ==
                DateTime(now.year, now.month, now.day);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: isToday
                      ? AppColors.philippineBlue
                      : AppColors.blueLight.withOpacity(0.5),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Monthly Bar Chart ─────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  final List<DepositModel> deposits;
  const _MonthlyChart({required this.deposits});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Last 6 months
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return DateTime(m.year, m.month);
    });

    final Map<DateTime, double> totals = {for (var m in months) m: 0.0};
    for (final dep in deposits) {
      final key = DateTime(dep.date.year, dep.date.month);
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + dep.amount;
      }
    }

    final maxY = totals.values.isEmpty
        ? 500.0
        : (totals.values.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(500.0, double.infinity);

    final monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                PesoFormatter.format(rod.toY),
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final month = months[value.toInt()];
                  final isCurrent = month.month == now.month &&
                      month.year == now.year;
                  return Text(
                    monthLabels[month.month - 1],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isCurrent
                          ? AppColors.philippineBlue
                          : AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(months.length, (i) {
            final amount = totals[months[i]] ?? 0;
            final isCurrent = months[i].month == now.month &&
                months[i].year == now.year;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: isCurrent
                      ? AppColors.philippineBlue
                      : AppColors.philippineYellow.withOpacity(0.7),
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Total Summary ─────────────────────────────────────────────────────────────

class _TotalSummary extends StatelessWidget {
  final List<DepositModel> deposits;
  const _TotalSummary({required this.deposits});

  @override
  Widget build(BuildContext context) {
    final total =
        deposits.fold<double>(0.0, (sum, d) => sum + d.amount);
    final thisMonth = deposits
        .where((d) =>
            d.date.month == DateTime.now().month &&
            d.date.year == DateTime.now().year)
        .fold<double>(0.0, (sum, d) => sum + d.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              label: 'Kabuuan',
              amount: total,
              color: AppColors.philippineBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryChip(
              label: 'Ngayong buwan',
              amount: thisMonth,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            PesoFormatter.format(amount),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ── Source Filter ─────────────────────────────────────────────────────────────

class _SourceFilter extends StatelessWidget {
  final List<Map<String, String>> sources;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SourceFilter({
    required this.sources,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = sources[i];
          final isSelected = s['value'] == selected;
          return GestureDetector(
            onTap: () => onChanged(s['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.philippineBlue
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.philippineBlue
                      : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['emoji']!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    s['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyDeposits extends StatelessWidget {
  const _EmptyDeposits();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Wala pang deposits.',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'I-log ang iyong unang ipon!',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.addDeposit),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Mag-ipon Ngayon'),
            ),
          ],
        ),
      ),
    );
  }
}
