import "package:hive_ce/hive.dart";

import "package:widget_training/models/note.dart";
import "package:widget_training/models/gallery_photo.dart";
import "package:widget_training/models/task.dart";

part "hive_adapters.g.dart";

@GenerateAdapters([
  AdapterSpec<Task>(),
  AdapterSpec<Note>(),
  AdapterSpec<GalleryPhoto>(),
])
class HiveAdapters {}
