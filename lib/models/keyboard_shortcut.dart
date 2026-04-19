import 'package:uuid/uuid.dart';

enum ShortcutAction {
  newConnection,
  profiles,
  discovery,
  keys,
  tabChar,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  home,
  end,
  ctrlC,
  ctrlD,
  ctrlZ,
  ctrlL,
  ctrlA,
  ctrlP,
}

class KeyboardShortcut {
  final String id;
  final String label;
  final String description;
  final ShortcutAction action;
  final int? charCode;
  final int row;

  KeyboardShortcut({
    required this.label,
    required this.description,
    required this.action,
    String? id,
    this.charCode,
    this.row = 0,
  }) : id = id ?? const Uuid().v4();

  String get actionName {
    return switch (action) {
      ShortcutAction.newConnection => 'new_connection',
      ShortcutAction.profiles => 'profiles',
      ShortcutAction.discovery => 'discovery',
      ShortcutAction.keys => 'keys',
      ShortcutAction.tabChar => 'tab_char',
      ShortcutAction.arrowUp => 'arrow_up',
      ShortcutAction.arrowDown => 'arrow_down',
      ShortcutAction.arrowLeft => 'arrow_left',
      ShortcutAction.arrowRight => 'arrow_right',
      ShortcutAction.home => 'home',
      ShortcutAction.end => 'end',
      ShortcutAction.ctrlC => 'ctrl_c',
      ShortcutAction.ctrlD => 'ctrl_d',
      ShortcutAction.ctrlZ => 'ctrl_z',
      ShortcutAction.ctrlL => 'ctrl_l',
      ShortcutAction.ctrlA => 'ctrl_a',
      ShortcutAction.ctrlP => 'ctrl_p',
    };
  }

  KeyboardShortcut copyWith({
    String? id,
    String? label,
    String? description,
    ShortcutAction? action,
    int? charCode,
    int? row,
  }) {
    return KeyboardShortcut(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      action: action ?? this.action,
      charCode: charCode ?? this.charCode,
      row: row ?? this.row,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'description': description,
      'action': actionName,
      'charCode': charCode,
      'row': row,
    };
  }

  factory KeyboardShortcut.fromJson(Map<String, dynamic> json) {
    return KeyboardShortcut(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      action: _actionFromString(json['action'] as String),
      charCode: json['charCode'] as int?,
      row: json['row'] as int? ?? 0,
    );
  }

  static ShortcutAction _actionFromString(String action) {
    return switch (action) {
      'new_connection' => ShortcutAction.newConnection,
      'profiles' => ShortcutAction.profiles,
      'discovery' => ShortcutAction.discovery,
      'keys' => ShortcutAction.keys,
      'tab_char' => ShortcutAction.tabChar,
      'arrow_up' => ShortcutAction.arrowUp,
      'arrow_down' => ShortcutAction.arrowDown,
      'arrow_left' => ShortcutAction.arrowLeft,
      'arrow_right' => ShortcutAction.arrowRight,
      'home' => ShortcutAction.home,
      'end' => ShortcutAction.end,
      'ctrl_c' => ShortcutAction.ctrlC,
      'ctrl_d' => ShortcutAction.ctrlD,
      'ctrl_z' => ShortcutAction.ctrlZ,
      'ctrl_l' => ShortcutAction.ctrlL,
      'ctrl_a' => ShortcutAction.ctrlA,
      'ctrl_p' => ShortcutAction.ctrlP,
      _ => ShortcutAction.newConnection,
    };
  }

  static List<KeyboardShortcut> get defaults => [
        KeyboardShortcut(
            label: 'Ctrl+N',
            description: 'New Connection',
            action: ShortcutAction.newConnection,
            row: 0),
        KeyboardShortcut(
            label: 'Ctrl+P',
            description: 'Profiles',
            action: ShortcutAction.profiles,
            row: 0),
        KeyboardShortcut(
            label: 'Ctrl+D',
            description: 'Discovery',
            action: ShortcutAction.discovery,
            row: 0),
        KeyboardShortcut(
            label: 'Ctrl+K',
            description: 'Keys',
            action: ShortcutAction.keys,
            row: 0),
        KeyboardShortcut(
            label: 'Tab',
            description: 'Tab',
            action: ShortcutAction.tabChar,
            charCode: 9,
            row: 1),
        KeyboardShortcut(
            label: '←',
            description: 'Arrow Left',
            action: ShortcutAction.arrowLeft,
            row: 1),
        KeyboardShortcut(
            label: '→',
            description: 'Arrow Right',
            action: ShortcutAction.arrowRight,
            row: 1),
        KeyboardShortcut(
            label: '↑',
            description: 'Arrow Up',
            action: ShortcutAction.arrowUp,
            row: 1),
        KeyboardShortcut(
            label: '↓',
            description: 'Arrow Down',
            action: ShortcutAction.arrowDown,
            row: 1),
        KeyboardShortcut(
            label: 'Home',
            description: 'Home',
            action: ShortcutAction.home,
            row: 1),
        KeyboardShortcut(
            label: 'End',
            description: 'End',
            action: ShortcutAction.end,
            row: 1),
        KeyboardShortcut(
            label: 'Ctrl+C',
            description: 'Interrupt',
            action: ShortcutAction.ctrlC,
            charCode: 3,
            row: 2),
        KeyboardShortcut(
            label: 'Ctrl+D',
            description: 'EOF',
            action: ShortcutAction.ctrlD,
            charCode: 4,
            row: 2),
        KeyboardShortcut(
            label: 'Ctrl+Z',
            description: 'Suspend',
            action: ShortcutAction.ctrlZ,
            charCode: 26,
            row: 2),
        KeyboardShortcut(
            label: 'Ctrl+L',
            description: 'Clear',
            action: ShortcutAction.ctrlL,
            charCode: 12,
            row: 2),
      ];
}
