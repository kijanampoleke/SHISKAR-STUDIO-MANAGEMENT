import 'dart:convert';

class TechLog {
  int? id;
  int? projectId;
  String title;
  String notes;
  String diagramPath; // optional file path for wiring diagram image
  DateTime createdAt;

  TechLog({
    this.id,
    this.projectId,
    required this.title,
    this.notes = '',
    this.diagramPath = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'notes': notes,
      'diagram_path': diagramPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TechLog.fromMap(Map<String, dynamic> m) => TechLog(
        id: m['id'] as int?,
        projectId: m['project_id'] as int?,
        title: m['title'],
        notes: m['notes'] ?? '',
        diagramPath: m['diagram_path'] ?? '',
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory TechLog.fromJson(String s) => TechLog.fromMap(json.decode(s));
}