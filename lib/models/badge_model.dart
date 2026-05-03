// lib/models/badge_model.dart

import 'package:hive/hive.dart';

part 'badge_model.g.dart';

@HiveType(typeId: 3)
class BadgeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String emoji;

  @HiveField(4)
  bool isEarned;

  @HiveField(5)
  DateTime? earnedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.isEarned = false,
    this.earnedAt,
  });
}

// All badge definitions — static, no backend needed
class BadgeDefinitions {
  static List<BadgeModel> get all => [
    BadgeModel(id: 'first_deposit', title: 'Unang Ipon!', description: 'Logged your first deposit', emoji: '🌱'),
    BadgeModel(id: 'streak_7', title: '7-Day Streak', description: 'Saved 7 days in a row', emoji: '🔥'),
    BadgeModel(id: 'streak_30', title: '30-Day Streak', description: 'Saved 30 days in a row', emoji: '💪'),
    BadgeModel(id: 'goal_complete', title: 'Goal Achieved!', description: 'Completed your first goal', emoji: '🎯'),
    BadgeModel(id: 'saved_500', title: '₱500 Saved!', description: 'Total savings reached ₱500', emoji: '💰'),
    BadgeModel(id: 'saved_1000', title: '₱1,000 Saved!', description: 'Total savings reached ₱1,000', emoji: '💎'),
    BadgeModel(id: 'saved_5000', title: '₱5,000 Saved!', description: 'Total savings reached ₱5,000', emoji: '👑'),
    BadgeModel(id: 'multi_goal', title: 'Maraming Pangarap', description: 'Created 3 goals at once', emoji: '⭐'),
  ];
}
