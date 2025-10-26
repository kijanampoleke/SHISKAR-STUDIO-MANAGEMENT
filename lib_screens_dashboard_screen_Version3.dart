import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shiskar Studio')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(child: Text('Projects', style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'New Project',
                  onPressed: () => _showCreateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.projects.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: const [
                    Icon(Icons.folder_open, size: 72, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No projects yet. Tap + to create one.'),
                  ],
                ),
              )
            else
              ...provider.projects.map((p) => ProjectCard(project: p)).toList(),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final _titleController = TextEditingController();
    String _type = 'music';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), autofocus: true),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (_, setState) => DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'music', child: Text('Music')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'photo', child: Text('Photo')),
                    DropdownMenuItem(value: 'tech', child: Text('Tech')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'music'),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                await context.read<ProjectProvider>().addProject(title: title, type: _type);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project created')));
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}