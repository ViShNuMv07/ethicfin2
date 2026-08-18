import 'package:flutter/material.dart';

import '../models/github_repo.dart';
import '../utils/date_formatter.dart';

class RepoTile extends StatelessWidget {
  final GithubRepo repo;

  const RepoTile({super.key, required this.repo});

  String formatRelativeDate(DateTime? date) {
    if (date == null) return 'No date';
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repo.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (repo.description != null && repo.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                repo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (repo.language != null && repo.language!.isNotEmpty) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _languageColor(repo.language!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(repo.language!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.star_border, size: 16),
                const SizedBox(width: 2),
                Text('${repo.stargazersCount}', style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  formatRelativeDate(repo.updatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _languageColor(String language) {
    const colors = {
      'Dart': Colors.blue,
      'JavaScript': Colors.amber,
      'TypeScript': Colors.blueAccent,
      'Python': Colors.green,
      'Java': Colors.orange,
      'Swift': Colors.deepOrange,
      'Kotlin': Colors.purple,
      'C++': Colors.pink,
      'C': Colors.blueGrey,
      'Go': Colors.cyan,
      'Ruby': Colors.red,
      'HTML': Colors.deepOrange,
      'CSS': Colors.indigo,
    };
    return colors[language] ?? Colors.grey;
  }
}