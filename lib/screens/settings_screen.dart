import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:widget_training/screens/signin_screen.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode currentTheme = ThemeMode.system;
  bool showConfirmationDialogs = true;
  String defaultTaskFilter = "Today";
  String appVersion = "1.0.0";

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
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Theme"),
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("Light"),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (ThemeMode? value) {
                  setState(() {
                    currentTheme = ThemeMode.light;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark"),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (ThemeMode? value) {
                  setState(() {
                    currentTheme = ThemeMode.dark;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("System Default"),
                value: ThemeMode.system,
                groupValue: currentTheme,
                onChanged: (ThemeMode? value) {
                  setState(() {
                    currentTheme = ThemeMode.system;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                "Appearance",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_4_outlined),
              title: const Text("Theme"),
              subtitle: Text(
                currentTheme == ThemeMode.light
                    ? "Light"
                    : currentTheme == ThemeMode.dark
                    ? "Dark"
                    : "System Default",
              ),
              onTap: () => _showThemeDialog(),
            ),
            const Divider(),
            ListTile(
              title: Text(
                "Data Management",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: Icon(null),
              title: const Text("Clear All Tasks"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(null),
              title: const Text("Clear All Notes"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(null),
              title: const Text("Clear All Gallery Images"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(null),
              title: const Text("Clear All Application Data"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              title: Text(
                "Behavior",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              title: const Text("Confirm Deletions"),
              subtitle: const Text(
                "Show confirmation dialog before deleting items",
              ),
              value: showConfirmationDialogs,
              onChanged: (bool value) {},
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text("Default Task Filter"),
              subtitle: const Text("Today"),
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
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Licenses & Acknowledgments"),
              onTap: () {
                showLicensePage(context: context);
              },
            ),
            const Divider(),
            ListTile(
              title: Text(
                "Account",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                "Sign Out",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: _signOut,
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }
}
