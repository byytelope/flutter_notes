import "package:flutter/material.dart";

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<String> _notes = [];
  final TextEditingController _textController = TextEditingController();

  Future<String?> _showNoteDialog({String? initialText}) async {
    _textController.text = initialText ?? "";
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(initialText == null ? "Add Note" : "Edit Note"),
          content: TextField(
            controller: _textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter your note here"),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
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
    final String? newNote = await _showNoteDialog();
    if (newNote != null && newNote.isNotEmpty) {
      setState(() {
        _notes.add(newNote);
      });
    }
  }

  void _editNote(int index) async {
    final String? updatedNote = await _showNoteDialog(
      initialText: _notes[index],
    );
    if (updatedNote != null && updatedNote.isNotEmpty) {
      setState(() {
        _notes[index] = updatedNote;
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
          if (_notes.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text("No notes yet!"),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ListTile(
                  title: Text(_notes[index]),
                  onTap: () => _editNote(index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _notes.removeAt(index);
                      });
                    },
                  ),
                );
              }, childCount: _notes.length),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: "Add Note",
        child: const Icon(Icons.edit),
      ),
    );
  }
}
