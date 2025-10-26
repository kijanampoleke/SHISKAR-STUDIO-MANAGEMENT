import 'package:shiskar_studio_manager/db/app_database.dart';
import 'package:shiskar_studio_manager/models/project.dart';

class ProjectRepository {
  final db = AppDatabase.instance.db;

  Future<int> insert(Project p) async {
    final id = await db.insert('projects', p.toMap());
    return id;
  }

  Future<int> update(Project p) async {
    if (p.id == null) throw Exception('Project id required for update');
    p.updatedAt = DateTime.now();
    return await db.update('projects', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> delete(int id) async {
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Project>> getAll() async {
    final rows = await db.query('projects', orderBy: 'updated_at DESC');
    return rows.map((r) => Project.fromMap(r)).toList();
  }

  Future<Project?> getById(int id) async {
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }
}