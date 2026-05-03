// lib/screens/student/student_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/app_router.dart';
import '../../widgets/goal_progress_card.dart';
import '../../widgets/deposit_tile.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.splash));
          return const Scaffold(body: SizedBox.shrink());
        }

        final userId = user.id;
        final balanceAsync = ref.watch(totalBalanceProvider(userId));
        final goalsAsync = ref.watch(goalsProvider(userId));
        final recentAsync = ref.watch(recentDepositsProvider(userId));
        final streakAsync = ref.watch(streakProvider(userId));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Header with balance ──────────────────────────────────
              SliverToBoxAdapter(
                child: _DashboardHeader(
                  userName: user.name,
                  balanceAsync: balanceAsync,
                  streakAsync: streakAsync,
                ),
              ),

              // ── Streak Banner ────────────────────────────────────────
              SliverToBoxAdapter(
                child: streakAsync.when(
                  data: (streak) => streak > 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: StreakBanner(streak: streak),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ── Active Goals ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Mga Goals Ko',
                  subtitle: 'My Goals',
                  actionLabel: 'See All',
                  onAction: () => context.push(AppRoutes.goals),
                ),
              ),

              goalsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
                data: (goals) {
                  final active = goals.where((g) => g.status == 'active').toList();
                  if (active.isEmpty) {
                    return SliverToBoxAdapter(child: _EmptyGoals(
                      onCreateGoal: () => context.push(AppRoutes.createGoal),
                    ));
                  }
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: active.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => GoalProgressCard(goal: active[i]),
                      ),
                    ),
                  );
                },
              ),

              // ── Recent Transactions ───────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Huling Ipon',
                  subtitle: 'Recent Deposits',
                  actionLabel: 'See All',
                  onAction: () => context.push(AppRoutes.depositLog),
                ),
              ),

              recentAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
                data: (deposits) {
                  if (deposits.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyDeposits());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DepositTile(deposit: deposits[i]),
                      ),
                      childCount: deposits.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Bottom Nav ───────────────────────────────────────────────
          bottomNavigationBar: _StudentBottomNav(currentIndex: 0),

          // ── FAB — Add Deposit ─────────────────────────────────────────
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.addDeposit),
            backgroundColor: AppColors.philippineBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Mag-ipon',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

// ── Dashboard Header Widget ────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final AsyncValue<double> balanceAsync;
  final AsyncValue<int> streakAsync;

  const _DashboardHeader({
    required this.userName,
    required this.balanceAsync,
    required this.streakAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.philippineBlue, AppColors.blueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + avatar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    userName.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.philippineYellow,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'I',
                  style: const TextStyle(
                      color: AppColors.philippineBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Balance display
          const Text(
            'Kabuuang Ipon  •  Total Savings',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          balanceAsync.when(
            data: (balance) => Text(
              PesoFormatter.format(balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1),
            ),
            loading: () => const Text(
              '₱ ——',
              style: TextStyle(color: Colors.white54, fontSize: 38),
            ),
            error: (_, __) => const Text(
              '₱ —',
              style: TextStyle(color: Colors.white54, fontSize: 38),
            ),
          ),

          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.flag_rounded,
                label: 'Active Goals',
                color: AppColors.philippineYellow,
              ),
              const SizedBox(width: 10),
              streakAsync.when(
                data: (streak) => streak > 0
                    ? _StatChip(
                        icon: Icons.local_fire_department_rounded,
                        label: '$streak day streak 🔥',
                        color: Colors.orange,
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Magandang umaga! ☀️';
    if (hour < 17) return 'Magandang tanghali! 🌤️';
    return 'Magandang gabi! 🌙';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.philippineBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(actionLabel!,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ── Empty States ────────────────────────────────────────────────────────────

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onCreateGoal;
  const _EmptyGoals({required this.onCreateGoal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: onCreateGoal,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.blueSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.philippineBlue.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Walang goals pa!',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Gumawa ng goal mo ngayon →',
                        style: TextStyle(
                            color: AppColors.philippineBlue, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDeposits extends StatelessWidget {
  const _EmptyDeposits();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Text('💰', style: TextStyle(fontSize: 28)),
            SizedBox(width: 16),
            Text('Wala pang naka-log na ipon.\nMag-ipon na tayo!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation ───────────────────────────────────────────────────────

class _StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  const _StudentBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.studentDashboard); break;
          case 1: context.push(AppRoutes.goals); break;
          case 2: context.push(AppRoutes.depositLog); break;
          case 3: context.push(AppRoutes.badges); break;
          case 4: context.push(AppRoutes.profile); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'Goals'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Badges'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
