import "package:hive_ce_flutter/hive_flutter.dart";

class Note extends HiveObject {
  final String id;
  String text;
  final DateTime createdAt;

  Note({required this.id, required this.text}) : createdAt = DateTime.now();
}
