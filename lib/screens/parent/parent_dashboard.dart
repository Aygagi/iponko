// lib/screens/parent/parent_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/deposit_model.dart';
import '../../models/goal_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import '../../utils/formatters.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.go(AppRoutes.splash));
          return const Scaffold(body: SizedBox.shrink());
        }

        // For offline demo: use demo child ID
        // When Jhed's backend is ready, this comes from user.linkedChildId
        const demoChildId = 'demo_student_001';
        final childId = user.linkedChildId ?? demoChildId;

        final depositsAsync = ref.watch(depositNotifierProvider(childId));
        final goalsAsync = ref.watch(goalNotifierProvider(childId));
        final balanceAsync = ref.watch(totalBalanceProvider(childId));
        final streakAsync = ref.watch(streakProvider(childId));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ParentHeader(parent: user),
              ),

              // ── Child Overview Card ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _ChildOverviewCard(
                    balanceAsync: balanceAsync,
                    streakAsync: streakAsync,
                    goalsAsync: goalsAsync,
                    depositsAsync: depositsAsync,
                  ),
                ),
              ),

              // ── Pending Approvals ─────────────────────────────────
              depositsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (deposits) {
                  final pending = deposits
                      .where((d) => !d.isApprovedByParent)
                      .toList();
                  if (pending.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _PendingApprovals(
                      deposits: pending,
                      onApprove: (deposit) async {
                        final repo = ref.read(repositoryProvider);
                        deposit.isApprovedByParent = true;
                        await repo.saveDeposit(deposit);
                        ref.invalidate(
                            depositNotifierProvider(childId));
                      },
                    ),
                  );
                },
              ),

              // ── Active Goals ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                    label: 'Mga Goals ni Anak', sublabel: 'Active Goals'),
              ),
              goalsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (goals) {
                  final active =
                      goals.where((g) => g.status == 'active').toList();
                  if (active.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptySection(
                          message: 'Wala pang active goals ang anak mo.'),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: _ParentGoalTile(goal: active[i]),
                      ),
                      childCount: active.length,
                    ),
                  );
                },
              ),

              // ── Recent Activity ───────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                    label: 'Kamakailang Activity',
                    sublabel: 'Recent deposits'),
              ),
              depositsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (deposits) {
                  final recent = deposits.take(5).toList();
                  if (recent.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptySection(
                          message:
                              'Wala pang na-log na deposits ang anak mo.'),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: _ActivityTile(deposit: recent[i]),
                      ),
                      childCount: recent.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),

          bottomNavigationBar: _ParentBottomNav(),
        );
      },
    );
  }
}

// ── Parent Header ─────────────────────────────────────────────────────────────

class _ParentHeader extends StatelessWidget {
  final UserModel parent;
  const _ParentHeader({required this.parent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003580), AppColors.philippineBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 20, 24, 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Parent Dashboard',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text(
                'Kumusta, ${parent.name.split(' ').first}! 👋',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text('Subaybayan ang ipon ng iyong anak.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const Spacer(),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.philippineYellow,
            child: Text(
              parent.name.isNotEmpty
                  ? parent.name[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                  color: AppColors.philippineBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Child Overview Card ───────────────────────────────────────────────────────

class _ChildOverviewCard extends StatelessWidget {
  final AsyncValue<double> balanceAsync;
  final AsyncValue<int> streakAsync;
  final AsyncValue<List<GoalModel>> goalsAsync;
  final AsyncValue<List<DepositModel>> depositsAsync;

  const _ChildOverviewCard({
    required this.balanceAsync,
    required this.streakAsync,
    required this.goalsAsync,
    required this.depositsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎒', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text('Iyong Anak',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Kabuuang Ipon',
                  value: balanceAsync.when(
                    data: (b) => PesoFormatter.format(b),
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: AppColors.philippineBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Streak',
                  value: streakAsync.when(
                    data: (s) => '$s araw 🔥',
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Active Goals',
                  value: goalsAsync.when(
                    data: (g) =>
                        '${g.where((g) => g.status == 'active').length}',
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Pending Approvals ─────────────────────────────────────────────────────────

class _PendingApprovals extends StatelessWidget {
  final List<DepositModel> deposits;
  final ValueChanged<DepositModel> onApprove;

  const _PendingApprovals(
      {required this.deposits, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏳',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${deposits.length} Pending Approval',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...deposits.map((d) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: _ApprovalTile(
                  deposit: d, onApprove: () => onApprove(d)),
            )),
      ],
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final DepositModel deposit;
  final VoidCallback onApprove;

  const _ApprovalTile(
      {required this.deposit, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSurface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.philippineYellow, width: 1.5),
      ),
      child: Row(
        children: [
          Text(_sourceEmoji(deposit.source),
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deposit.sourceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(DateFormatter.relative(deposit.date),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '+${PesoFormatter.format(deposit.amount)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.success),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(60, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('✓ OK',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _sourceEmoji(String source) {
    switch (source) {
      case 'allowance': return '💵';
      case 'baon': return '🍱';
      case 'gift': return '🎁';
      default: return '💰';
    }
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String sublabel;
  const _SectionHeader(
      {required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(sublabel,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Parent Goal Tile ──────────────────────────────────────────────────────────

class _ParentGoalTile extends StatelessWidget {
  final GoalModel goal;
  const _ParentGoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text(goal.emoji ?? '🎯',
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent,
                    minHeight: 5,
                    backgroundColor: AppColors.blueSurface,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.philippineBlue),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${PesoFormatter.format(goal.currentAmount)} / ${PesoFormatter.format(goal.targetAmount)}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.philippineBlue),
          ),
        ],
      ),
    );
  }
}

// ── Activity Tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final DepositModel deposit;
  const _ActivityTile({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blueSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_sourceEmoji(deposit.source),
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deposit.sourceLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(DateFormatter.relative(deposit.date),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${PesoFormatter.format(deposit.amount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.success)),
              Text(
                deposit.isApprovedByParent ? '✅ Approved' : '⏳ Pending',
                style: TextStyle(
                    fontSize: 10,
                    color: deposit.isApprovedByParent
                        ? AppColors.success
                        : AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sourceEmoji(String source) {
    switch (source) {
      case 'allowance': return '💵';
      case 'baon': return '🍱';
      case 'gift': return '🎁';
      default: return '💰';
    }
  }
}

// ── Empty Section ─────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

// ── Parent Bottom Nav ─────────────────────────────────────────────────────────

class _ParentBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        if (i == 1) context.push(AppRoutes.profile);
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
