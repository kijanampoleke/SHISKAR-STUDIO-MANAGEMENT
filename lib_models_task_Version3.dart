import 'dart:convert';

class TaskItem {
  int? id;
  int projectId;
  String title;
  String description;
  int priority; // 0 low, 1 medium, 2 high
  bool done;
  double progress; // 0.0 - 1.0
  DateTime updatedAt;

  TaskItem({
    this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.priority = 1,
    this.done = false,
    this.progress = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'priority': priority,
      'done': done ? 1 : 0,
      'progress': progress,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> m) {
    return TaskItem(
      id: m['id'] as int?,
      projectId: m['project_id'] ?? -1,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      priority: m['priority'] ?? 1,
      done: (m['done'] ?? 0) == 1,
      progress: (m['progress'] ?? 0.0) is int ? (m['progress'] as int).toDouble() : (m['progress'] ?? 0.0),
      updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory TaskItem.fromJson(String src) => TaskItem.fromMap(json.decode(src));
}