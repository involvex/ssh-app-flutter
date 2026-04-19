import 'package:uuid/uuid.dart';

class Snippet {
  final String id;
  final String name;
  final String content;
  final String category;

  Snippet({
    required this.name,
    required this.content,
    String? id,
    this.category = 'General',
  }) : id = id ?? const Uuid().v4();

  Snippet copyWith({
    String? id,
    String? name,
    String? content,
    String? category,
  }) {
    return Snippet(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'content': content,
      'category': category,
    };
  }

  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'General',
    );
  }

  static List<Snippet> get defaults => [
        Snippet(name: 'List files', content: 'ls -la', category: 'File'),
        Snippet(name: 'Current directory', content: 'pwd', category: 'System'),
        Snippet(name: 'Disk usage', content: 'df -h', category: 'System'),
        Snippet(name: 'Memory usage', content: 'free -m', category: 'System'),
        Snippet(name: 'Process list', content: 'ps aux', category: 'System'),
        Snippet(
            name: 'Top processes', content: 'top -b -n 1', category: 'System'),
        Snippet(name: 'Network info', content: 'ip addr', category: 'Network'),
        Snippet(
            name: 'Ping', content: 'ping -c 4 8.8.8.8', category: 'Network'),
      ];
}
