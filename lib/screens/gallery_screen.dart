import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:image_picker/image_picker.dart";
import "package:uuid/uuid.dart";

import "package:widget_training/models/gallery_photo.dart";

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final Set<int> _selectedIndices = {};
  final ImagePicker _picker = ImagePicker();
  final _box = Hive.box<GalleryPhoto>("gallery_photos");
  final _uuid = const Uuid();
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
  }

  void _addImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final id = _uuid.v4();
      final newImage = GalleryPhoto(id: id, path: image.path);

      await _box.put(id, newImage);
    }
  }

  Future<void> _deleteImages(List<int> indices) async {
    if (indices.isEmpty) return;

    await _box.deleteAll(
      indices.map((index) {
        final image = _box.getAt(index);
        return image?.id;
      }).toList(),
    );

    setState(() {
      _disableSelectionMode();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
        _isSelectionMode = true;
      }
    });
  }

  void _enableSelectionMode(int index) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIndices.clear();
        _selectedIndices.add(index);
      });
    }
  }

  void _disableSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _deleteSelectedImages() {
    _deleteImages(_selectedIndices.toList());
  }

  Route _createPreviewRoute(GalleryPhoto image) {
    return PageRouteBuilder(
      pageBuilder:
          (context, animation, secondaryAnimation) =>
              _ImagePreviewScreen(image: image),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
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
              centerTitle: true,
              title: Text(
                _isSelectionMode
                    ? "${_selectedIndices.length} selected"
                    : "Gallery",
              ),
            ),
            leading:
                _isSelectionMode
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _disableSelectionMode,
                      tooltip: "Cancel Selection",
                    )
                    : null,
            actions: _isSelectionMode ? [] : null,
          ),
          ValueListenableBuilder(
            valueListenable: _box.listenable(),
            builder: (context, Box<GalleryPhoto> box, _) {
              if (!box.isOpen) {
                return SliverToBoxAdapter(
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final images = box.values.toList();
              images.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (images.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "No images added.",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150.0,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final image = images[index];
                    final imagePath = image.path;
                    final isSelected = _selectedIndices.contains(index);

                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(index);
                        } else {
                          Navigator.of(
                            context,
                          ).push(_createPreviewRoute(image));
                        }
                      },
                      onLongPress: () => _enableSelectionMode(index),
                      child: Hero(
                        tag: image.id,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                frameBuilder: (
                                  context,
                                  child,
                                  frame,
                                  wasSynchronouslyLoaded,
                                ) {
                                  if (wasSynchronouslyLoaded) {
                                    return child;
                                  }
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  if (kDebugMode) {
                                    print("Error loading image: $error");
                                  }
                                  return Container(
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                              if (isSelected)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: images.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSelectionMode ? _deleteSelectedImages : _addImage,
        tooltip: _isSelectionMode ? "Delete Selected" : "Add Image",
        backgroundColor: _isSelectionMode ? Colors.red : null,
        child: Icon(
          _isSelectionMode
              ? Icons.delete_outline
              : Icons.add_photo_alternate_outlined,
        ),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final GalleryPhoto image;

  const _ImagePreviewScreen({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                scaleEnabled: true,
                trackpadScrollCausesScale: true,
                constrained: true,
                panEnabled: false,
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(20),
                child: Center(
                  child: Hero(
                    tag: image.id,
                    child: Image.file(File(image.path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton.filledTonal(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
