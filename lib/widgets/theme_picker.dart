import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_suggest),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                settings.setThemeMode(newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Accent Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _ColorOption(color: Colors.blue, current: settings.accentColor),
                _ColorOption(color: Colors.green, current: settings.accentColor),
                _ColorOption(color: Colors.purple, current: settings.accentColor),
                _ColorOption(color: Colors.orange, current: settings.accentColor),
                _ColorOption(color: Colors.red, current: settings.accentColor),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final Color current;

  const _ColorOption({required this.color, required this.current});

  @override
  Widget build(BuildContext context) {
    final isSelected = color.toARGB32() == current.toARGB32();
    return GestureDetector(
      onTap: () {
        context.read<SettingsProvider>().setAccentColor(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}