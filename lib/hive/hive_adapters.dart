import "package:hive_ce/hive.dart";

import "package:widget_training/models/note.dart";
import "package:widget_training/screens/gallery_screen.dart";
import "package:widget_training/screens/tasks_screen.dart";

part "hive_adapters.g.dart";

@GenerateAdapters([
  AdapterSpec<Task>(),
  AdapterSpec<Note>(),
  AdapterSpec<GalleryPhoto>(),
])
class HiveAdapters {}
