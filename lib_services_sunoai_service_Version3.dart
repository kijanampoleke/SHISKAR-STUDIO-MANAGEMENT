import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SunoAIService {
  static const String _apiKeyPref = 'suno_api_key';
  static const String _lastOutputPref = 'suno_last_output';
  final Duration timeout;

  SunoAIService({this.timeout = const Duration(seconds: 60)});

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<void> setLastOutput(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOutputPref, path);
  }

  Future<String?> getLastOutput() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOutputPref);
  }

  Future<String> generateFromPrompt({
    required String prompt,
    String? model,
    String? format,
    Map<String, dynamic>? extraParams,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Suno API key not set. Enter it in Settings.');
    }

    final endpoint = Uri.parse('https://api.suno.ai/v1/generate'); // placeholder
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = <String, dynamic>{
      'prompt': prompt,
      if (model != null) 'model': model,
      if (format != null) 'format': format,
      if (extraParams != null) 'params': extraParams,
    };

    final http.Response res = await http
        .post(endpoint, headers: headers, body: jsonEncode(body))
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Suno request failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> jsonBody = jsonDecode(res.body) as Map<String, dynamic>;

    if (jsonBody.containsKey('audio_base64')) {
      final base64Str = jsonBody['audio_base64'] as String;
      final mime = (jsonBody['mime'] as String?) ?? 'audio/wav';
      final bytes = base64Decode(base64Str);
      final saved = await _saveBytesToFile(bytes, mime);
      await setLastOutput(saved);
      return saved;
    }

    if (jsonBody.containsKey('download_url')) {
      final url = jsonBody['download_url'] as String;
      final mime = (jsonBody['mime'] as String?) ?? 'audio/mpeg';
      final bytes = await _downloadBytes(url);
      final saved = await _saveBytesToFile(bytes, mime);
      await setLastOutput(saved);
      return saved;
    }

    if (jsonBody.containsKey('resources') && jsonBody['resources'] is List && jsonBody['resources'].isNotEmpty) {
      final r = jsonBody['resources'][0] as Map<String, dynamic>;
      if (r.containsKey('audio_base64')) {
        final bytes = base64Decode(r['audio_base64'] as String);
        final mime = (r['mime'] as String?) ?? 'audio/wav';
        final saved = await _saveBytesToFile(bytes, mime);
        await setLastOutput(saved);
        return saved;
      }
      if (r.containsKey('download_url')) {
        final bytes = await _downloadBytes(r['download_url'] as String);
        final mime = (r['mime'] as String?) ?? 'audio/mpeg';
        final saved = await _saveBytesToFile(bytes, mime);
        await setLastOutput(saved);
        return saved;
      }
    }

    throw Exception('Suno response did not contain audio (unexpected response shape)');
  }

  Future<List<int>> _downloadBytes(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Download failed: ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  Future<String> _saveBytesToFile(List<int> bytes, String mime) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/suno_outputs');
    if (!await outDir.exists()) await outDir.create(recursive: true);

    final ext = _extFromMime(mime);
    final filename = 'suno_${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}$ext';
    final file = File('${outDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _extFromMime(String mime) {
    final m = mime.split(';').first.trim().toLowerCase();
    if (m.contains('mpeg') || m.contains('mp3')) return '.mp3';
    if (m.contains('wav')) return '.wav';
    if (m.contains('ogg')) return '.ogg';
    if (m.contains('webm')) return '.webm';
    return '.wav';
  }
}