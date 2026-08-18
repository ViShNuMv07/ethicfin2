import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/github_repo.dart';
import '../services/github_api_service.dart';
import '../services/github_exceptions.dart';
import 'request_state.dart';

enum RepoSortOption { stars, recentlyUpdated }

class RepoListProvider extends ChangeNotifier {
  final GithubApiService _apiService;

  RepoListProvider({required GithubApiService apiService})
      : _apiService = apiService;

  RequestState _state = RequestState.idle;
  RequestState get state => _state;

  List<GithubRepo> _repos = [];

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  RepoSortOption _sortOption = RepoSortOption.stars;
  RepoSortOption get sortOption => _sortOption;

  List<GithubRepo> get repos {
    final sorted = List<GithubRepo>.from(_repos);
    switch (_sortOption) {
      case RepoSortOption.stars:
        sorted.sort((a, b) => b.stargazersCount.compareTo(a.stargazersCount));
        break;
      case RepoSortOption.recentlyUpdated:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return sorted;
  }

  Future<void> fetchRepos(String username) async {
    _state = RequestState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final repos = await _apiService.fetchRepos(username);
      _repos = repos;
      _state = RequestState.success;
    } on UserNotFoundException catch (e) {
      _state = RequestState.error;
      _errorMessage = "No repositories found for \"${e.username}\".";
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

  void setSortOption(RepoSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }
}
