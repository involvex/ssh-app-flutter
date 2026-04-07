import 'package:flutter/material.dart';
import '../models/keyboard_shortcut.dart';
import '../services/config_service.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = Colors.blue;
  List<KeyboardShortcut> _shortcuts = [];
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  List<KeyboardShortcut> get shortcuts => _shortcuts;
  bool get isLoaded => _isLoaded;

  List<KeyboardShortcut> getShortcutsByRow(int row) {
    return _shortcuts.where((s) => s.row == row).toList();
  }

  int get maxRow => _shortcuts.isEmpty ? 0 : _shortcuts.map((s) => s.row).reduce((a, b) => a > b ? a : b);

  Future<void> loadSettings() async {
    final settings = await ConfigService.getSettings();
    
    final themeModeStr = settings['themeMode'] as String? ?? 'dark';
    _themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    final accentColorStr = settings['accentColor'] as String? ?? 'blue';
    _accentColor = switch (accentColorStr) {
      'green' => Colors.green,
      'purple' => Colors.purple,
      'orange' => Colors.orange,
      'red' => Colors.red,
      _ => Colors.blue,
    };

    final shortcutsData = settings['shortcuts'] as List<dynamic>?;
    if (shortcutsData != null && shortcutsData.isNotEmpty) {
      _shortcuts = shortcutsData.map((e) => KeyboardShortcut.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } else {
      _shortcuts = KeyboardShortcut.defaults;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _saveSetting('themeMode', modeStr);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final colorStr = switch (color) {
      final c when c == Colors.blue => 'blue',
      final c when c == Colors.green => 'green',
      final c when c == Colors.purple => 'purple',
      final c when c == Colors.orange => 'orange',
      final c when c == Colors.red => 'red',
      _ => 'blue',
    };
    await _saveSetting('accentColor', colorStr);
    notifyListeners();
  }

  Future<void> updateShortcuts(List<KeyboardShortcut> shortcuts) async {
    _shortcuts = shortcuts;
    await _saveSetting('shortcuts', shortcuts.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<void> resetShortcuts() async {
    _shortcuts = KeyboardShortcut.defaults;
    await _saveSetting('shortcuts', _shortcuts.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final settings = await ConfigService.getSettings();
    settings[key] = value;
    await ConfigService.saveSettings(settings);
  }
}