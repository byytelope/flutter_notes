import "package:hive_ce_flutter/hive_flutter.dart";

class Task extends HiveObject {
  final String id;
  final String text;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.text,
    this.dueDate,
    this.isCompleted = false,
  }) : createdAt = DateTime.now();
}
