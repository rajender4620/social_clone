import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';
import '../widgets/comment_widget.dart';
import '../widgets/comment_input_widget.dart';
import '../../data/models/post_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/services/snackbar_service.dart';
import '../../../../shared/widgets/custom_refresh_indicator.dart';
import '../../../../shared/widgets/animated_list_item.dart';
import '../../../../shared/widgets/custom_avatar_widget.dart';

class CommentsPage extends StatefulWidget {
  final PostModel post;

  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CommentsBloc>().add(
        CommentsLoadMoreRequested(postId: widget.post.id),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<CommentsBloc>().add(
      CommentsRefreshRequested(postId: widget.post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => CommentsBloc(
        feedRepository: context.read(),
        authBloc: context.read<AuthBloc>(),
        postId: widget.post.id,
      )..add(CommentsLoadRequested(postId: widget.post.id)),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Comments'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            // Post preview (optional - shows which post we're commenting on)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Post author avatar with initials fallback
                  CustomAvatarWidget.small(
                    imageUrl: widget.post.authorProfileImageUrl,
                    displayName: widget.post.authorDisplayName,
                    username: widget.post.authorUsername,
                  ),
                  const SizedBox(width: 12),
                  
                  // Post info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post.authorUsername,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.post.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (widget.post.caption.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.post.caption,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Comments list
            Expanded(
              child: BlocConsumer<CommentsBloc, CommentsState>(
                listener: (context, state) {
                  if (state.hasError) {
                    context.showErrorSnackbar(
                      state.errorMessage ?? 'Failed to load comments',
                      actionLabel: 'Dismiss',
                      onActionPressed: () {
                        context.read<CommentsBloc>().add(const CommentsErrorCleared());
                      },
                    );
                  }
                },
                builder: (context, state) {
                  return _buildCommentsContent(state, theme);
                },
              ),
            ),

            // Comment input
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState.status != AuthStatus.authenticated) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Sign in to comment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return BlocBuilder<CommentsBloc, CommentsState>(
                  builder: (context, commentsState) {
                    return CommentInputWidget(
                      isSubmitting: commentsState.isSubmitting,
                      onCommentSubmitted: (content) {
                        context.read<CommentsBloc>().add(
                          CommentAdded(
                            postId: widget.post.id,
                            content: content,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsContent(CommentsState state, ThemeData theme) {
    switch (state.status) {
      case CommentsStatus.initial:
      case CommentsStatus.loading:
        return const CommentsSkeleton(itemCount: 6);

      case CommentsStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Failed to load comments',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<CommentsBloc>().add(
                    CommentsLoadRequested(postId: widget.post.id),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case CommentsStatus.loaded:
      case CommentsStatus.loadingMore:
      case CommentsStatus.refreshing:
      case CommentsStatus.submitting:
        if (state.comments.isEmpty) {
          return _buildEmptyComments(theme);
        }

        return PumpkinRefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            itemCount: state.comments.length + 
                (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                return _buildLoadingIndicator(theme);
              }

              final comment = state.comments[index];
              return AnimatedCommentItem(
                index: index,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    return CommentWidget(
                      comment: comment,
                      currentUserId: authState.user.uid,
                      onLikePressed: () {
                        context.read<CommentsBloc>().add(
                          CommentLikeToggled(
                            postId: widget.post.id,
                            commentId: comment.id,
                            userId: authState.user.uid,
                          ),
                        );
                      },
                      onAuthorTapped: () {
                        context.push('/profile/${comment.authorId}');
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildEmptyComments(ThemeData theme) {
    return PumpkinRefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.mode_comment_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No comments yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Be the first to comment on this post!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
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
