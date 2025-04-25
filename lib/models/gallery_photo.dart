import "package:hive_ce_flutter/hive_flutter.dart";

class GalleryPhoto extends HiveObject {
  final String id;
  final String path;
  final DateTime createdAt;

  GalleryPhoto({required this.id, required this.path})
    : createdAt = DateTime.now();
}
