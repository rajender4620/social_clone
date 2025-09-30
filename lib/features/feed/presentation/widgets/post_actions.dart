import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';
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

  // Throttling and debouncing variables
  Timer? _debounceTimer;
  DateTime? _lastBookmarkTap;
  static const Duration _minTapInterval = Duration(
    milliseconds: 500,
  ); // Min 500ms between taps
  static const Duration _debounceDelay = Duration(
    milliseconds: 300,
  ); // 300ms debounce

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) {
      debugPrint('❌ User not authenticated, skipping bookmark check');
      return;
    }

    try {
      debugPrint(
        '🔍 Checking bookmark status for post: ${widget.post.id}, user: ${authState.user.uid}',
      );
      final feedRepository = context.read<FeedRepository>();
      final isBookmarked = await feedRepository.isPostBookmarked(
        postId: widget.post.id,
        userId: authState.user.uid,
      );
      debugPrint('📌 Initial bookmark status: $isBookmarked');

      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      // Handle error silently for bookmark status
      debugPrint('❌ Error checking bookmark status: $e');
    }
  }

  // Throttled bookmark toggle handler - prevents rapid multiple taps
  void _onBookmarkTapped() {
    final now = DateTime.now();

    // Check if we're within the minimum tap interval
    if (_lastBookmarkTap != null &&
        now.difference(_lastBookmarkTap!) < _minTapInterval) {
      debugPrint(
        '⏸️ Bookmark tap throttled - too fast! Time since last: ${now.difference(_lastBookmarkTap!).inMilliseconds}ms',
      );

      // Give subtle feedback that tap was registered but ignored
      HapticService.lightImpact();
      return;
    }

    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Set up new debounce timer
    _debounceTimer = Timer(_debounceDelay, () {
      _toggleBookmark();
    });

    debugPrint(
      '⏳ Bookmark tap registered - debouncing for ${_debounceDelay.inMilliseconds}ms',
    );
  }

  Future<void> _toggleBookmark() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated || _isLoadingBookmark) {
      debugPrint(
        '⏸️ Bookmark toggle blocked: auth=${authState.status}, loading=$_isLoadingBookmark',
      );
      return;
    }

    // Update last tap time to start cooldown period
    _lastBookmarkTap = DateTime.now();

    // Optimistic update - immediately toggle UI for better responsiveness
    final optimisticState = !_isBookmarked;
    setState(() {
      _isBookmarked = optimisticState;
      _isLoadingBookmark = true;
    });

    try {
      debugPrint(
        '🔄 Toggling bookmark for post: ${widget.post.id}, user: ${authState.user.uid}',
      );
      final feedRepository = context.read<FeedRepository>();
      final actualBookmarkState = await feedRepository.togglePostBookmark(
        postId: widget.post.id,
        userId: authState.user.uid,
      );
      debugPrint('✅ Bookmark toggle result: $actualBookmarkState');

      if (mounted) {
        setState(() {
          _isBookmarked = actualBookmarkState; // Update with real server state
          _isLoadingBookmark = false;
        });

        // Add haptic feedback
        if (actualBookmarkState) {
          HapticService.buttonPress();
          SnackbarService.showSuccess(context, 'Post saved to your collection');
        } else {
          HapticService.buttonPress();
          SnackbarService.showInfo(context, 'Post removed from saved');
        }

        // Note: Removed BookmarkBloc notification to prevent double-triggering
        // The bookmark state is managed directly in this widget
      }
    } catch (e) {
      debugPrint('❌ Failed to toggle bookmark: $e');
      if (mounted) {
        // Revert optimistic update on error
        setState(() {
          _isBookmarked = !optimisticState; // Revert to previous state
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
              // IconButton(
              //   icon: Icon(
              //     Icons.send_outlined,
              //     color: theme.colorScheme.onSurface,
              //     size: 24,
              //   ),
              //   onPressed: _sharePost,
              //   padding: EdgeInsets.zero,
              //   constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              // ),
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
                onPressed: _isLoadingBookmark ? null : _onBookmarkTapped,
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
