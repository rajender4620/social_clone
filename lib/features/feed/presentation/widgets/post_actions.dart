import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';

class PostActions extends StatefulWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;

  const PostActions({
    super.key,
    required this.post,
    required this.isLiked,
    this.onLikePressed,
    this.onCommentPressed,
    this.onSharePressed,
  });

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
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
                        widget.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isLiked
                            ? Colors.red
                            : theme.colorScheme.onSurface,
                        size: 24,
                      ),
                      onPressed: widget.onLikePressed,
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
                onPressed: widget.onCommentPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),

              // Share button
              IconButton(
                icon: Icon(
                  Icons.send_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: widget.onSharePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),

              const Spacer(),

              // Bookmark button (future feature)
              IconButton(
                icon: Icon(
                  Icons.bookmark_border,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  // TODO: Implement bookmark functionality
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
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
