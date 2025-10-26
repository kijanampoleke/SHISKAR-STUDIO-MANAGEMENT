import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ResearchService {
  static const String _googleApiKeyPref = 'google_api_key';
  static const String _googleCxPref = 'google_cx';
  static const String _openAiKeyPref = 'openai_api_key';

  Future<void> setGoogleCredentials(String apiKey, String cx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleApiKeyPref, apiKey);
    await prefs.setString(_googleCxPref, cx);
  }

  Future<Map<String, dynamic>> searchGoogle(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_googleApiKeyPref);
    final cx = prefs.getString(_googleCxPref);
    if (apiKey == null || cx == null) throw Exception('Google API key and CX required');
    final url = Uri.https('www.googleapis.com', '/customsearch/v1', {'key': apiKey, 'cx': cx, 'q': query});
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Search failed: ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> setAssistantKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAiKeyPref, key);
  }
}