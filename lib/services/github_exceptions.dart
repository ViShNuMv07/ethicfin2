class UserNotFoundException implements Exception {
  final String username;
  UserNotFoundException(this.username);

  @override
  String toString() => 'UserNotFoundException: "$username" was not found';
}


class GithubApiException implements Exception {
  final String message;
  GithubApiException(this.message);

  @override
  String toString() => 'GithubApiException: $message';
}
