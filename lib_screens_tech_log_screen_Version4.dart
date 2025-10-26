import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tech_log.dart';
import '../providers/project_provider.dart';
import 'video_link_preview_screen.dart';

class TechLogScreen extends StatelessWidget {
  const TechLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final logs = provider.techLogs;

    return Scaffold(
      appBar: AppBar(title: const Text('Tech Logbook')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        itemBuilder: (ctx, i) {
          final log = logs[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.note),
              title: Text(log.title),
              subtitle: Text(log.notes),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => provider.deleteTechLog(log.id!),
              ),
              onTap: () => _showEditDialog(context, provider, log),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateDialog(context),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final _title = TextEditingController();
    final _notes = TextEditingController();
    final _videoUrl = TextEditingController();
    int? projectId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tech Log'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 8),
              TextField(controller: _videoUrl, decoration: const InputDecoration(labelText: 'Related video URL (optional)')),
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
              final t = TechLog(projectId: projectId, title: title, notes: _notes.text.trim(), diagramPath: '', createdAt: DateTime.now());
              if (_videoUrl.text.trim().isNotEmpty) {
                t.notes = '${t.notes}\n\nRelated Video: ${_videoUrl.text.trim()}';
              }
              await context.read<ProjectProvider>().addTechLog(t);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ProjectProvider provider, TechLog log) {
    final _title = TextEditingController(text: log.title);
    final _notes = TextEditingController(text: log.notes);
    final _videoPeek = _extractVideoUrlFromNotes(log.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Tech Log'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 8),
              if (_videoPeek != null)
                Column(
                  children: [
                    Row(
                      children: [
                        const Text('Related video detected'),
                        const Spacer(),
                        ElevatedButton(
                          child: const Text('Preview'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VideoLinkPreviewScreen(url: _videoPeek)));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              log.title = _title.text.trim();
              log.notes = _notes.text.trim();
              await provider.updateTechLog(log);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _extractVideoUrlFromNotes(String notes) {
    final lines = notes.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('http')) return trimmed;
    }
    return null;
  }
}