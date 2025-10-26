import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/tech_log.dart';
import '../repositories/project_repository.dart';
import '../db/app_database.dart';
import '../services/youtube_service.dart';
import '../services/reminder_service.dart';
import 'package:workmanager/workmanager.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repo = ProjectRepository();
  List<Project> projects = [];
  bool isDarkMode = true;

  List<TaskItem> tasks = [];
  List<MediaItem> mediaItems = [];
  List<TechLog> techLogs = [];

  Map<String, dynamic> youtubeCache = {}; // channelKey -> cached object
  bool youtubeEnabled = false;
  bool autosyncEnabled = false;
  int autosyncMinutes = 60;

  int minLongFormSeconds = 78;

  List<Map<String, String>> extraChannels = [];

  Timer? _autoTimer;
  final _uuid = Uuid();

  ProjectProvider() {
    _loadTheme();
    _loadYoutubeSettings();
    ReminderService().init();
  }

  Future _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('dark_mode') ?? true;
    notifyListeners();
  }

  Future toggleDarkMode(bool enabled) async {
    isDarkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
    notifyListeners();
  }

  Future _loadYoutubeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    youtubeEnabled = prefs.getBool('youtube_enabled') ?? false;
    autosyncEnabled = prefs.getBool('autosync_enabled') ?? false;
    autosyncMinutes = prefs.getInt('autosync_minutes') ?? 60;
    minLongFormSeconds = prefs.getInt('min_long_form_seconds') ?? 78;

    final chRaw = prefs.getString('extra_channels') ?? '[]';
    final List<dynamic> parsed = jsonDecode(chRaw);
    extraChannels = parsed.map((e) => Map<String, String>.from(e as Map)).toList();

    final svc = YouTubeService(minLongFormSeconds: minLongFormSeconds);
    final Map<String, dynamic> cache = {};
    for (final k in YouTubeService.defaultChannelKeys) {
      final d = await svc.readCacheFor(k);
      if (d != null) cache[k] = d;
    }
    for (final ch in extraChannels) {
      final key = ch['key']!;
      final d = await svc.readCacheFor(key);
      if (d != null) cache[key] = d;
    }
    youtubeCache = cache;
    notifyListeners();
  }

  Future setMinLongFormSeconds(int seconds) async {
    minLongFormSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('min_long_form_seconds', seconds);
    notifyListeners();
  }

  Future addExtraChannel(String key, String handle) async {
    extraChannels.add({'key': key, 'handle': handle});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_channels', jsonEncode(extraChannels));
    notifyListeners();
    await manualYoutubeSync();
  }

  Future removeExtraChannel(String key) async {
    extraChannels.removeWhere((c) => c['key'] == key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_channels', jsonEncode(extraChannels));
    final prefs2 = await SharedPreferences.getInstance();
    await prefs2.remove('yt_feed_cache_$key');
    youtubeCache.remove(key);
    notifyListeners();
  }

  Future toggleYoutubeEnabled(bool enabled) async {
    youtubeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('youtube_enabled', enabled);
    notifyListeners();
    if (enabled && autosyncEnabled) maybeStartAutoSync();
  }

  Future toggleAutosync(bool enabled, {int? minutes}) async {
    autosyncEnabled = enabled;
    if (minutes != null) autosyncMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autosync_enabled', enabled);
    await prefs.setInt('autosync_minutes', autosyncMinutes);
    notifyListeners();
    if (enabled) {
      maybeStartAutoSync();
    } else {
      _stopAutoSync();
    }
  }

  void maybeStartAutoSync() {
    _stopAutoSync();
    if (!youtubeEnabled || !autosyncEnabled) return;
    _autoTimer = Timer.periodic(Duration(minutes: autosyncMinutes), (_) async {
      await _doSync();
    });
    try {
      Workmanager().registerPeriodicTask(
        'shiskar_yt_sync',
        'shiskar_background_sync_task',
        frequency: Duration(minutes: autosyncMinutes),
        initialDelay: const Duration(minutes: 1),
      );
    } catch (e) {}
  }

  void _stopAutoSync() {
    _autoTimer?.cancel();
    _autoTimer = null;
    try {
      Workmanager().cancelByUniqueName('shiskar_yt_sync');
    } catch (_) {}
  }

  Future<void> _doSync() async {
    try {
      final svc = YouTubeService(minLongFormSeconds: minLongFormSeconds);
      final Map<String, String> channelsToFetch = {};
      for (final k in YouTubeService.defaultChannels.entries) {
        channelsToFetch[k.key] = k.value;
      }
      for (final ch in extraChannels) {
        channelsToFetch[ch['key']!] = ch['handle']!;
      }
      await svc.fetchAndCacheAll(channelsToFetch);
      final Map<String, dynamic> cache = {};
      for (final k in channelsToFetch.keys) {
        final d = await svc.readCacheFor(k);
        if (d != null) cache[k] = d;
      }
      youtubeCache = cache;
      notifyListeners();
    } catch (e) {}
  }

  Future manualYoutubeSync() async {
    await _doSync();
  }

  Future<int?> scheduleReminder({
    required String title,
    required String body,
    required DateTime at,
  }) async {
    final id = await ReminderService().scheduleNotification(title: title, body: body, scheduledAt: at);
    return id;
  }

  Future<void> cancelReminder(int id) async {
    await ReminderService().cancelNotification(id);
  }

  Future loadAll() async {
    try {
      projects = await _repo.getAll();
      await _loadTasks();
      await _loadMedia();
      await _loadTechLogs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future _loadTasks() async {
    final db = AppDatabase.instance.db;
    final rows = await db.query('tasks', orderBy: 'updated_at DESC');
    tasks = rows.map((r) => TaskItem.fromMap(r)).toList();
  }

  Future addTask(TaskItem t) async {
    final db = AppDatabase.instance.db;
    t.updatedAt = DateTime.now();
    final id = await db.insert('tasks', t.toMap());
    t.id = id;
    tasks.insert(0, t);
    notifyListeners();
  }

  Future updateTask(TaskItem t) async {
    final db = AppDatabase.instance.db;
    t.updatedAt = DateTime.now();
    await db.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    final i = tasks.indexWhere((x) => x.id == t.id);
    if (i >= 0) tasks[i] = t;
    notifyListeners();
  }

  Future deleteTask(int id) async {
    final db = AppDatabase.instance.db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future _loadMedia() async {
    final db = AppDatabase.instance.db;
    final rows = await db.query('media_items', orderBy: 'created_at DESC');
    mediaItems = rows.map((r) => MediaItem.fromMap(r)).toList();
  }

  Future addMedia(MediaItem m) async {
    final db = AppDatabase.instance.db;
    final id = await db.insert('media_items', m.toMap());
    m.id = id;
    mediaItems.insert(0, m);
    notifyListeners();
  }

  Future updateMedia(MediaItem m) async {
    final db = AppDatabase.instance.db;
    await db.update('media_items', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
    final i = mediaItems.indexWhere((x) => x.id == m.id);
    if (i >= 0) mediaItems[i] = m;
    notifyListeners();
  }

  Future deleteMedia(int id) async {
    final db = AppDatabase.instance.db;
    await db.delete('media_items', where: 'id = ?', whereArgs: [id]);
    mediaItems.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future _loadTechLogs() async {
    final db = AppDatabase.instance.db;
    final rows = await db.query('tech_logs', orderBy: 'created_at DESC');
    techLogs = rows.map((r) => TechLog.fromMap(r)).toList();
  }

  Future addTechLog(TechLog t) async {
    final db = AppDatabase.instance.db;
    final id = await db.insert('tech_logs', t.toMap());
    t.id = id;
    techLogs.insert(0, t);
    notifyListeners();
  }

  Future updateTechLog(TechLog t) async {
    final db = AppDatabase.instance.db;
    await db.update('tech_logs', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    final i = techLogs.indexWhere((x) => x.id == t.id);
    if (i >= 0) techLogs[i] = t;
    notifyListeners();
  }

  Future deleteTechLog(int id) async {
    final db = AppDatabase.instance.db;
    await db.delete('tech_logs', where: 'id = ?', whereArgs: [id]);
    techLogs.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<String> exportAllAsJson() async {
    final db = AppDatabase.instance.db;
    final pRows = await db.query('projects');
    final tRows = await db.query('tasks');
    final mRows = await db.query('media_items');
    final lRows = await db.query('tech_logs');

    final obj = {
      'projects': pRows,
      'tasks': tRows,
      'media_items': mRows,
      'tech_logs': lRows,
      'exported_at': DateTime.now().toIso8601String(),
    };

    return jsonEncode(obj);
  }

  Future<void> importFromJson(String jsonText) async {
    final db = AppDatabase.instance.db;
    final data = jsonDecode(jsonText);
    final batch = db.batch();

    if (data['projects'] is List) {
      for (final p in data['projects']) {
        batch.insert('projects', Map<String, dynamic>.from(p));
      }
    }
    if (data['tasks'] is List) {
      for (final t in data['tasks']) {
        batch.insert('tasks', Map<String, dynamic>.from(t));
      }
    }
    if (data['media_items'] is List) {
      for (final m in data['media_items']) {
        batch.insert('media_items', Map<String, dynamic>.from(m));
      }
    }
    if (data['tech_logs'] is List) {
      for (final l in data['tech_logs']) {
        batch.insert('tech_logs', Map<String, dynamic>.from(l));
      }
    }
    await batch.commit(noResult: true);
    await loadAll();
  }
}