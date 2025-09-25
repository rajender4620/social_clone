import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/bookmark_bloc.dart';
import '../bloc/bookmark_event.dart';
import '../bloc/bookmark_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/widgets/profile_posts_grid.dart';
import '../../../../shared/widgets/custom_refresh_indicator.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  @override
  void initState() {
    super.initState();
    // Load saved posts when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated) {
        context.read<BookmarkBloc>().add(
          BookmarkLoadRequested(userId: authState.user.uid),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<BookmarkBloc, BookmarkState>(
            builder: (context, bookmarkState) {
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<BookmarkBloc>().add(
                    BookmarkRefreshRequested(userId: authState.user.uid),
                  );
                },
                child: CustomScrollView(
                  slivers: [
                    // Info header
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Only you can see what you\'ve saved',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Posts grid
                    _buildBookmarkContent(bookmarkState, authState.user.uid),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookmarkContent(BookmarkState state, String currentUserId) {
    switch (state.status) {
      case BookmarkStatus.initial:
      case BookmarkStatus.loading:
        if (state.posts.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        break;

      case BookmarkStatus.error:
        if (state.posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Failed to load saved posts',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BookmarkBloc>().add(
                        BookmarkLoadRequested(userId: currentUserId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        break;

      case BookmarkStatus.loaded:
        break;
    }

    if (state.posts.isEmpty && state.status == BookmarkStatus.loaded) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Saved Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Save posts to view them here later.',
                style: TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ProfilePostsGrid(
      posts: state.posts,
      isLoading: state.isLoadingMore,
      hasError: state.status == BookmarkStatus.error,
      errorMessage: state.errorMessage,
      hasMorePosts: state.hasMore,
      onLoadMore: () {
        context.read<BookmarkBloc>().add(
          BookmarkLoadMoreRequested(userId: currentUserId),
        );
      },
      onPostTapped: (post) {
        context.push('/post/${post.id}', extra: post);
      },
    );
  }
}
