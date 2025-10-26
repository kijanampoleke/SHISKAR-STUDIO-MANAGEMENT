import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/media_item.dart';
import '../providers/project_provider.dart';
import 'media_preview_screen.dart';
import 'package:just_audio/just_audio.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});
  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final AudioPlayer _player = AudioPlayer();
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future _pickAndAdd(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    try {
      final r = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (r == null) return;
      final file = r.files.single;
      final ext = file.extension?.toLowerCase() ?? '';
      String type = 'image';
      if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) type = 'audio';
      if (['mp4', 'mov', 'mkv', 'webm'].contains(ext)) type = 'video';
      final path = file.path!;
      final m = MediaItem(path: path, type: type, title: file.name);
      await provider.addMedia(m);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media added locally')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final media = provider.mediaItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Media Organizer')),
      body: media.isEmpty
          ? const Center(child: Text('No media yet. Add audio, video or images.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: media.length,
              itemBuilder: (ctx, i) {
                final m = media[i];
                final thumbnail = (m.type == 'image' || m.type == 'video') && File(m.path).existsSync()
                    ? Image.file(File(m.path), width: 72, height: 48, fit: BoxFit.cover)
                    : const Icon(Icons.audiotrack, size: 48);
                return Card(
                  child: ListTile(
                    leading: Hero(
                      tag: m.id ?? m.path,
                      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: thumbnail),
                    ),
                    title: Text(m.title.isNotEmpty ? m.title : m.path.split('/').last),
                    subtitle: Text('${m.type} • ${m.tags.join(', ')}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (m.type == 'audio')
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () async {
                            try {
                              await _player.setFilePath(m.path);
                              _player.play();
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e')));
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.open_in_full),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MediaPreviewScreen(path: m.path, type: m.type, title: m.title),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => provider.deleteMedia(m.id!),
                      ),
                    ]),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaPreviewScreen(path: m.path, type: m.type, title: m.title),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}