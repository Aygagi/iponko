// lib/repositories/ipon_repository.dart
// Abstract interface — Jhed swaps the implementation to ApiRepository later
// Your UI and providers NEVER import HiveRepository directly

import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/deposit_model.dart';
import '../models/badge_model.dart';

abstract class IponRepository {
  // Auth
  Future<UserModel?> getCurrentUser();
  Future<void> saveUser(UserModel user);
  Future<void> clearUser();

  // Goals
  Future<List<GoalModel>> getGoals(String userId);
  Future<GoalModel?> getGoal(String goalId);
  Future<void> saveGoal(GoalModel goal);
  Future<void> deleteGoal(String goalId);
  Future<void> updateGoalAmount(String goalId, double newAmount);

  // Deposits
  Future<List<DepositModel>> getDeposits(String userId);
  Future<List<DepositModel>> getDepositsForGoal(String goalId);
  Future<void> saveDeposit(DepositModel deposit);
  Future<void> deleteDeposit(String depositId);

  // Badges
  Future<List<BadgeModel>> getEarnedBadges(String userId);
  Future<void> awardBadge(String userId, String badgeId);

  // Stats
  Future<double> getTotalBalance(String userId);
  Future<int> getCurrentStreak(String userId);
  Future<List<DepositModel>> getRecentDeposits(String userId, {int limit = 5});
}
