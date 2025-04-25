import "package:flutter/material.dart";
import "package:localstore/localstore.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Map<String, dynamic>> _notes = [];
  final TextEditingController _textController = TextEditingController();
  final _db = Localstore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final snapshot = await _db.collection("notes").get();
    if (snapshot != null) {
      final List<Map<String, dynamic>> loadedNotes = [];
      snapshot.forEach((key, value) {
        final id = key.split("/").last;
        loadedNotes.add({"id": id, "text": value["text"]});
      });
      setState(() {
        _notes.addAll(loadedNotes);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
          actions: <Widget>[
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
    if (newNoteText != null && newNoteText.isNotEmpty) {
      final id = _db.collection("notes").doc().id;
      final newNoteData = {"id": id, "text": newNoteText};
      await _db.collection("notes").doc(id).set({"text": newNoteText});

      setState(() {
        _notes.add(newNoteData);
      });
    }
  }

  void _editNote(int index) async {
    final note = _notes[index];
    final String? updatedNoteText = await _showNoteDialog(
      initialText: note["text"],
    );
    if (updatedNoteText != null && updatedNoteText.isNotEmpty) {
      final updatedNoteData = {"id": note["id"], "text": updatedNoteText};
      await _db.collection("notes").doc(note["id"]).set({
        "text": updatedNoteText,
      });

      setState(() {
        _notes[index] = updatedNoteData;
      });
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
            flexibleSpace: FlexibleSpaceBar(title: Text("Notes")),
          ),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_notes.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    "No notes yet.",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    elevation: 2.0,
                    child: InkWell(
                      onTap: () => _editNote(index),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note["text"],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20.0),
                                  tooltip: "Delete Note",
                                  onPressed: () async {
                                    final noteId = _notes[index]["id"];
                                    await _db
                                        .collection("notes")
                                        .doc(noteId)
                                        .delete();

                                    setState(() {
                                      _notes.removeAt(index);
                                    });
                                  },
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
