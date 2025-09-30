import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../widgets/comment_widget.dart';
import '../widgets/comment_input_widget.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_header.dart';
import '../../data/models/post_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/services/snackbar_service.dart';
import '../../../../shared/widgets/custom_refresh_indicator.dart';
import '../../../../shared/widgets/animated_list_item.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _imageAnimationController;
  late Animation<double> _imageAnimation;
  bool _showImageFullscreen = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _imageAnimation = CurvedAnimation(
      parent: _imageAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imageAnimationController.dispose();
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

  void _toggleImageFullscreen() {
    setState(() {
      _showImageFullscreen = !_showImageFullscreen;
    });

    if (_showImageFullscreen) {
      _imageAnimationController.forward();
    } else {
      _imageAnimationController.reverse();
    }
  }

  Future<void> _onRefreshComments() async {
    context.read<CommentsBloc>().add(
      CommentsRefreshRequested(postId: widget.post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create:
          (context) => CommentsBloc(
            feedRepository: context.read(),
            authBloc: context.read<AuthBloc>(),
            postId: widget.post.id,
          )..add(CommentsLoadRequested(postId: widget.post.id)),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _showImageFullscreen ? null : _buildAppBar(theme),
        body: Stack(
          children: [
            // Main content
            if (!_showImageFullscreen) _buildMainContent(theme),

            // Fullscreen image overlay
            if (_showImageFullscreen) _buildFullscreenImage(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        '@${widget.post.authorUsername}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPostOptions(context),
        ),
      ],
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return BlocConsumer<CommentsBloc, CommentsState>(
      listener: (context, state) {
        if (state.hasError) {
          context.showErrorSnackbar(
            state.errorMessage ?? 'Failed to load comments',
            actionLabel: 'Dismiss',
            onActionPressed: () {
              context.read<CommentsBloc>().add(
                const CommentsErrorCleared(),
              );
            },
          );
        }
      },
      builder: (context, commentsState) {
        return Column(
          children: [
            // Scrollable content area
            Expanded(
              child: PumpkinRefreshIndicator(
                onRefresh: _onRefreshComments,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Post content
                    SliverToBoxAdapter(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post header
                          PostHeader(
                            post: widget.post,
                            onAuthorTapped: () {
                              context.push('/profile/${widget.post.authorId}');
                            },
                            onMorePressed: () => _showPostOptions(context),
                          ),

                          // Post image with tap to zoom
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Hero(
                              tag: 'post_image_${widget.post.id}',
                              child: GestureDetector(
                                onTap: _toggleImageFullscreen,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.post.mediaUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: theme.colorScheme.surfaceVariant,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: theme.colorScheme.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: theme.colorScheme.surfaceVariant,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            size: 64,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Post actions and caption
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              final isLiked = widget.post.hasLikeFrom(authState.user.uid);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Post actions (like, comment, share)
                                  PostActions(
                                    post: widget.post,
                                    isLiked: isLiked,
                                    onLikePressed: () {
                                      context.read<FeedBloc>().add(
                                        PostLikeToggled(
                                          postId: widget.post.id,
                                          userId: authState.user.uid,
                                        ),
                                      );
                                    },
                                    onCommentPressed: () {
                                      // Scroll to comments section
                                      _scrollController.animateTo(
                                        600, // Adjusted scroll position
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                  ),

                                  // Post caption (without comments navigation)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildCaptionOnly(theme),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Divider before comments
                          Container(
                            height: 8,
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),

                          // Comments section header
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: theme.colorScheme.surface,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mode_comment_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Comments',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Comments list as slivers
                  _buildCommentsSlivers(commentsState, theme),
                ],
                ),
              ),
            ),

            // Fixed comment input at bottom
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState.status != AuthStatus.authenticated) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor, width: 0.5),
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

                return CommentInputWidget(
                  isSubmitting: commentsState.isSubmitting,
                  onCommentSubmitted: (content) {
                    context.read<CommentsBloc>().add(
                      CommentAdded(postId: widget.post.id, content: content),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullscreenImage(ThemeData theme) {
    return AnimatedBuilder(
      animation: _imageAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(_imageAnimation.value * 0.9),
          child: Stack(
            children: [
              // Zoomable image
              Center(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(
                    widget.post.mediaUrl,
                  ),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'post_image_${widget.post.id}',
                  ),
                  loadingBuilder:
                      (context, event) => Center(
                        child: CircularProgressIndicator(
                          value:
                              event == null
                                  ? 0
                                  : event.cumulativeBytesLoaded /
                                      (event.expectedTotalBytes ?? 1),
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),

              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _toggleImageFullscreen,
                  ),
                ),
              ),

              // Image info overlay
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@${widget.post.authorUsername}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.post.caption.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.post.caption,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptionOnly(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.post.caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.post.authorUsername,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (widget.post.isVerified)
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.verified,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                TextSpan(
                  text: ' ${widget.post.caption}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Location if available
        if (widget.post.location != null &&
            widget.post.location!.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                widget.post.location!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Timestamp
        Text(
          _getTimeAgo(widget.post.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommentsSlivers(CommentsState state, ThemeData theme) {
    switch (state.status) {
      case CommentsStatus.initial:
      case CommentsStatus.loading:
        return SliverToBoxAdapter(
          child: const CommentsSkeleton(itemCount: 5),
        );

      case CommentsStatus.error:
        return SliverFillRemaining(
          child: Center(
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
          ),
        );

      case CommentsStatus.loaded:
      case CommentsStatus.loadingMore:
      case CommentsStatus.refreshing:
      case CommentsStatus.submitting:
        if (state.comments.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyCommentsInline(theme));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
            childCount: state.comments.length + (state.isLoadingMore ? 1 : 0),
          ),
        );
    }
  }

  Widget _buildEmptyCommentsInline(ThemeData theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.mode_comment_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              subtitle: const Text('Open native share dialog'),
              onTap: () async {
                Navigator.pop(context);
                await _sharePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              subtitle: const Text('Copy post URL to clipboard'),
              onTap: () async {
                Navigator.pop(context);
                await _copyPostLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report
                context.showWarningSnackbar(
                  'Report feature coming soon! ⚠️',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePost() async {
    try {
      final shareText = _buildShareText();
      final shareUrl = _buildPostUrl();
      
      await Share.share(
        '$shareText\n\n$shareUrl',
        subject: 'Check out this post on PumpkinSocial',
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar('Failed to share post');
      }
    }
  }

  Future<void> _copyPostLink() async {
    try {
      final postUrl = _buildPostUrl();
      await Clipboard.setData(ClipboardData(text: postUrl));
      if (mounted) {
        context.showSuccessSnackbar('Link copied to clipboard');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar('Failed to copy link');
      }
    }
  }

  String _buildShareText() {
    final author = widget.post.displayAuthorName;
    final caption = widget.post.caption.isNotEmpty 
        ? widget.post.caption 
        : 'Check out this post';
    
    return 'Check out this post by $author on PumpkinSocial!\n\n$caption';
  }

  String _buildPostUrl() {
    // In a real app, this would be your actual domain
    return 'https://pumpkinsocial.app/post/${widget.post.id}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
