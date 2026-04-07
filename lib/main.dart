import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ssh_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/snippet_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  MaterialColor _getMaterialColor(Color color) {
    if (color == Colors.blue) return Colors.blue;
    if (color == Colors.green) return Colors.green;
    if (color == Colors.purple) return Colors.purple;
    if (color == Colors.orange) return Colors.orange;
    if (color == Colors.red) return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SSHProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (context) => SnippetProvider()..loadSnippets()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final materialColor = _getMaterialColor(settings.accentColor);
          return MaterialApp(
            title: 'SSH App',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              primarySwatch: materialColor,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: materialColor,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: materialColor,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1A1A2E),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF16213E),
                elevation: 0,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}