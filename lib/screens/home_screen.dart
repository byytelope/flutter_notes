import "package:animations/animations.dart";
import "package:flutter/material.dart";

import "./tasks_screen.dart";
import "./notes_screen.dart";
import "./gallery_screen.dart";
import "./settings_screen.dart";

class _MyFloatingActionButtonAnimator extends FloatingActionButtonAnimator {
  const _MyFloatingActionButtonAnimator();

  @override
  Offset getOffset({
    required Offset begin,
    required Offset end,
    required double progress,
  }) {
    if (progress < 0.5) {
      return begin;
    } else {
      return end;
    }
  }

  @override
  Animation<double> getScaleAnimation({required Animation<double> parent}) {
    return Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: parent, curve: Curves.easeOut));
  }

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) {
    return const AlwaysStoppedAnimation<double>(1.0);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  final GlobalKey<TasksScreenState> _tasksScreenKey =
      GlobalKey<TasksScreenState>();
  final GlobalKey<NotesScreenState> _notesScreenKey =
      GlobalKey<NotesScreenState>();
  final GlobalKey<GalleryScreenState> _galleryScreenKey =
      GlobalKey<GalleryScreenState>();

  late final List<Widget> _tabItems;

  @override
  void initState() {
    super.initState();
    _tabItems = [
      TasksScreen(key: _tasksScreenKey),
      NotesScreen(
        key: _notesScreenKey,
        onSelectionModeChanged: (_) {
          if (_selectedIndex == 1) {
            setState(() {});
          }
        },
      ),
      GalleryScreen(
        key: _galleryScreenKey,
        onSelectionModeChanged: (_) {
          if (_selectedIndex == 2) {
            setState(() {});
          }
        },
      ),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  Widget? _buildFab() {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
          key: const ValueKey("fab_tasks"),
          onPressed: () => _tasksScreenKey.currentState?.showAddTaskDialog(),
          tooltip: "Add Task",
          child: const Icon(Icons.add),
        );
      case 1:
        final isNotesSelectionMode =
            _notesScreenKey.currentState?.isSelectionMode ??
            false; 
        return FloatingActionButton(
          key: const ValueKey("fab_notes"),
          onPressed:
              isNotesSelectionMode
                  ? () =>
                      _notesScreenKey.currentState
                          ?.deleteSelectedNotes() 
                  : () => _notesScreenKey.currentState?.addNote(), 
          tooltip: isNotesSelectionMode ? "Delete Selected" : "Add Note",
          backgroundColor:
              isNotesSelectionMode ? Colors.red : null, 
          child: Icon(
            isNotesSelectionMode
                ? Icons
                    .delete_outline 
                : Icons.note_add_outlined, 
          ),
        );
      case 2:
        final isGallerySelectionMode =
            _galleryScreenKey.currentState?.isSelectionMode ?? false;
        return FloatingActionButton(
          key: const ValueKey("fab_gallery"),
          onPressed:
              isGallerySelectionMode
                  ? () => _galleryScreenKey.currentState?.deleteSelectedImages()
                  : () => _galleryScreenKey.currentState?.addImage(),
          tooltip: isGallerySelectionMode ? "Delete Selected" : "Add Image",
          backgroundColor: isGallerySelectionMode ? Colors.red : null,
          child: Icon(
            isGallerySelectionMode
                ? Icons.delete_outline
                : Icons.add_photo_alternate_outlined,
          ),
        );
      case 3:
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReverse = _selectedIndex < _previousIndex;

    return Scaffold(
      body: PageTransitionSwitcher(
        reverse: isReverse,
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _tabItems[_selectedIndex],
        ),
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
      floatingActionButtonAnimator: const _MyFloatingActionButtonAnimator(),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: "Tasks",
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: "Notes",
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: "Gallery",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
