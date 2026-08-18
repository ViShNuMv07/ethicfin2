import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recent_searches_provider.dart';
import '../providers/request_state.dart';
import '../providers/user_search_provider.dart';
import '../utils/responsive.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/user_profile_card.dart';
import 'repositories_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String username) async {
    FocusScope.of(context).unfocus();
    final searchProvider = context.read<UserSearchProvider>();
    final recentProvider = context.read<RecentSearchesProvider>();
    await searchProvider.search(username);
    await recentProvider.refresh();
  }

  void _searchFor(String username) {
    _controller.text = username;
    _runSearch(username);
  }

  void _onQueryChanged(String value) {
    if (value.trim().isEmpty) {
      context.read<UserSearchProvider>().reset();
    }
  }

  void _clearField() {
    _controller.clear();
    context.read<UserSearchProvider>().reset();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Search')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hPad = responsiveHorizontalPadding(constraints.maxWidth);
                final isWide = deviceTypeOf(context) != DeviceType.mobile;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          final hasText = value.text.isNotEmpty;
                          return TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) => _runSearch(value),
                            onChanged: _onQueryChanged,
                            decoration: InputDecoration(
                              hintText: 'Enter GitHub username',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasText)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _clearField,
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () => _runSearch(_controller.text),
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<UserSearchProvider>(
                        builder: (context, provider, _) {
                          switch (provider.state) {
                            case RequestState.loading:
                              return const LoadingView();
                            case RequestState.error:
                              return ErrorView(
                                message: provider.errorMessage,
                                onRetry: () => _runSearch(provider.lastQuery),
                              );
                            case RequestState.success:
                              final user = provider.user!;
                              return SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? hPad - 16 : 0,
                                ),
                                child: UserProfileCard(
                                  user: user,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RepositoriesScreen(
                                        username: user.login,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            case RequestState.idle:
                              return _RecentSearchesList(
                                onTap: _searchFor,
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

class _RecentSearchesList extends StatelessWidget {
  final ValueChanged<String> onTap;
  final double horizontalPadding;

  const _RecentSearchesList({
    required this.onTap,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecentSearchesProvider>(
      builder: (context, provider, _) {
        if (!provider.loaded) return const SizedBox.shrink();

        if (provider.searches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Search for a GitHub username to get started',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Recent searches',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.searches
                    .map(
                      (username) => ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(username),
                    onPressed: () => onTap(username),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}