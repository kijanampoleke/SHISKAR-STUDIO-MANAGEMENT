import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/audio_player_widget.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String path;
  final String type;
  final String title;
  const MediaPreviewScreen({super.key, required this.path, required this.type, required this.title});

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _videoController = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          setState(() {
            _videoReady = true;
            _videoController?.setLooping(false);
          });
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.type == 'image') IconButton(icon: const Icon(Icons.zoom_in), onPressed: () {}),
        ],
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.type == 'image') {
      return InteractiveViewer(
        key: ValueKey(widget.path),
        child: Image.file(File(widget.path)),
      );
    } else if (widget.type == 'video') {
      if (!_videoReady) {
        return const CircularProgressIndicator();
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          const SizedBox(height: 8),
          VideoProgressIndicator(_videoController!, allowScrubbing: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => setState(() {
                  _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                }),
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final pos = _videoController!.value.position;
                  _videoController!.seekTo(pos - const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ],
      );
    } else if (widget.type == 'audio') {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: AudioPlayerWidget(filePath: widget.path, title: widget.title),
      );
    } else {
      return const Text('Preview not supported');
    }
  }
}