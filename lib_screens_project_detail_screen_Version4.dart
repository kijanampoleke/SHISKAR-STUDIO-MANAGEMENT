import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';
import 'video_link_preview_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final TextEditingController _notesController;
  String _status = '';
  DateTime? _deadline;
  final _videoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.project.notes);
    _status = widget.project.status;
    _deadline = widget.project.deadline;
  }

  Future _save() async {
    final p = widget.project;
    p.notes = _notesController.text;
    p.status = _status;
    p.deadline = _deadline;
    await context.read<ProjectProvider>().updateProject(p);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Type: ${widget.project.type}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'done', child: Text('Done')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'open'),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _videoUrlController,
            decoration: const InputDecoration(labelText: 'Related video URL (paste link)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('Preview'),
                onPressed: () {
                  final url = _videoUrlController.text.trim();
                  if (url.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No URL provided')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoLinkPreviewScreen(url: url)));
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Set Reminder'),
                onPressed: () async {
                  final provider = context.read<ProjectProvider>();
                  final id = await provider.scheduleReminder(title: 'Reminder: ${widget.project.title}', body: widget.project.notes, at: DateTime.now().add(const Duration(hours: 1)));
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder scheduled (id: $id)')));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_deadline != null ? 'Deadline: ${_deadline!.toLocal().toIso8601String().split('T').first}' : 'No deadline'),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _deadline = d);
                },
                child: const Text('Set'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}