import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final tasks = provider.tasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) {
          final t = tasks[i];
          return Card(
            child: ListTile(
              leading: Checkbox(
                value: t.done,
                onChanged: (v) {
                  t.done = v ?? false;
                  provider.updateTask(t);
                },
              ),
              title: Text(t.title),
              subtitle: Text('Priority: ${['Low','Medium','High'][t.priority]} • ${ (t.progress*100).round()}%'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => provider.deleteTask(t.id!),
              ),
              onTap: () => _showEditDialog(ctx, provider, t),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateTaskDialog(context),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final _title = TextEditingController();
    int priority = 1;
    int? projectId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: priority,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Low')),
                  DropdownMenuItem(value: 1, child: Text('Medium')),
                  DropdownMenuItem(value: 2, child: Text('High')),
                ],
                onChanged: (v) => priority = v ?? 1,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 8),
              Consumer<ProjectProvider>(
                builder: (context, provider, _) => DropdownButtonFormField<int?>(
                  value: projectId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No project')),
                    ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                  ],
                  onChanged: (v) => projectId = v,
                  decoration: const InputDecoration(labelText: 'Attach to project'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              final t = TaskItem(projectId: projectId ?? -1, title: title, priority: priority);
              await context.read<ProjectProvider>().addTask(t);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task added')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ProjectProvider provider, TaskItem t) {
    final _title = TextEditingController(text: t.title);
    int priority = t.priority;
    double progress = t.progress;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Task'),
        content: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: priority,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Low')),
                  DropdownMenuItem(value: 1, child: Text('Medium')),
                  DropdownMenuItem(value: 2, child: Text('High')),
                ],
                onChanged: (v) => setState(() => priority = v ?? 1),
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Progress'),
                  Expanded(
                    child: Slider(
                      value: progress,
                      onChanged: (v) => setState(() => progress = v),
                      divisions: 10,
                      label: '${(progress * 100).round()}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              t.title = _title.text.trim();
              t.priority = priority;
              t.progress = progress;
              await provider.updateTask(t);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}