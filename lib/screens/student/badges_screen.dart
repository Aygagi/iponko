// lib/screens/student/badges_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/badge_model.dart';
import '../../models/deposit_model.dart';
import '../../models/goal_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());

        final depositsAsync = ref.watch(depositNotifierProvider(user.id));
        final goalsAsync = ref.watch(goalNotifierProvider(user.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mga Badges 🏆'),
            centerTitle: false,
          ),
          body: depositsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (deposits) => goalsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (goals) {
                // Compute earned badges from current data
                final earned = _computeEarnedBadges(deposits, goals);
                final allBadges = BadgeDefinitions.all.map((b) {
                  b.isEarned = earned.contains(b.id);
                  return b;
                }).toList();

                final earnedList =
                    allBadges.where((b) => b.isEarned).toList();
                final lockedList =
                    allBadges.where((b) => !b.isEarned).toList();

                return CustomScrollView(
                  slivers: [
                    // ── Progress Header ──────────────────────────
                    SliverToBoxAdapter(
                      child: _BadgeProgressHeader(
                        earned: earnedList.length,
                        total: allBadges.length,
                      ),
                    ),

                    // ── Earned Badges ────────────────────────────
                    if (earnedList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Na-earn na! 🎉',
                          count: earnedList.length,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _BadgeCard(
                              badge: earnedList[i],
                              onTap: () => _showBadgeDetail(
                                  context, earnedList[i]),
                            ),
                            childCount: earnedList.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                        ),
                      ),
                    ],

                    // ── Locked Badges ────────────────────────────
                    if (lockedList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'I-unlock pa 🔒',
                          count: lockedList.length,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _BadgeCard(
                              badge: lockedList[i],
                              onTap: () => _showBadgeDetail(
                                  context, lockedList[i]),
                            ),
                            childCount: lockedList.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 32)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Badge award logic ─────────────────────────────────────────────────────
  Set<String> _computeEarnedBadges(
      List<DepositModel> deposits, List<GoalModel> goals) {
    final earned = <String>{};
    if (deposits.isEmpty) return earned;

    // First deposit
    earned.add('first_deposit');

    // Total savings milestones
    final total =
        deposits.fold<double>(0.0, (sum, d) => sum + d.amount);
    if (total >= 500) earned.add('saved_500');
    if (total >= 1000) earned.add('saved_1000');
    if (total >= 5000) earned.add('saved_5000');

    // Streak badges
    final streak = _computeStreak(deposits);
    if (streak >= 7) earned.add('streak_7');
    if (streak >= 30) earned.add('streak_30');

    // Goal completed
    final hasCompleted =
        goals.any((g) => g.status == 'completed' || g.isCompleted);
    if (hasCompleted) earned.add('goal_complete');

    // 3 active goals at once
    final activeCount =
        goals.where((g) => g.status == 'active').length;
    if (activeCount >= 3 ||
        goals.where((g) => g.status != 'archived').length >= 3) {
      earned.add('multi_goal');
    }

    return earned;
  }

  int _computeStreak(List<DepositModel> deposits) {
    if (deposits.isEmpty) return 0;
    final now = DateTime.now();
    final depositDays = deposits
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime check =
        DateTime(now.year, now.month, now.day);
    for (final day in depositDays) {
      if (day == check ||
          day == check.subtract(const Duration(days: 1))) {
        streak++;
        check = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  void _showBadgeDetail(BuildContext context, BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgeDetailSheet(badge: badge),
    );
  }
}

// ── Badge Progress Header ─────────────────────────────────────────────────────

class _BadgeProgressHeader extends StatelessWidget {
  final int earned;
  final int total;
  const _BadgeProgressHeader(
      {required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? earned / total : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.philippineBlue, AppColors.blueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Badge Collection',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  Text(
                    '$earned sa $total badges na-unlock',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(
                  AppColors.philippineYellow),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            earned == total
                ? '🎉 Kumpleto na! Ikaw na!'
                : '${total - earned} badges pa ang kailangan mo!',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blueSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.philippineBlue)),
          ),
        ],
      ),
    );
  }
}

// ── Badge Card ────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback onTap;
  const _BadgeCard({required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: badge.isEarned ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isEarned
                ? AppColors.philippineYellow
                : AppColors.divider,
            width: badge.isEarned ? 2 : 1,
          ),
          boxShadow: badge.isEarned
              ? [
                  BoxShadow(
                    color: AppColors.philippineYellow.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji with lock overlay if locked
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 36,
                          color: badge.isEarned
                              ? null
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      if (!badge.isEarned)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                Colors.grey.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.grey, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: badge.isEarned
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Earned checkmark
            if (badge.isEarned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Detail Bottom Sheet ─────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeDetailSheet({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Emoji
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? AppColors.yellowSurface
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge.isEarned
                        ? AppColors.philippineYellow
                        : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 40,
                      color: badge.isEarned
                          ? null
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              if (!badge.isEarned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              if (badge.isEarned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            badge.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: badge.isEarned
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.description,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badge.isEarned
                  ? AppColors.successSurface
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badge.isEarned
                    ? AppColors.success
                    : AppColors.divider,
              ),
            ),
            child: Text(
              badge.isEarned
                  ? '✅ Na-earn mo na ito!'
                  : '🔒 Hindi pa na-unlock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: badge.isEarned
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Isara'),
            ),
          ),
        ],
      ),
    );
  }
}
