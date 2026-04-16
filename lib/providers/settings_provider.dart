import 'package:flutter/material.dart';
import '../models/keyboard_shortcut.dart';
import '../services/config_service.dart';

enum AppTheme { system, light, dark, hacker }

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  AppTheme _appTheme = AppTheme.dark;
  Color _accentColor = Colors.blue;
  List<KeyboardShortcut> _shortcuts = [];
  bool _isLoaded = false;
  double _terminalFontSize = 12.0;

  ThemeMode get themeMode => _themeMode;
  AppTheme get appTheme => _appTheme;
  Color get accentColor => _accentColor;
  List<KeyboardShortcut> get shortcuts => _shortcuts;
  bool get isLoaded => _isLoaded;
  double get terminalFontSize => _terminalFontSize;

  List<KeyboardShortcut> getShortcutsByRow(int row) {
    return _shortcuts.where((s) => s.row == row).toList();
  }

  int get maxRow => _shortcuts.isEmpty
      ? 0
      : _shortcuts.map((s) => s.row).reduce((a, b) => a > b ? a : b);

  Future<void> loadSettings() async {
    final settings = await ConfigService.getSettings();

    final themeStr = settings['appTheme'] as String? ?? 'dark';
    _appTheme = AppTheme.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => AppTheme.dark,
    );

    _themeMode = switch (_appTheme) {
      AppTheme.light => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
      AppTheme.system => ThemeMode.system,
      AppTheme.hacker => ThemeMode.dark,
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
      _shortcuts = shortcutsData
          .map((e) =>
              KeyboardShortcut.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      _shortcuts = KeyboardShortcut.defaults;
    }

    final fontSizeVal = settings['terminalFontSize'];
    if (fontSizeVal != null) {
      _terminalFontSize = (fontSizeVal as num).toDouble();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setTerminalFontSize(double size) async {
    _terminalFontSize = size;
    await _saveSetting('terminalFontSize', size);
    notifyListeners();
  }

  Future<void> setAppTheme(AppTheme theme) async {
    _appTheme = theme;
    _themeMode = switch (theme) {
      AppTheme.light => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
      AppTheme.system => ThemeMode.system,
      AppTheme.hacker => ThemeMode.dark,
    };
    await _saveSetting('appTheme', theme.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _appTheme = switch (mode) {
      ThemeMode.light => AppTheme.light,
      ThemeMode.dark => AppTheme.dark,
      ThemeMode.system => AppTheme.system,
    };
    await _saveSetting('appTheme', _appTheme.name);
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
