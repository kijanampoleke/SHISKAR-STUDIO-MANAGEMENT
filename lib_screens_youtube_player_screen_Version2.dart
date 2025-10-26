import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  const YouTubePlayerScreen({super.key, required this.videoId, required this.title});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        desktopMode: false,
        privacyEnhanced: true,
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_outlined),
            tooltip: 'Enter fullscreen/mini player',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the player fullscreen button')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Preview'),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayerControllerProvider(
              controller: _controller,
              child: YoutubePlayerIFrame(
                gestureRecognizers: const {},
              ),
            ),
          ),
          _buildHeader(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  onPressed: () {
                    _controller.play();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  onPressed: () {
                    _controller.pause();
                  },
                ),
                const Spacer(),
                TextButton(
                  child: const Text('Open on YouTube'),
                  onPressed: () {
                    _controller.getVideoUrl().then((url) {
                      if (url != null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open externally from previous screen')));
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}