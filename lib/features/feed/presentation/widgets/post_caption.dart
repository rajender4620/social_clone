import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/post_model.dart';

class PostCaption extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onAuthorTapped;

  const PostCaption({
    super.key,
    required this.post,
    this.onAuthorTapped,
  });

  @override
  State<PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<PostCaption> {
  bool _isExpanded = false;
  final int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = widget.post.caption;
    final hasLongCaption = caption.length > 100; // Rough estimate

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption text
          if (caption.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                children: [
                  // Username
                  TextSpan(
                    text: '${widget.post.authorUsername} ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Caption content
                  TextSpan(
                    text: caption,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              maxLines: _isExpanded ? null : _maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),

            // "More" button for long captions
            if (hasLongCaption && !_isExpanded) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                child: Text(
                  'more',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],

          // Comments section
          GestureDetector(
            onTap: () {
              context.push('/comments/${widget.post.id}', extra: widget.post);
            },
            child: widget.post.commentsCount > 0 
                ? Text(
                    _getCommentsText(widget.post.commentsCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  )
                : Text(
                    'Add a comment...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
          ),
          const SizedBox(height: 8),

          // Timestamp
          Text(
            _getTimeAgo(widget.post.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getCommentsText(int commentsCount) {
    if (commentsCount == 1) {
      return 'View 1 comment';
    } else {
      return 'View all $commentsCount comments';
    }
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
