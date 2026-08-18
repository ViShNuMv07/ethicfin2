class GithubUser {
  final String login;
  final String? name;
  final String avatarUrl;
  final String? bio;
  final int followers;
  final int following;
  final int publicRepos;
  final String htmlUrl;

  const GithubUser({
    required this.login,
    this.name,
    required this.avatarUrl,
    this.bio,
    required this.followers,
    required this.following,
    required this.publicRepos,
    required this.htmlUrl,
  });

  factory GithubUser.fromJson(Map<String, dynamic> json) {
    return GithubUser(
      login: json['login'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String?,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      publicRepos: json['public_repos'] as int? ?? 0,
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }


  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : login;
}
