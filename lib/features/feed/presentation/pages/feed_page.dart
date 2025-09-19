import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/post_widget.dart';
import '../widgets/feed_loading_widget.dart';
import '../widgets/feed_error_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Load initial feed
    context.read<FeedBloc>().add(const FeedLoadRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<FeedBloc>().add(const FeedLoadMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<FeedBloc>().add(const FeedRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PumpkinSocial',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              context.push('/create-post');
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Navigate to activity/notifications
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  if (authState.status == AuthStatus.authenticated) {
                    context.push('/profile/${authState.user.uid}');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, feedState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState.status != AuthStatus.authenticated) {
                return const Center(child: CircularProgressIndicator());
              }

              return _buildFeedContent(feedState, authState.user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedContent(FeedState state, String currentUserId) {
    switch (state.status) {
      case FeedStatus.initial:
      case FeedStatus.loading:
        return const FeedLoadingWidget();

      case FeedStatus.error:
        print(state.errorMessage);
        return FeedErrorWidget(
          message: state.errorMessage ?? 'An error occurred',
          onRetry: () {
            context.read<FeedBloc>().add(const FeedLoadRequested());
          },
        );

      case FeedStatus.loaded:
      case FeedStatus.loadingMore:
      case FeedStatus.refreshing:
        if (state.posts.isEmpty) {
          return _buildEmptyFeed();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                state.posts.length +
                (state.status == FeedStatus.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.posts.length) {
                return _buildLoadingIndicator();
              }

              final post = state.posts[index];
              return PostWidget(
                post: post,
                currentUserId: currentUserId,
                onLikePressed: () {
                  context.read<FeedBloc>().add(
                    PostLikeToggled(postId: post.id, userId: currentUserId),
                  );
                },
                onCommentPressed: () {
                  // TODO: Navigate to comments
                },
                onSharePressed: () {
                  // TODO: Implement share functionality
                },
                onAuthorTapped: () {
                  context.push('/profile/${post.authorId}');
                },
                onImageTapped: () {
                  // TODO: Navigate to post detail
                },
              );
            },
          ),
        );
    }
  }

  Widget _buildEmptyFeed() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to PumpkinSocial!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Start by following some users or create your first post to see content in your feed.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/create-post');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Post'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
