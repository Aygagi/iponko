// lib/screens/student/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/goal_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/app_router.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteGoal(String userId, GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Burahin ang "${goal.name}"?'),
        content: const Text(
            'Mawawala ang goal na ito at lahat ng deposits na naka-link dito ay magiging unallocated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huwag'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Burahin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(goalNotifierProvider(userId).notifier).deleteGoal(goal.id);
      ref.invalidate(goalsProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${goal.emoji ?? '🎯'} "${goal.name}" nabura na.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
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

        final goalsAsync = ref.watch(goalNotifierProvider(user.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mga Goals Ko 🎯'),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.philippineBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.philippineBlue,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Archived'),
              ],
            ),
          ),

          body: goalsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (goals) {
              final active =
                  goals.where((g) => g.status == 'active').toList();
              final completed =
                  goals.where((g) => g.status == 'completed').toList();
              final archived =
                  goals.where((g) => g.status == 'archived').toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _GoalsList(
                    goals: active,
                    userId: user.id,
                    emptyEmoji: '🎯',
                    emptyTitle: 'Walang active goals!',
                    emptySubtitle: 'Gumawa ng bagong goal para magsimula.',
                    showAddButton: true,
                    onDelete: (g) => _deleteGoal(user.id, g),
                    onAddDeposit: (goalId) =>
                        context.push(AppRoutes.addDeposit, extra: goalId),
                  ),
                  _GoalsList(
                    goals: completed,
                    userId: user.id,
                    emptyEmoji: '🏆',
                    emptyTitle: 'Wala pang completed goals.',
                    emptySubtitle: 'Mag-ipon ka para maabot ang iyong goals!',
                    showAddButton: false,
                    onDelete: (g) => _deleteGoal(user.id, g),
                    onAddDeposit: (_) {},
                  ),
                  _GoalsList(
                    goals: archived,
                    userId: user.id,
                    emptyEmoji: '📦',
                    emptyTitle: 'Walang archived goals.',
                    emptySubtitle: '',
                    showAddButton: false,
                    onDelete: (g) => _deleteGoal(user.id, g),
                    onAddDeposit: (_) {},
                  ),
                ],
              );
            },
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.createGoal),
            backgroundColor: AppColors.philippineBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Bagong Goal',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

// ── Goals List ────────────────────────────────────────────────────────────────

class _GoalsList extends StatelessWidget {
  final List<GoalModel> goals;
  final String userId;
  final String emptyEmoji;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showAddButton;
  final ValueChanged<GoalModel> onDelete;
  final ValueChanged<String> onAddDeposit;

  const _GoalsList({
    required this.goals,
    required this.userId,
    required this.emptyEmoji,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showAddButton,
    required this.onDelete,
    required this.onAddDeposit,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _EmptyState(
        emoji: emptyEmoji,
        title: emptyTitle,
        subtitle: emptySubtitle,
        showAddButton: showAddButton,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: goals.length,
      itemBuilder: (_, i) => Dismissible(
        key: Key(goals[i].id),
        direction: DismissDirection.endToStart,
        background: _SwipeDeleteBackground(),
        confirmDismiss: (_) async {
          onDelete(goals[i]);
          return false; // We handle deletion manually
        },
        child: _GoalCard(
          goal: goals[i],
          onAddDeposit: () => onAddDeposit(goals[i].id),
        ),
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onAddDeposit;

  const _GoalCard({required this.goal, required this.onAddDeposit});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent;
    final isCompleted = goal.isCompleted;
    final isOverdue =
        goal.daysRemaining < 0 && goal.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main Content ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.successSurface
                            : AppColors.blueSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(goal.emoji ?? '🎯',
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isCompleted)
                                _StatusChip(
                                    label: 'Completed! 🎉',
                                    color: AppColors.success)
                              else if (isOverdue)
                                _StatusChip(
                                    label: 'Overdue ⚠️',
                                    color: AppColors.error)
                              else
                                Text(
                                  '${goal.daysRemaining} araw na natitira',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Percent badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.successSurface
                            : AppColors.blueSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.philippineBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                LinearPercentIndicator(
                  percent: progress,
                  lineHeight: 10,
                  backgroundColor: AppColors.blueSurface,
                  progressColor: isCompleted
                      ? AppColors.success
                      : isOverdue
                          ? AppColors.error
                          : AppColors.philippineBlue,
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 600,
                ),

                const SizedBox(height: 12),

                // Amount row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Na-ipon',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          PesoFormatter.format(goal.currentAmount),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.philippineBlue),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Kulang pa',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          PesoFormatter.format(goal.remainingAmount),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Target',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          PesoFormatter.format(goal.targetAmount),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),

                // Daily savings hint
                if (!isCompleted && goal.daysRemaining > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.yellowSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💡',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          'Mag-ipon ng ${PesoFormatter.format(goal.requiredDailySavings)}/araw para maabot',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Action Row ─────────────────────────────────────────────
          if (goal.status == 'active')
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 1)),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20)),
              ),
              child: TextButton.icon(
                onPressed: onAddDeposit,
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.philippineBlue),
                label: const Text(
                  'Mag-ipon para dito',
                  style: TextStyle(
                      color: AppColors.philippineBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Swipe Delete Background ───────────────────────────────────────────────────

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text('Burahin',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool showAddButton;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.showAddButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
            if (showAddButton) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createGoal),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Gumawa ng Goal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
