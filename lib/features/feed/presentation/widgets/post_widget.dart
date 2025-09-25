import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/post_model.dart';
import 'post_header.dart';
import 'post_actions.dart';
import 'post_caption.dart';
import '../../../../shared/services/haptic_service.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onAuthorTapped;
  final VoidCallback? onImageTapped;

  const PostWidget({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLikePressed,
    this.onCommentPressed,
    this.onAuthorTapped,
    this.onImageTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked = currentUserId != null && post.hasLikeFrom(currentUserId!);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header (author info)
          PostHeader(
            post: post,
            onAuthorTapped: onAuthorTapped,
          ),

          // Post Image
          GestureDetector(
            onTap: () {
              HapticService.navigation();
              onImageTapped?.call();
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxHeight: 400,
                minHeight: 200,
              ),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Post Actions (like, comment, share)
          PostActions(
            post: post,
            isLiked: isLiked,
            onLikePressed: onLikePressed,
            onCommentPressed: onCommentPressed,
          ),

          // Post Caption and Metadata
          PostCaption(
            post: post,
            onAuthorTapped: onAuthorTapped,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
