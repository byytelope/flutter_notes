import "package:flutter/material.dart";

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          expandedHeight: 150.0,
          flexibleSpace: FlexibleSpaceBar(title: Text("Gallery")),
        ),
        const SliverToBoxAdapter(child: Center(child: Text("Gallery Screen"))),
      ],
    );
  }
}
