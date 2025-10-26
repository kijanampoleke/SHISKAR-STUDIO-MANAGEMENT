import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class ChannelManagerScreen extends StatefulWidget {
  const ChannelManagerScreen({super.key});

  @override
  State<ChannelManagerScreen> createState() => _ChannelManagerScreenState();
}

class _ChannelManagerScreenState extends State<ChannelManagerScreen> {
  final _handleController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _handleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage YouTube Channels')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Add a channel by handle (e.g., shiskarmusic) and a local key label.'),
            const SizedBox(height: 8),
            TextField(controller: _keyController, decoration: const InputDecoration(labelText: 'Key / Label (unique)'), autocorrect: false),
            const SizedBox(height: 8),
            TextField(controller: _handleController, decoration: const InputDecoration(labelText: 'Handle (without @)'), autocorrect: false),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  child: const Text('Add Channel'),
                  onPressed: () async {
                    final key = _keyController.text.trim();
                    final handle = _handleController.text.trim();
                    if (key.isEmpty || handle.isEmpty) return;
                    await provider.addExtraChannel(key, handle);
                    _keyController.clear();
                    _handleController.clear();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Channel added and sync started')));
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  child: const Text('Sync Now'),
                  onPressed: () async {
                    await provider.manualYoutubeSync();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync completed')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Existing channels'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final built in YouTubeBuiltInList()) _buildChannelRow(context, built['key']!, built['handle']!, provider),
                  const Divider(),
                  for (final ch in provider.extraChannels) _buildChannelRow(context, ch['key']!, ch['handle']!, provider, removable: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelRow(BuildContext context, String key, String handle, ProjectProvider provider, {bool removable = false}) {
    return ListTile(
      leading: const Icon(Icons.video_library),
      title: Text('$key — $handle'),
      subtitle: Text(provider.youtubeCache[key] != null ? 'Cached ${((provider.youtubeCache[key] as Map)['videos'] as List).length} videos' : 'Not cached'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.sync),
          onPressed: () async {
            await provider.manualYoutubeSync();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync completed')));
          },
        ),
        if (removable)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await provider.removeExtraChannel(key);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Channel removed')));
            },
          ),
      ]),
    );
  }

  List<Map<String, String>> YouTubeBuiltInList() {
    return [
      {'key': 'SHISKARMUSIC', 'handle': 'shiskarmusic'},
      {'key': 'HANDYBOYVICTOR', 'handle': 'handyboyvictor'},
    ];
  }
}