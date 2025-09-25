import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';
import '../bloc/bookmark_bloc.dart';
import '../bloc/bookmark_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';

class PostActions extends StatefulWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;

  const PostActions({
    super.key,
    required this.post,
    required this.isLiked,
    this.onLikePressed,
    this.onCommentPressed,
  });

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Check initial bookmark status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBookmarkStatus();
    });
  }

  @override
  void didUpdateWidget(PostActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) return;

    try {
      final feedRepository = context.read<FeedRepository>();
      final isBookmarked = await feedRepository.isPostBookmarked(
        postId: widget.post.id,
        userId: authState.user.uid,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      // Handle error silently for bookmark status
    }
  }

  Future<void> _toggleBookmark() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated || _isLoadingBookmark)
      return;

    setState(() {
      _isLoadingBookmark = true;
    });

    try {
      final feedRepository = context.read<FeedRepository>();
      final isBookmarked = await feedRepository.togglePostBookmark(
        postId: widget.post.id,
        userId: authState.user.uid,
      );

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
          _isLoadingBookmark = false;
        });

        // Add haptic feedback
        if (isBookmarked) {
          HapticService.buttonPress();
          SnackbarService.showSuccess(context, 'Post saved to your collection');
        } else {
          HapticService.buttonPress();
          SnackbarService.showInfo(context, 'Post removed from saved');
        }

        // Notify bookmark bloc if available
        try {
          context.read<BookmarkBloc>().add(
            BookmarkToggleRequested(
              postId: widget.post.id,
              userId: authState.user.uid,
            ),
          );
        } catch (e) {
          // BookmarkBloc might not be available in all contexts
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() {
          _isLoadingBookmark = false;
        });
        SnackbarService.showError(context, 'Failed to update bookmark');
      }
    }
  }

  Future<void> _sharePost() async {
    try {
      HapticService.buttonPress();

      // Create share content
      final shareText = _buildShareText();
      final shareUrl = _buildPostUrl();

      // Show share dialog with copy option
      await _showShareDialog(shareText, shareUrl);
    } catch (e) {
      debugPrint(e.toString());
      SnackbarService.showError(context, 'Failed to share post');
    }
  }

  String _buildShareText() {
    final author = widget.post.displayAuthorName;
    final caption =
        widget.post.caption.isNotEmpty
            ? widget.post.caption
            : 'Check out this post';

    return 'Check out this post by $author on PumpkinSocial!\n\n$caption';
  }

  String _buildPostUrl() {
    // In a real app, this would be your actual domain
    return 'https://pumpkinsocial.app/post/${widget.post.id}';
  }

  Future<void> _showShareDialog(String shareText, String shareUrl) async {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Container(
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

              // Title
              Text(
                'Share Post',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Share options
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via...'),
                subtitle: const Text('Open native share dialog'),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.share(
                    '$shareText\n\n$shareUrl',
                    subject: 'Check out this post on PumpkinSocial',
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                subtitle: const Text('Copy post URL to clipboard'),
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: shareUrl));
                  if (mounted) {
                    SnackbarService.showSuccess(
                      context,
                      'Link copied to clipboard',
                    );
                  }
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            children: [
              // Like button
              AnimatedBuilder(
                animation: _likeAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _likeAnimation.value,
                    child: IconButton(
                      icon: Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        color:
                            widget.isLiked
                                ? Colors.red
                                : theme.colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed: () {
                        // Add haptic feedback
                        if (widget.isLiked) {
                          HapticService.unlike();
                        } else {
                          HapticService.like();
                        }

                        // Call the original callback
                        widget.onLikePressed?.call();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  );
                },
              ),

              // Comment button
              IconButton(
                icon: Icon(
                  Icons.mode_comment_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  HapticService.buttonPress();
                  widget.onCommentPressed?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),

              // Share button
              IconButton(
                icon: Icon(
                  Icons.send_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _sharePost,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),

              const Spacer(),

              // Bookmark button
              IconButton(
                icon:
                    _isLoadingBookmark
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                        : Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                onPressed: _isLoadingBookmark ? null : _toggleBookmark,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),

          // Likes count
          if (widget.post.likesCount > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                // TODO: Show likes list
              },
              child: Text(
                _getLikesText(widget.post.likesCount),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLikesText(int likesCount) {
    if (likesCount == 1) {
      return '1 like';
    } else if (likesCount < 1000) {
      return '$likesCount likes';
    } else if (likesCount < 1000000) {
      final k = (likesCount / 1000).toStringAsFixed(1);
      return '${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}K likes';
    } else {
      final m = (likesCount / 1000000).toStringAsFixed(1);
      return '${m.endsWith('.0') ? m.substring(0, m.length - 2) : m}M likes';
    }
  }
}
