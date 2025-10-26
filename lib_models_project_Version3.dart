import 'dart:convert';

class Project {
  int? id;
  String uuid;
  String title;
  String type; // music, video, photo, tech
  String notes;
  String status;
  DateTime? deadline;
  DateTime updatedAt;
  Project({
    this.id,
    required this.uuid,
    required this.title,
    required this.type,
    this.notes = '',
    this.status = 'open',
    this.deadline,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'type': type,
      'notes': notes,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> m) {
    return Project(
      id: m['id'] as int?,
      uuid: m['uuid'] as String,
      title: m['title'] as String,
      type: m['type'] as String,
      notes: m['notes'] ?? '',
      status: m['status'] ?? 'open',
      deadline: m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
      updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Project.fromJson(String source) => Project.fromMap(json.decode(source));
}