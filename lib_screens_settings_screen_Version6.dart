import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'channel_manager_screen.dart';
import 'suno_generator_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/sunoai_service.dart';
import '../services/research_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sunoKeyController = TextEditingController();
  final _googleKeyController = TextEditingController();
  final _googleCxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSunoKey();
  }

  Future<void> _loadSunoKey() async {
    final key = await SunoAIService().getApiKey();
    if (mounted) setState(() => _sunoKeyController.text = key ?? '');
  }

  @override
  void dispose() {
    _sunoKeyController.dispose();
    _googleKeyController.dispose();
    _googleCxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: provider.isDarkMode,
            onChanged: (v) => provider.toggleDarkMode(v),
          ),
          const Divider(),
          ListTile(
            title: const Text('Long-form threshold (seconds)'),
            subtitle: Text('${provider.minLongFormSeconds} seconds (videos longer than this will be shown)'),
            trailing: SizedBox(
              width: 160,
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: provider.minLongFormSeconds.toDouble(),
                      min: 30,
                      max: 3600,
                      divisions: 60,
                      label: '${provider.minLongFormSeconds}s',
                      onChanged: (v) {
                        provider.setMinLongFormSeconds(v.round());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('Manage YouTube channels'),
            subtitle: const Text('Add or remove channels to follow long-form content'),
            trailing: ElevatedButton(
              child: const Text('Manage'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChannelManagerScreen())),
            ),
          ),
          SwitchListTile(
            title: const Text('YouTube Preview'),
            subtitle: const Text('Show latest videos from configured channels'),
            value: provider.youtubeEnabled,
            onChanged: (v) => provider.toggleYoutubeEnabled(v),
          ),
          SwitchListTile(
            title: const Text('Autosync YouTube Feeds'),
            subtitle: Text('Sync every ${provider.autosyncMinutes} minutes (background when possible)'),
            value: provider.autosyncEnabled,
            onChanged: (v) => provider.toggleAutosync(v),
          ),
          if (provider.youtubeEnabled)
            ListTile(
              title: ElevatedButton(child: const Text('Sync Now'), onPressed: () async {
                await provider.manualYoutubeSync();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube feeds updated')));
              }),
            ),
          const Divider(),
          ListTile(
            title: const Text('SunoAI'),
            subtitle: const Text('Enter your Suno API key and open the generator'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(children: [
              Expanded(child: TextField(controller: _sunoKeyController, decoration: const InputDecoration(labelText: 'Suno API key'))),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () async {
                  await SunoAIService().setApiKey(_sunoKeyController.text.trim());
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suno API key saved')));
                },
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: const Text('Open Suno Generator'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SunoGeneratorScreen())),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Research / Assistant integration (optional)'),
            subtitle: const Text('Configure Google Custom Search or assistant API keys'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(children: [
              TextField(controller: _googleKeyController, decoration: const InputDecoration(labelText: 'Google API Key')),
              const SizedBox(height: 8),
              TextField(controller: _googleCxController, decoration: const InputDecoration(labelText: 'Custom Search CX')),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(
                  child: const Text('Save Google'),
                  onPressed: () async {
                    await ResearchService().setGoogleCredentials(_googleKeyController.text.trim(), _googleCxController.text.trim());
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google search config saved')));
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  child: const Text('Open Research'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Research screen not implemented - opens a browser search instead')));
                  },
                ),
              ]),
            ]),
          ),
          const Divider(),
          ListTile(
            title: const Text('Lyrics editor (Music)'),
            subtitle: const Text('Use the built-in editor. You can open a new Google Doc in browser with the button below.'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open new Google Doc'),
            onPressed: () async {
              final uri = Uri.parse('https://docs.new');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open browser')));
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Export data (to SD/USB)'),
            subtitle: const Text('Exports a JSON snapshot of all data.'),
            trailing: ElevatedButton(onPressed: () {}, child: const Text('Export')),
          ),
          const Divider(),
          ListTile(
            title: const Text('App storage location'),
            subtitle: FutureBuilder(
              future: getApplicationDocumentsDirectory(),
              builder: (ctx, snap) => Text(snap.hasData ? (snap.data as Directory).path : 'Loading...'),
            ),
          ),
        ],
      ),
    );
  }
}