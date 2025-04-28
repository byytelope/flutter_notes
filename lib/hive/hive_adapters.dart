import "package:hive_ce/hive.dart";

import "package:flutter_notes/models/note.dart";
import "package:flutter_notes/models/gallery_photo.dart";
import "package:flutter_notes/models/task.dart";

part "hive_adapters.g.dart";

@GenerateAdapters([
  AdapterSpec<Task>(),
  AdapterSpec<Note>(),
  AdapterSpec<GalleryPhoto>(),
])
class HiveAdapters {}
