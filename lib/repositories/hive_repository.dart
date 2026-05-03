// lib/repositories/hive_repository.dart
// Offline-first implementation using Hive local database
// When Jhed's backend is ready: create ApiRepository that extends IponRepository
// and swap the provider in main.dart — NO UI changes needed

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/deposit_model.dart';
import '../models/badge_model.dart';
import 'ipon_repository.dart';

const _uuid = Uuid();

class HiveRepository implements IponRepository {
  static const _userBox = 'users';
  static const _goalBox = 'goals';
  static const _depositBox = 'deposits';
  static const _badgeBox = 'badges';

  // ─── Auth ───────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    final box = Hive.box<UserModel>(_userBox);
    return box.get('currentUser');
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_userBox);
    await box.put('currentUser', user);
    await box.put(user.id, user);
  }

  @override
  Future<void> clearUser() async {
    final box = Hive.box<UserModel>(_userBox);
    await box.delete('currentUser');
  }

  // ─── Goals ──────────────────────────────────────────────

  @override
  Future<List<GoalModel>> getGoals(String userId) async {
    final box = Hive.box<GoalModel>(_goalBox);
    return box.values.where((g) => g.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<GoalModel?> getGoal(String goalId) async {
    final box = Hive.box<GoalModel>(_goalBox);
    return box.get(goalId);
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    final box = Hive.box<GoalModel>(_goalBox);
    await box.put(goal.id, goal);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final box = Hive.box<GoalModel>(_goalBox);
    await box.delete(goalId);
  }

  @override
  Future<void> updateGoalAmount(String goalId, double newAmount) async {
    final box = Hive.box<GoalModel>(_goalBox);
    final goal = box.get(goalId);
    if (goal != null) {
      goal.currentAmount = newAmount;
      goal.isSynced = false;
      if (newAmount >= goal.targetAmount) {
        goal.status = 'completed';
      }
      await goal.save();
    }
  }

  // ─── Deposits ───────────────────────────────────────────

  @override
  Future<List<DepositModel>> getDeposits(String userId) async {
    final box = Hive.box<DepositModel>(_depositBox);
    return box.values.where((d) => d.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<DepositModel>> getDepositsForGoal(String goalId) async {
    final box = Hive.box<DepositModel>(_depositBox);
    return box.values.where((d) => d.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> saveDeposit(DepositModel deposit) async {
    final box = Hive.box<DepositModel>(_depositBox);
    await box.put(deposit.id, deposit);

    // Update goal balance if this deposit is linked to a goal
    if (deposit.goalId != null) {
      final goalDeposits = await getDepositsForGoal(deposit.goalId!);
      final total = goalDeposits.fold<double>(0.0, (sum, d) => sum + d.amount);
      await updateGoalAmount(deposit.goalId!, total);
    }
  }

  @override
  Future<void> deleteDeposit(String depositId) async {
    final box = Hive.box<DepositModel>(_depositBox);
    final deposit = box.get(depositId);
    await box.delete(depositId);

    // Recalculate goal balance
    if (deposit?.goalId != null) {
      final goalDeposits = await getDepositsForGoal(deposit!.goalId!);
      final total = goalDeposits.fold<double>(0.0, (sum, d) => sum + d.amount);
      await updateGoalAmount(deposit.goalId!, total);
    }
  }

  // ─── Badges ─────────────────────────────────────────────

  @override
  Future<List<BadgeModel>> getEarnedBadges(String userId) async {
    final box = Hive.box<BadgeModel>(_badgeBox);
    final key = 'badges_$userId';
    final stored = box.get(key);
    // Returns all badge definitions with earned status applied
    final earnedIds = stored?.id.split(',') ?? [];
    return BadgeDefinitions.all.map((b) {
      b.isEarned = earnedIds.contains(b.id);
      return b;
    }).toList();
  }

  @override
  Future<void> awardBadge(String userId, String badgeId) async {
    final box = Hive.box<BadgeModel>(_badgeBox);
    final key = 'badges_$userId';
    final stored = box.get(key);
    final earned = stored?.id.split(',').toSet() ?? {};
    earned.add(badgeId);
    final badge = BadgeDefinitions.all.firstWhere((b) => b.id == badgeId);
    badge.isEarned = true;
    badge.earnedAt = DateTime.now();
    badge.id = earned.join(','); // Reuse id field to store CSV of earned IDs
    await box.put(key, badge);
  }

  // ─── Stats ──────────────────────────────────────────────

  @override
  Future<double> getTotalBalance(String userId) async {
    final deposits = await getDeposits(userId);
    return deposits.fold<double>(0.0, (sum, d) => sum + d.amount);
  }

  @override
  Future<int> getCurrentStreak(String userId) async {
    final deposits = await getDeposits(userId);
    if (deposits.isEmpty) return 0;

    final depositDays = deposits
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime check = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final day in depositDays) {
      if (day == check || day == check.subtract(const Duration(days: 1))) {
        streak++;
        check = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Future<List<DepositModel>> getRecentDeposits(String userId,
      {int limit = 5}) async {
    final deposits = await getDeposits(userId);
    return deposits.take(limit).toList();
  }

  // ─── Hive Box Initialization ─────────────────────────────

  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(GoalModelAdapter());
    Hive.registerAdapter(DepositModelAdapter());
    Hive.registerAdapter(BadgeModelAdapter());
    await Hive.openBox<UserModel>(_userBox);
    await Hive.openBox<GoalModel>(_goalBox);
    await Hive.openBox<DepositModel>(_depositBox);
    await Hive.openBox<BadgeModel>(_badgeBox);
  }
}
