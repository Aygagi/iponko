// lib/models/goal_model.dart

import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 1)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name; // e.g., 'Bagong Sapatos', 'Tablet'

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  DateTime targetDate;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String status; // 'active' | 'completed' | 'archived'

  @HiveField(8)
  String? emoji; // Optional emoji for the goal card

  @HiveField(9)
  bool isSynced;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    this.status = 'active',
    this.emoji,
    this.isSynced = false,
  });

  // Progress percentage (0.0 to 1.0)
  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  // Remaining amount
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  // Days remaining
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  // Required daily savings to hit goal
  double get requiredDailySavings {
    if (daysRemaining <= 0) return remainingAmount;
    return remainingAmount / daysRemaining;
  }

  bool get isCompleted => status == 'completed' || currentAmount >= targetAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'emoji': emoji,
      };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        targetDate: DateTime.parse(json['targetDate']),
        createdAt: DateTime.parse(json['createdAt']),
        status: json['status'] ?? 'active',
        emoji: json['emoji'],
        isSynced: true,
      );
}
