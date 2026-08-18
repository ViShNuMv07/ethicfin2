import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesService {
  static const _key = 'recent_searches_v1';
  static const maxItems = 5;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {

      return [];
    }
  }

  Future<void> addSearch(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentSearches();
    current.removeWhere((e) => e.toLowerCase() == username.toLowerCase());
    current.insert(0, username);
    final trimmed = current.take(maxItems).toList();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
