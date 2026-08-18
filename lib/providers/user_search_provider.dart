import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/github_user.dart';
import '../services/github_api_service.dart';
import '../services/github_exceptions.dart';
import '../services/recent_searches_service.dart';
import 'request_state.dart';

class UserSearchProvider extends ChangeNotifier {
  final GithubApiService _apiService;
  final RecentSearchesService _recentSearchesService;

  UserSearchProvider({
    required GithubApiService apiService,
    required RecentSearchesService recentSearchesService,
  })  : _apiService = apiService,
        _recentSearchesService = recentSearchesService;

  RequestState _state = RequestState.idle;
  RequestState get state => _state;

  GithubUser? _user;
  GithubUser? get user => _user;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;


  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  Future<void> search(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return;

    _lastQuery = trimmed;
    _state = RequestState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _apiService.fetchUser(trimmed);
      _user = user;
      _state = RequestState.success;
      unawaited(_recentSearchesService.addSearch(user.login));
    } on UserNotFoundException catch (e) {
      _state = RequestState.error;
      _errorMessage = "No GitHub user found for \"${e.username}\".";
    } on SocketException {
      _state = RequestState.error;
      _errorMessage = 'No internet connection. Please check your network.';
    } on GithubApiException catch (e) {
      _state = RequestState.error;
      _errorMessage = e.message;
    } catch (_) {
      _state = RequestState.error;
      _errorMessage = 'Something went wrong. Please try again.';
    }
    notifyListeners();
  }

  void reset() {
    _state = RequestState.idle;
    _user = null;
    _errorMessage = '';
    notifyListeners();
  }
}
