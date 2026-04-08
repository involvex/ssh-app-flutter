import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/theme_picker.dart';
import '../widgets/shortcut_editor.dart';
import '../widgets/keyboard_shortcut_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // prefer_const_literals_to_create_immutables fix
              SizedBox(height: 16),
              ThemePicker(),
              Divider(height: 32),
              Text('Keyboard Shortcuts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  leading: Icon(Icons.keyboard),
                  title: Text('Configure Shortcuts'),
                  subtitle: Text('Customize keyboard shortcuts'), // prefer_const_constructors fixes
                  childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Collapsed summary uses the first terminal row (row 1)
                    KeyboardShortcutBar(showRow: 1, forceShowOnMobile: true), // shows first terminal row (Tab, arrows, Home/End)
                    SizedBox(height: 8),
                    // Expanded editor embedded inline
                    ShortcutEditor(),
                  ],
                ),
              ),
              Divider(height: 32),
              Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('SSH App'),
                      subtitle: Text('Version 1.0.0'),
                    ),
                    ListTile(
                      leading: Icon(Icons.code),
                      title: Text('Built with Flutter'),
                      subtitle: Text('Dartssh2, xterm, Provider'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}