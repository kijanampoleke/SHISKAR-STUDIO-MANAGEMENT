import 'dart:convert';

class MediaItem {
  int? id;
  int? projectId;
  String path; // local file path
  String type; // audio, video, image
  String title;
  List<String> tags;
  DateTime createdAt;

  MediaItem({
    this.id,
    this.projectId,
    required this.path,
    required this.type,
    this.title = '',
    List<String>? tags,
    DateTime? createdAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'path': path,
      'type': type,
      'title': title,
      'tags': jsonEncode(tags),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> m) {
    return MediaItem(
      id: m['id'] as int?,
      projectId: m['project_id'] as int?,
      path: m['path'],
      type: m['type'],
      title: m['title'] ?? '',
      tags: m['tags'] != null ? List<String>.from(json.decode(m['tags'])) : [],
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory MediaItem.fromJson(String s) => MediaItem.fromMap(json.decode(s));
}