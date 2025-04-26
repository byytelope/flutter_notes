import "package:flutter/material.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:widget_training/main.dart";
import "package:widget_training/models/gallery_photo.dart";
import "package:widget_training/models/note.dart";
import "package:widget_training/models/task.dart";
import "package:widget_training/screens/signin_screen.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String appVersion = "1.0.0";
  final _tasksBox = Hive.box<Task>("tasks");
  final _notesBox = Hive.box<Note>("notes");
  final _galleryBox = Hive.box<GalleryPhoto>("gallery_photos");
  final _prefsBox = Hive.box("user_preferences");
  final _themeKey = "theme_mode";
  final _confirmDeletionsKey = "confirm_deletions";
  final _defaultTaskFilterKey = "default_task_filter";

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign Out Failed: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: $e")),
        );
      }
    }
  }

  Future<void> _showThemeDialog() async {
    final currentTheme =
        _prefsBox.get(_themeKey, defaultValue: ThemeMode.system.index) as int;
    ThemeMode selectedTheme = ThemeMode.values[currentTheme];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Theme"),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 24,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text("Light"),
                    value: ThemeMode.light,
                    groupValue: selectedTheme,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        setDialogState(() => selectedTheme = value);
                        _prefsBox.put(_themeKey, value.index);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("Dark"),
                    value: ThemeMode.dark,
                    groupValue: selectedTheme,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        setDialogState(() => selectedTheme = value);
                        _prefsBox.put(_themeKey, value.index);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("System Default"),
                    value: ThemeMode.system,
                    groupValue: selectedTheme,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        setDialogState(() => selectedTheme = value);
                        _prefsBox.put(_themeKey, value.index);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTaskFilterDialog() async {
    final currentFilter =
        _prefsBox.get(
              _defaultTaskFilterKey,
              defaultValue: TaskFilter.today.index,
            )
            as int;
    TaskFilter selectedFilter = TaskFilter.values[currentFilter];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Default Task Filter"),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 24,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    TaskFilter.values.map((filter) {
                      return RadioListTile<TaskFilter>(
                        title: Text(filter.name.capitalize()),
                        value: filter,
                        groupValue: selectedFilter,
                        onChanged: (TaskFilter? value) {
                          if (value != null) {
                            setDialogState(() => selectedFilter = value);
                            _prefsBox.put(_defaultTaskFilterKey, value.index);
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showClearConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: [Text(content)]),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Confirm",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("$title successful")));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _prefsBox.listenable(
        keys: [_themeKey, _confirmDeletionsKey, _defaultTaskFilterKey],
      ),
      builder: (context, box, _) {
        final themeMode =
            box.get(_themeKey, defaultValue: ThemeMode.system.index) as int;
        final confirmDeletions =
            box.get(_confirmDeletionsKey, defaultValue: true) as bool;
        final defaultTaskFilter =
            box.get(_defaultTaskFilterKey, defaultValue: TaskFilter.today.index)
                as int;

        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              expandedHeight: 150.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Settings"),
                centerTitle: true,
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  title: Text(
                    "App Settings",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: const Icon(Icons.brightness_4_outlined),
                    title: const Text("Theme"),
                    subtitle: Text(
                      themeMode == ThemeMode.light.index
                          ? "Light"
                          : themeMode == ThemeMode.dark.index
                          ? "Dark"
                          : "System Default",
                    ),
                    onTap: () => _showThemeDialog(),
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: const Icon(Icons.filter_list),
                    title: const Text("Default Task Filter"),
                    subtitle: Text(
                      TaskFilter.values[defaultTaskFilter].name.capitalize(),
                    ),
                    onTap: () => _showTaskFilterDialog(),
                  ),
                ),
                Material(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.shield_outlined),
                    title: const Text("Confirm Deletions"),
                    subtitle: const Text(
                      "Show confirmation dialog before deleting items",
                    ),
                    value: confirmDeletions,
                    onChanged: (bool value) {
                      _prefsBox.put(_confirmDeletionsKey, value);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    "Data Management",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: Icon(null),
                    title: const Text("Clear All Tasks"),
                    onTap: () async {
                      await _showClearConfirmationDialog(
                        title: "Clear All Tasks",
                        content:
                            "Are you sure you want to delete all tasks? This action cannot be undone.",
                        onConfirm: () async => await _tasksBox.clear(),
                      );
                    },
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: Icon(null),
                    title: const Text("Clear All Notes"),
                    onTap: () async {
                      await _showClearConfirmationDialog(
                        title: "Clear All Notes",
                        content:
                            "Are you sure you want to delete all notes? This action cannot be undone.",
                        onConfirm: () async => await _notesBox.clear(),
                      );
                    },
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: Icon(null),
                    title: const Text("Clear All Gallery Images"),
                    onTap: () async {
                      await _showClearConfirmationDialog(
                        title: "Clear All Gallery Images",
                        content:
                            "Are you sure you want to delete all gallery images? This action cannot be undone.",
                        onConfirm: () async => await _galleryBox.clear(),
                      );
                    },
                  ),
                ),
                Material(
                  child: ListTile(
                    leading: Icon(null),
                    title: const Text("Clear All Application Data"),
                    onTap: () async {
                      await _showClearConfirmationDialog(
                        title: "Clear All Application Data",
                        content:
                            "Are you sure you want to delete all application data (tasks, notes, images)? This action cannot be undone.",
                        onConfirm: () async {
                          await _tasksBox.clear();
                          await _notesBox.clear();
                          await _galleryBox.clear();
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    "About",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("App Version"),
                  subtitle: Text(appVersion),
                ),
                Material(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text("Licenses & Acknowledgments"),
                    onTap: () {
                      showLicensePage(context: context);
                    },
                  ),
                ),
                const Divider(),
                Material(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      "Sign Out",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: _signOut,
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ],
        );
      },
    );
  }
}
