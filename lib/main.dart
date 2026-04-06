import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ssh_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SSHProvider(),
      child: MaterialApp(
        title: 'Flutter SSH',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16213E),
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}