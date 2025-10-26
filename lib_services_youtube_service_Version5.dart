import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YouTubeService {
  static const Map<String, String> defaultChannels = {
    'SHISKARMUSIC': 'shiskarmusic',
    'HANDYBOYVICTOR': 'handyboyvictor',
  };

  static const List<String> defaultChannelKeys = ['SHISKARMUSIC', 'HANDYBOYVICTOR'];

  static const String _cacheKeyPrefix = 'yt_feed_cache_';

  final int minLongFormSeconds;
  final Duration _timeout;

  YouTubeService({required this.minLongFormSeconds, Duration timeout = const Duration(seconds: 10)})
      : _timeout = timeout;

  Future<Map<String, dynamic>?> readCacheFor(String channelKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cacheKeyPrefix$channelKey');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String?> resolveChannelIdFromHandle(String handle) async {
    final urls = [
      'https://www.youtube.com/@$handle',
      'https://youtube.com/@$handle',
      'https://www.youtube.com/c/$handle',
      'https://youtube.com/c/$handle',
    ];

    final RegExp idRe = RegExp(r'"channelId"\s*:\s*"(?<id>UC[0-9A-Za-z_\-]{20,})"');
    final RegExp externalIdRe = RegExp(r'"externalId"\s*:\s*"(?<id>UC[0-9A-Za-z_\-]{20,})"');
    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(_timeout);
        if (res.statusCode != 200) continue;
        final body = res.body;
        final m = idRe.firstMatch(body) ?? externalIdRe.firstMatch(body);
        if (m != null && m.namedGroup('id') != null) {
          return m.namedGroup('id');
        }
        final genRe = RegExp(r'("channelId"\s*:\s*"(?<id>UC[0-9A-Za-z_\-]{20,})")');
        final mm = genRe.firstMatch(body);
        if (mm != null) return mm.namedGroup('id');
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchFeedByChannelId(String channelId) async {
    final url = 'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId';
    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch RSS feed: ${res.statusCode} for $channelId');
    }
    final xmlDoc = XmlDocument.parse(res.body);
    final entries = xmlDoc.findAllElements('entry');
    final List<Map<String, dynamic>> videos = [];
    for (final entry in entries) {
      final id = entry.getElement('yt:videoId')?.innerText ?? '';
      if (id.isEmpty) continue;
      final title = entry.getElement('title')?.innerText ?? '';
      final published = entry.getElement('published')?.innerText ?? '';
      final linkElem = entry.findElements('link').firstWhere((_) => true, orElse: () => XmlElement(XmlName('link')));
      final link = linkElem.getAttribute('href') ?? 'https://www.youtube.com/watch?v=$id';
      final thumbnail = 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
      videos.add({
        'id': id,
        'title': title,
        'published': published,
        'link': link,
        'thumbnail': thumbnail,
      });
    }
    return videos;
  }

  Future<int?> fetchVideoDurationSeconds(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = res.body;
      final lengthSecondsRe = RegExp(r'["\']lengthSeconds["\']\s*:\s*["\']?(?<sec>\d{1,6})["\']?');
      final m1 = lengthSecondsRe.firstMatch(body);
      if (m1 != null) return int.tryParse(m1.namedGroup('sec') ?? '');
      final approxMsRe = RegExp(r'["\']approxDurationMs["\']\s*:\s*(?<ms>\d{2,12})');
      final m2 = approxMsRe.firstMatch(body);
      if (m2 != null) {
        final ms = int.tryParse(m2.namedGroup('ms') ?? '');
        if (ms != null) return (ms / 1000).round();
      }
      final microformatRe = RegExp(r'playerMicroformatRenderer.*?["\']lengthSeconds["\']\s*:\s*["\']?(?<sec>\d{1,6})["\']?', dotAll: true);
      final m3 = microformatRe.firstMatch(body);
      if (m3 != null) return int.tryParse(m3.namedGroup('sec') ?? '');
      final altRe = RegExp(r'"duration"\s*:\s*{\s*["\']seconds["\']\s*:\s*["\']?(?<sec>\d{1,6})["\']?', dotAll: true);
      final m4 = altRe.firstMatch(body);
      if (m4 != null) return int.tryParse(m4.namedGroup('sec') ?? '');
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAndCacheAll(Map<String, String> channelsMap) async {
    final prefs = await SharedPreferences.getInstance();
    for (final kv in channelsMap.entries) {
      final channelKey = kv.key;
      final handle = kv.value;
      try {
        final channelId = await resolveChannelIdFromHandle(handle);
        if (channelId == null) {
          continue;
        }
        final feed = await fetchFeedByChannelId(channelId);
        final List<Map<String, dynamic>> longForm = [];
        const int concurrency = 5;
        final sem = _AsyncSemaphore(concurrency);
        final futures = <Future>[];
        for (final v in feed) {
          futures.add(() async {
            await sem.acquire();
            try {
              final vid = v['id'] as String;
              final dur = await fetchVideoDurationSeconds(vid);
              final seconds = dur ?? 0;
              if (seconds >= minLongFormSeconds) {
                final copy = Map<String, dynamic>.from(v);
                copy['duration_seconds'] = seconds;
                longForm.add(copy);
              }
            } finally {
              sem.release();
            }
          }());
        }
        await Future.wait(futures);
        longForm.sort((a, b) {
          final pa = a['published'] as String? ?? '';
          final pb = b['published'] as String? ?? '';
          return pb.compareTo(pa);
        });
        final obj = {
          'fetched_at': DateTime.now().toIso8601String(),
          'channel_id': channelId,
          'handle': handle,
          'videos': longForm,
        };
        await prefs.setString('$_cacheKeyPrefix$channelKey', jsonEncode(obj));
      } catch (e) {
        // ignore individual channel errors
      }
    }
  }
}

class _AsyncSemaphore {
  final int _maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waiters = [];

  _AsyncSemaphore(this._maxConcurrent);

  Future<void> acquire() {
    if (_current < _maxConcurrent) {
      _current++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    _current--;
    if (_waiters.isNotEmpty) {
      final c = _waiters.removeAt(0);
      _current++;
      c.complete();
    }
  }
}