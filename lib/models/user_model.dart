// lib/models/user_model.dart
// Sync-ready: matches agreed JSON contract with Jhed's backend
// Fields map directly to Spring Boot entity

import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id; // UUID generated locally, replaced by backend ID on sync

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String role; // 'student' | 'parent'

  @HiveField(4)
  String? school;

  @HiveField(5)
  int? gradeLevel;

  @HiveField(6)
  String? linkedChildId; // Parent links to child via this

  @HiveField(7)
  String? linkedParentId; // Child's parent reference

  @HiveField(8)
  String? profilePhotoPath;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  bool isSynced; // Set to false until backend confirms

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.school,
    this.gradeLevel,
    this.linkedChildId,
    this.linkedParentId,
    this.profilePhotoPath,
    required this.createdAt,
    this.isSynced = false,
  });

  // JSON serialization — matches Jhed's API contract
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'school': school,
        'gradeLevel': gradeLevel,
        'linkedChildId': linkedChildId,
        'linkedParentId': linkedParentId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'],
        school: json['school'],
        gradeLevel: json['gradeLevel'],
        linkedChildId: json['linkedChildId'],
        linkedParentId: json['linkedParentId'],
        createdAt: DateTime.parse(json['createdAt']),
        isSynced: true,
      );

  bool get isStudent => role == 'student';
  bool get isParent => role == 'parent';
}
