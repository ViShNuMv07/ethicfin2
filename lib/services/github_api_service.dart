import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/github_repo.dart';
import '../models/github_user.dart';
import 'github_exceptions.dart';

class GithubApiService {
  static const _baseUrl = 'https://api.github.com';

  final http.Client _client;

  GithubApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<GithubUser> fetchUser(String username) async {
    final uri = Uri.parse('$_baseUrl/users/$username');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GithubUser.fromJson(json);
    }
    if (response.statusCode == 404) {
      throw UserNotFoundException(username);
    }
    if (response.statusCode == 403) {
      throw GithubApiException(
          'GitHub API rate limit exceeded. Please try again later.');
    }
    throw GithubApiException(
        'Failed to load user (status ${response.statusCode}).');
  }

  Future<List<GithubRepo>> fetchRepos(String username) async {
    final uri = Uri.parse(
        '$_baseUrl/users/$username/repos?per_page=100&sort=updated');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => GithubRepo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 404) {
      throw UserNotFoundException(username);
    }
    if (response.statusCode == 403) {
      throw GithubApiException(
          'GitHub API rate limit exceeded. Please try again later.');
    }
    throw GithubApiException(
        'Failed to load repositories (status ${response.statusCode}).');
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/vnd.github+json',
      };

  void dispose() => _client.close();
}
