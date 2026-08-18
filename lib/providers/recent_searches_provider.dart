import 'package:flutter/foundation.dart';

import '../services/recent_searches_service.dart';

class RecentSearchesProvider extends ChangeNotifier {
  final RecentSearchesService _service;

  RecentSearchesProvider({required RecentSearchesService service})
      : _service = service {
    _load();
  }

  List<String> _searches = [];
  List<String> get searches => List.unmodifiable(_searches);

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> _load() async {
    _searches = await _service.getRecentSearches();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _searches = await _service.getRecentSearches();
    notifyListeners();
  }
}
