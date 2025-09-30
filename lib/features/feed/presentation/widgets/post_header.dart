import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../../../shared/widgets/custom_avatar_widget.dart';

class PostHeader extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onAuthorTapped;
  final VoidCallback? onMorePressed;

  const PostHeader({
    super.key,
    required this.post,
    this.onAuthorTapped,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Profile Picture with initials fallback
          CustomAvatarWidget.small(
            imageUrl: post.authorProfileImageUrl,
            displayName: post.authorDisplayName,
            username: post.authorUsername,
            onTap: onAuthorTapped,
          ),

          const SizedBox(width: 12),

          // Author Info
          Expanded(
            child: GestureDetector(
              onTap: onAuthorTapped,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Username
                      Text(
                        post.authorUsername,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      // Verification badge
                      if (post.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),

                  // Location (if available)
                  if (post.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      post.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // More options button - Disabled for now
          // TODO: Implement post options menu (edit, delete, report, share, etc.)
          // IconButton(
          //   icon: Icon(
          //     Icons.more_vert,
          //     color: theme.colorScheme.onSurface,
          //     size: 20,
          //   ),
          //   onPressed: onMorePressed ?? () {
          //     // Show post options menu
          //   },
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(
          //     minWidth: 24,
          //     minHeight: 24,
          //   ),
          // ),
        ],
      ),
    );
  }
}
