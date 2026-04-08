import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../widgets/theme_picker.dart';
import '../widgets/shortcut_editor.dart';
import '../widgets/keyboard_shortcut_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await BackupService.export();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isImporting = true);
    try {
      final message = await BackupService.import();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // Reload settings provider so theme/shortcuts update immediately
        await Provider.of<SettingsProvider>(context, listen: false).loadSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

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
              const Card(
                child: ExpansionTile(
                  leading: Icon(Icons.keyboard),
                  title: Text('Configure Shortcuts'),
                  subtitle: Text('Customize keyboard shortcuts'),
                  childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    KeyboardShortcutBar(showRow: 1, forceShowOnMobile: true),
                    SizedBox(height: 8),
                    ShortcutEditor(),
                  ],
                ),
              ),
              const Divider(height: 32),
              const Text('Backup & Restore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: const Text('Export Backup'),
                      subtitle: const Text('Save profiles, SSH keys, snippets & settings to a file'),
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _isExporting ? null : _handleExport,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Import Backup'),
                      subtitle: const Text('Restore from a previously exported backup file'),
                      trailing: _isImporting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _isImporting ? null : _handleImport,
                    ),
                  ],
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
