import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final String title;
  const AudioPlayerWidget({super.key, required this.filePath, required this.title});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  late StreamSubscription<Duration?> _durationSub;
  late StreamSubscription<Duration> _positionSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future _init() async {
    try {
      await _player.setFilePath(widget.filePath);
      _duration = _player.duration ?? Duration.zero;
      _durationSub = _player.durationStream.listen((d) {
        setState(() => _duration = d ?? Duration.zero);
      });
      _positionSub = _player.positionStream.listen((p) {
        setState(() => _position = p);
      });
      _player.playerStateStream.listen((st) {
        setState(() => _isPlaying = st.playing);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio load error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _durationSub.cancel();
    _positionSub.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    if (hh > 0) return '$hh:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.audiotrack),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 30),
                onPressed: _loading ? null : () => _isPlaying ? _player.pause() : _player.play(),
              ),
            ]),
            const SizedBox(height: 6),
            Slider(
              value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble() == 0 ? 1 : _duration.inMilliseconds.toDouble()),
              max: _duration.inMilliseconds.toDouble() <= 0 ? 1 : _duration.inMilliseconds.toDouble(),
              onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_format(_position)), Text(_format(_duration))],
            ),
          ],
        ),
      ),
    );
  }
}