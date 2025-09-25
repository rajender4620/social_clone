import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comment_model.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';

class CommentWidget extends StatefulWidget {
  final CommentModel comment;
  final String currentUserId;
  final VoidCallback onLikePressed;
  final VoidCallback onAuthorTapped;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onLikePressed,
    required this.onAuthorTapped,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget>
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
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _onLikePressed() {
    final isLiked = widget.comment.hasLikeFrom(widget.currentUserId);
    
    // Add haptic feedback
    if (isLiked) {
      HapticService.unlike();
    } else {
      HapticService.like();
    }
    
    widget.onLikePressed();
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked = widget.comment.hasLikeFrom(widget.currentUserId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          GestureDetector(
            onTap: widget.onAuthorTapped,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: widget.comment.authorProfileImageUrl != null
                  ? CachedNetworkImageProvider(widget.comment.authorProfileImageUrl!)
                  : null,
              child: widget.comment.authorProfileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and content
                RichText(
                  text: TextSpan(
                    children: [
                      // Author name
                      TextSpan(
                        text: widget.comment.authorUsername,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      
                      // Verification badge
                      if (widget.comment.isVerified)
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
                      
                      // Comment content
                      TextSpan(
                        text: ' ${widget.comment.content}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Time and actions row
                Row(
                  children: [
                    // Time ago
                    Text(
                      _getTimeAgo(widget.comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Likes count (if any)
                    if (widget.comment.likesCount > 0) ...[
                      Text(
                        '${widget.comment.likesCount} ${widget.comment.likesCount == 1 ? 'like' : 'likes'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Reply button (placeholder for future feature)
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement reply functionality
                        context.showInfoSnackbar(
                          'Replies coming soon! 💬',
                        );
                      },
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Like button
          GestureDetector(
            onTap: _onLikePressed,
            child: AnimatedBuilder(
              animation: _likeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likeAnimation.value,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isLiked
                        ? Colors.red
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      // More than a week ago, show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
