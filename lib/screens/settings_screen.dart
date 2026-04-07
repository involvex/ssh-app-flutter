import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/theme_picker.dart';
import '../widgets/shortcut_editor.dart';

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
            children: [
              const Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const ThemePicker(),
              const Divider(height: 32),
              const Text('Keyboard Shortcuts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.keyboard),
                  title: const Text('Configure Shortcuts'),
                  subtitle: const Text('Customize keyboard shortcuts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const ShortcutEditor(),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Card(
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