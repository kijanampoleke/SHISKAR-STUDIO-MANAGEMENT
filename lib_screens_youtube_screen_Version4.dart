import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'youtube_player_screen.dart';

class YouTubeScreen extends StatelessWidget {
  const YouTubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    if (!provider.youtubeEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('YouTube preview is disabled. Enable it in Settings to see latest long-form videos.'),
              const SizedBox(height: 12),
              ElevatedButton(
                child: const Text('Open Settings'),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              )
            ],
          ),
        ),
      );
    }

    final keys = provider.youtubeCache.keys.toList();
    if (keys.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('YouTube Channels')),
        body: const Center(child: Text('No cached long-form videos yet. Use Sync Now to download long-form listings.')),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.sync),
          label: const Text('Sync Now'),
          onPressed: () async {
            await provider.manualYoutubeSync();
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube feeds updated')));
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Long-form')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Selected channels — long-form videos only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          for (final channelKey in keys)
            _ChannelBlock(channelKey: channelKey, data: provider.youtubeCache[channelKey] as Map<String, dynamic>),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.sync),
        label: const Text('Sync Now'),
        onPressed: () async {
          await provider.manualYoutubeSync();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube feeds updated')));
        },
      ),
    );
  }
}

class _ChannelBlock extends StatelessWidget {
  final String channelKey;
  final Map<String, dynamic> data;
  const _ChannelBlock({required this.channelKey, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> videos = data['videos'] ?? [];
    final fetchedAt = data['fetched_at'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.video_library),
        title: Text(channelKey),
        subtitle: Text('Cached ${videos.length} • fetched: ${fetchedAt.split('T').first}'),
        children: videos.isEmpty
            ? [const ListTile(title: Text('No long-form videos found'))]
            : videos.map((v) => _VideoRow(video: Map<String, dynamic>.from(v))).toList(),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  final Map<String, dynamic> video;
  const _VideoRow({required this.video});

  @override
  Widget build(BuildContext context) {
    final thumb = video['thumbnail'] as String? ?? '';
    final title = video['title'] as String? ?? '';
    final published = video['published'] as String? ?? '';
    final id = video['id'] as String? ?? '';
    final duration = video['duration_seconds'] as int? ?? 0;

    String _durationLabel(int s) {
      final h = s ~/ 3600;
      final m = (s % 3600) ~/ 60;
      final sec = s % 60;
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m ${sec}s';
      return '${sec}s';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: thumb.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(thumb, width: 120, fit: BoxFit.cover))
          : const Icon(Icons.ondemand_video),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${published.split('T').first} • ${_durationLabel(duration)}'),
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_fill),
        onPressed: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => YouTubePlayerScreen(videoId: id, title: title)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video id missing')));
          }
        },
      ),
      onTap: () {
        if (id.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => YouTubePlayerScreen(videoId: id, title: title)));
        }
      },
    );
  }
}