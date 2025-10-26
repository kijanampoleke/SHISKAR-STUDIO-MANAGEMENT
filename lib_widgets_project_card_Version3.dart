import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import '../screens/project_detail_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: _iconForType(project.type),
        ),
        title: Text(project.title),
        subtitle: Text('${project.type} • ${project.status}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
        ),
      ),
    );
  }

  Widget _iconForType(String type) {
    switch (type) {
      case 'music':
        return const Icon(Icons.music_note, color: Colors.deepPurple);
      case 'video':
        return const Icon(Icons.videocam, color: Colors.deepPurple);
      case 'photo':
        return const Icon(Icons.photo, color: Colors.deepPurple);
      case 'tech':
      default:
        return const Icon(Icons.build, color: Colors.deepPurple);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('This will remove the project and associated data. Are you sure you want to delete "${project.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (project.id != null) await context.read<ProjectProvider>().deleteProject(project.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}