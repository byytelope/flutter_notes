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
  State<GalleryScreen> createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final _box = Hive.box<GalleryPhoto>("gallery_photos");
  final _uuid = const Uuid();
  final Set<int> _selectedIndices = {};
  bool isSelectionMode = false;

  void addImage() async {
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
          isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
        isSelectionMode = true;
      }
    });
  }

  void _enableSelectionMode(int index) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        _selectedIndices.clear();
        _selectedIndices.add(index);
      });
    }
  }

  void _disableSelectionMode() {
    setState(() {
      isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void deleteSelectedImages() {
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
                isSelectionMode
                    ? "${_selectedIndices.length} selected"
                    : "Gallery",
              ),
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
              final images = box.values.toList();
              images.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (images.isEmpty) {
                return SliverToBoxAdapter(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Text(
                      "Press the button below to add an image.",
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
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
                        if (isSelectionMode) {
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
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.tertiaryContainer,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
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
