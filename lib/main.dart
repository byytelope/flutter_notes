import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:widget_training/hive/hive_registrar.g.dart";
import "package:widget_training/screens/signin_screen.dart";
import "package:widget_training/screens/home_screen.dart";
import "package:widget_training/models/note.dart";
import "package:widget_training/models/gallery_photo.dart";
import "package:widget_training/models/task.dart";

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Hive.initFlutter();
  Hive.registerAdapters();

  await Hive.openBox<Task>("tasks");
  await Hive.openBox<Note>("notes");
  await Hive.openBox<GalleryPhoto>("gallery_photos");
  await Hive.openBox("user_preferences");

  await Supabase.initialize(
    url: dotenv.env["SUPABASE_URL"] ?? "",
    anonKey: dotenv.env["SUPABASE_ANON_KEY"] ?? "",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final seedColor = Colors.deepPurple;
    final prefsBox = Hive.box("user_preferences");
    final pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      },
    );

    return ValueListenableBuilder(
      valueListenable: prefsBox.listenable(keys: ["theme_mode"]),
      builder: (context, box, _) {
        return MaterialApp(
          title: "Widget Training",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
            pageTransitionsTheme: pageTransitionsTheme,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            pageTransitionsTheme: pageTransitionsTheme,
          ),
          themeMode:
              ThemeMode.values[Hive.box(
                "user_preferences",
              ).get("theme_mode", defaultValue: ThemeMode.system.index)],
          home: user == null ? const SignInScreen() : const HomeScreen(),
        );
      },
    );
  }
}
