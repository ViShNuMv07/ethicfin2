import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_repo.dart';
import '../providers/repo_list_provider.dart';
import '../providers/request_state.dart';
import '../utils/responsive.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/repo_tile.dart';

class RepositoriesScreen extends StatefulWidget {
  final String username;

  const RepositoriesScreen({super.key, required this.username});

  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RepoListProvider>().fetchRepos(widget.username);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: Text("${widget.username}'s Repositories"),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hPad = responsiveHorizontalPadding(constraints.maxWidth);

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
                      child: Consumer<RepoListProvider>(
                        builder: (context, provider, _) {
                          return Row(
                            children: [
                              const Text('Sort by:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SegmentedButton<RepoSortOption>(
                                  segments: const [
                                    ButtonSegment(
                                      value: RepoSortOption.stars,
                                      label: Text('Stars'),
                                      icon: Icon(Icons.star),
                                    ),
                                    ButtonSegment(
                                      value: RepoSortOption.recentlyUpdated,
                                      label: Text('Recent'),
                                      icon: Icon(Icons.update),
                                    ),
                                  ],
                                  selected: {provider.sortOption},
                                  onSelectionChanged: (selection) =>
                                      provider.setSortOption(selection.first),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<RepoListProvider>(
                        builder: (context, provider, _) {
                          switch (provider.state) {
                            case RequestState.loading:
                            case RequestState.idle:
                              return const LoadingView();
                            case RequestState.error:
                              return ErrorView(
                                message: provider.errorMessage,
                                onRetry: () =>
                                    provider.fetchRepos(widget.username),
                              );
                            case RequestState.success:
                              final repos = provider.repos;
                              if (repos.isEmpty) {
                                return const Center(
                                  child: Text('No public repositories found'),
                                );
                              }
                              return _ResponsiveRepoList(
                                repos: repos,
                                horizontalPadding: hPad,
                              );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveRepoList extends StatelessWidget {
  final List<GithubRepo> repos;
  final double horizontalPadding;

  const _ResponsiveRepoList({
    required this.repos,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = repoGridColumns(constraints.maxWidth);

        if (columns == 1) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: repos.length,
            itemBuilder: (context, index) => RepoTile(repo: repos[index]),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding - 16,
            8,
            horizontalPadding - 16,
            16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 168,
          ),
          itemCount: repos.length,
          itemBuilder: (context, index) => RepoTile(repo: repos[index]),
        );
      },
    );
  }
}
