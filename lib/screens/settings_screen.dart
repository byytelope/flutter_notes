import "package:flutter/material.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          expandedHeight: 150.0,
          flexibleSpace: FlexibleSpaceBar(title: Text("Settings")),
        ),
        const SliverToBoxAdapter(child: Center(child: Text("Settings Screen"))),
      ],
    );
  }
}
