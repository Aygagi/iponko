// lib/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ipon_repository.dart';
import '../repositories/hive_repository.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/deposit_model.dart';

// ─── Repository Provider ────────────────────────────────────────────────────
// SWAP THIS when Jhed's backend is ready:
// Change HiveRepository() → ApiRepository()
// Nothing else in the app needs to change.

final repositoryProvider = Provider<IponRepository>((ref) {
  return HiveRepository();
});

// ─── Current User ───────────────────────────────────────────────────────────

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getCurrentUser();
});

// ─── Goals ──────────────────────────────────────────────────────────────────

final goalsProvider = FutureProvider.family<List<GoalModel>, String>(
  (ref, userId) async {
    final repo = ref.watch(repositoryProvider);
    return repo.getGoals(userId);
  },
);

// ─── Deposits ───────────────────────────────────────────────────────────────

final depositsProvider = FutureProvider.family<List<DepositModel>, String>(
  (ref, userId) async {
    final repo = ref.watch(repositoryProvider);
    return repo.getDeposits(userId);
  },
);

final recentDepositsProvider = FutureProvider.family<List<DepositModel>, String>(
  (ref, userId) async {
    final repo = ref.watch(repositoryProvider);
    return repo.getRecentDeposits(userId, limit: 5);
  },
);

// ─── Stats ───────────────────────────────────────────────────────────────────

final totalBalanceProvider = FutureProvider.family<double, String>(
  (ref, userId) async {
    final repo = ref.watch(repositoryProvider);
    return repo.getTotalBalance(userId);
  },
);

final streakProvider = FutureProvider.family<int, String>(
  (ref, userId) async {
    final repo = ref.watch(repositoryProvider);
    return repo.getCurrentStreak(userId);
  },
);

// ─── Notifiers (for mutations) ───────────────────────────────────────────────

class GoalNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  final IponRepository _repo;
  final String userId;

  GoalNotifier(this._repo, this.userId) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repo.getGoals(userId);
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    await _repo.saveGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(String goalId) async {
    await _repo.deleteGoal(goalId);
    await loadGoals();
  }
}

final goalNotifierProvider =
    StateNotifierProvider.family<GoalNotifier, AsyncValue<List<GoalModel>>, String>(
  (ref, userId) => GoalNotifier(ref.watch(repositoryProvider), userId),
);

class DepositNotifier extends StateNotifier<AsyncValue<List<DepositModel>>> {
  final IponRepository _repo;
  final String userId;

  DepositNotifier(this._repo, this.userId) : super(const AsyncValue.loading()) {
    loadDeposits();
  }

  Future<void> loadDeposits() async {
    state = const AsyncValue.loading();
    try {
      final deposits = await _repo.getDeposits(userId);
      state = AsyncValue.data(deposits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDeposit(DepositModel deposit) async {
    await _repo.saveDeposit(deposit);
    await loadDeposits();
  }
}

final depositNotifierProvider =
    StateNotifierProvider.family<DepositNotifier, AsyncValue<List<DepositModel>>, String>(
  (ref, userId) => DepositNotifier(ref.watch(repositoryProvider), userId),
);
