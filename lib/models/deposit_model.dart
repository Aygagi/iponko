// lib/models/deposit_model.dart

import 'package:hive/hive.dart';

part 'deposit_model.g.dart';

@HiveType(typeId: 2)
class DepositModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String? goalId; // nullable — deposit can be unallocated

  @HiveField(3)
  double amount;

  @HiveField(4)
  String source; // 'allowance' | 'baon' | 'gift' | 'other'

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? note; // e.g., 'Baon ko ngayon'

  @HiveField(7)
  String? receiptPhotoPath; // Local file path

  @HiveField(8)
  bool isApprovedByParent;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  DateTime createdAt;

  DepositModel({
    required this.id,
    required this.userId,
    this.goalId,
    required this.amount,
    required this.source,
    required this.date,
    this.note,
    this.receiptPhotoPath,
    this.isApprovedByParent = false,
    this.isSynced = false,
    required this.createdAt,
  });

  // Display label for source
  String get sourceLabel {
    switch (source) {
      case 'allowance': return 'Allowance';
      case 'baon': return 'Baon';
      case 'gift': return 'Regalo / Gift';
      case 'other': return 'Iba pa';
      default: return source;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'goalId': goalId,
        'amount': amount,
        'source': source,
        'date': date.toIso8601String(),
        'note': note,
        'isApprovedByParent': isApprovedByParent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DepositModel.fromJson(Map<String, dynamic> json) => DepositModel(
        id: json['id'],
        userId: json['userId'],
        goalId: json['goalId'],
        amount: (json['amount'] as num).toDouble(),
        source: json['source'],
        date: DateTime.parse(json['date']),
        note: json['note'],
        isApprovedByParent: json['isApprovedByParent'] ?? false,
        isSynced: true,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
