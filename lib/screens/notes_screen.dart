import "package:flutter/material.dart";
import "package:uuid/uuid.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

import "package:flutter_notes/models/note.dart";

class NotesScreen extends StatefulWidget {
  final ValueChanged<bool>? onSelectionModeChanged;

  const NotesScreen({super.key, this.onSelectionModeChanged});

  @override
  State<NotesScreen> createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  final TextEditingController _textController = TextEditingController();
  final _box = Hive.box<Note>("notes");
  final _uuid = const Uuid();
  final Set<String> _selectedIds = {};
  bool isSelectionMode = false;

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
          content: Container(
            constraints: BoxConstraints(
              maxHeight: height * 0.5,
              minHeight: height * 0.1,
            ),
            width: width * 0.8,
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

  void addNote() async {
    final String? newNoteText = await _showNoteDialog();

    if (newNoteText == null || newNoteText.isEmpty) {
      return;
    }

    final String id = _uuid.v4();
    final newNote = Note(id: id, text: newNoteText);
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

  Future<void> _deleteNotes() async {
    if (_selectedIds.isEmpty) return;

    await _box.deleteAll(_selectedIds);

    setState(() {
      _disableSelectionMode();
    });
  }

  void _toggleSelection(Note note) {
    setState(() {
      if (_selectedIds.contains(note.id)) {
        _selectedIds.remove(note.id);
        if (_selectedIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        _selectedIds.add(note.id);
        isSelectionMode = true;
      }
      widget.onSelectionModeChanged?.call(isSelectionMode);
    });
  }

  void _enableSelectionMode(String id) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        _selectedIds.clear();
        _selectedIds.add(id);
        widget.onSelectionModeChanged?.call(isSelectionMode);
      });
    }
  }

  void _disableSelectionMode() {
    setState(() {
      isSelectionMode = false;
      _selectedIds.clear();
      widget.onSelectionModeChanged?.call(isSelectionMode);
    });
  }

  void deleteSelectedNotes() {
    _deleteNotes();
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
          SliverAppBar(
            pinned: true,
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isSelectionMode ? "${_selectedIds.length} selected" : "Notes",
              ),
              centerTitle: true,
            ),
            leading:
                isSelectionMode
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _disableSelectionMode,
                      tooltip: "Cancel Selection",
                    )
                    : null,
            actions: isSelectionMode ? [] : null,
          ),
          ValueListenableBuilder(
            valueListenable: _box.listenable(),
            builder: (context, box, _) {
              if (!box.isOpen) {
                return SliverToBoxAdapter(
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final notes = box.values.toList();
              notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (notes.isEmpty) {
                return SliverToBoxAdapter(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Text(
                      "Tap the button below to add a note.",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                    final isSelected = _selectedIds.contains(note.id);

                    return Card.filled(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.0),

                        onTap: () {
                          if (isSelectionMode) {
                            _toggleSelection(note);
                          } else {
                            _editNote(note);
                          }
                        },
                        onLongPress: () => _enableSelectionMode(note.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            spacing: 8.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_outline,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                  size: 20,
                                ),
                              Text(
                                note.text,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                ),
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
    );
  }
}
