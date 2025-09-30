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
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/widgets/custom_refresh_indicator.dart';
import '../../../../shared/widgets/animated_list_item.dart';
import '../../../../shared/widgets/fullscreen_media_viewer.dart';
import '../../../../shared/widgets/pumpkin_icon.dart';

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
    HapticService.refresh();
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
            const PumpkinIcon.small(),
            const SizedBox(width: 8),
            Text(
              'Pumpkin',
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
          // IconButton(
          //   icon: const Icon(Icons.favorite_border),
          //   onPressed: () {
          //     // TODO: Navigate to activity/notifications
          //   },
          // ),
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

        return PumpkinRefreshIndicator(
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
              return AnimatedPostItem(
                index: index,
                child: PostWidget(
                  post: post,
                  currentUserId: currentUserId,
                  onLikePressed: () {
                    context.read<FeedBloc>().add(
                      PostLikeToggled(postId: post.id, userId: currentUserId),
                    );
                  },
                  onCommentPressed: () {
                    context.push('/comments/${post.id}', extra: post);
                  },
                  onAuthorTapped: () {
                    context.push('/profile/${post.authorId}');
                  },
                  onImageTapped: () {
                    post.showFullscreen(context);
                  },
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildEmptyFeed() {
    final theme = Theme.of(context);

    return PumpkinRefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PumpkinIcon.large(showShadow: true),
              const SizedBox(height: 24),
              Text(
                'Welcome to Pumpkin!',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const PostSkeleton(),
    );
  }
}
