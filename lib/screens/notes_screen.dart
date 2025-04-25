import "package:flutter/material.dart";
import "package:uuid/uuid.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

import "package:widget_training/models/note.dart";

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _textController = TextEditingController();
  final _box = Hive.box<Note>("notes");
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
  }

  Future<String?> _showNoteDialog({String? initialText}) async {
    _textController.text = initialText ?? "";

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);
        final height = mediaQuery.size.height;
        final width = mediaQuery.size.width;

        return AlertDialog(
          icon: Icon(
            initialText == null
                ? Icons.note_add_outlined
                : Icons.edit_note_outlined,
          ),
          title: Text(initialText == null ? "Add Note" : "Edit Note"),
          content: SizedBox(
            height: height * 0.15,
            width: width * 0.8,
            child: Center(
              child: TextField(
                controller: _textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Note Text",
                  hintText: "Enter your note here",
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 0),
              child: const Text("Save"),
              onPressed: () {
                Navigator.of(context).pop(_textController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _addNote() async {
    final String? newNoteText = await _showNoteDialog();

    final String id = _uuid.v4();
    final newNote = Note(id: id, text: newNoteText ?? "");
    await _box.put(id, newNote);
  }

  void _editNote(Note note) async {
    final String? updatedNoteText = await _showNoteDialog(
      initialText: note.text,
    );
    if (updatedNoteText != null && updatedNoteText.isNotEmpty) {
      note.text = updatedNoteText;
      await note.save();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Notes"),
              centerTitle: true,
            ),
          ),

          ValueListenableBuilder(
            valueListenable: _box.listenable(),
            builder: (context, Box<Note> box, _) {
              if (!box.isOpen) {
                return SliverToBoxAdapter(
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final notes = box.values.toList();
              notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (notes.isEmpty) {
                return SliverToBoxAdapter(
                  child: const Center(child: Text("No notes yet!")),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      elevation: 2.0,
                      child: InkWell(
                        onTap: () => _editNote(note),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20.0),
                                    tooltip: "Delete Note",
                                    onPressed: () async {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: "Add Note",
        child: const Icon(Icons.note_add_outlined),
      ),
    );
  }
}
