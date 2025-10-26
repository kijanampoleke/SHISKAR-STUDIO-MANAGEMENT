import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoLinkPreviewScreen extends StatefulWidget {
  final String url;
  final String title;
  const VideoLinkPreviewScreen({super.key, required this.url, this.title = ''});

  @override
  State<VideoLinkPreviewScreen> createState() => _VideoLinkPreviewScreenState();
}

class _VideoLinkPreviewScreenState extends State<VideoLinkPreviewScreen> {
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = _extractYouTubeId(widget.url);
    _isYoutube = _videoId != null;
    if (_isYoutube && _videoId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: _videoId!,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          privacyEnhanced: true,
          useHybridComposition: true,
        ),
      );
    } else {
      if (Platform.isAndroid) WebView.platform = AndroidWebView();
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    if (uri.host.contains('youtube.com')) {
      if (uri.queryParameters.containsKey('v')) return uri.queryParameters