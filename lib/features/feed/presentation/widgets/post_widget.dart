import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import '../../data/models/post_model.dart';
import 'post_header.dart';
import 'post_actions.dart';
import 'post_caption.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/widgets/video_player_widget.dart';

class PostWidget extends StatefulWidget {
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
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with AutomaticKeepAliveClientMixin {
  bool _isZooming = false;
  
  @override
  bool get wantKeepAlive => widget.post.isVideo; // Keep video posts alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isLiked = widget.currentUserId != null && widget.post.hasLikeFrom(widget.currentUserId!);

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
            post: widget.post,
            onAuthorTapped: widget.onAuthorTapped,
          ),

          // Post Media (Image or Video) with Hero animation
          Stack(
            children: [
              Hero(
                tag: 'post_media_${widget.post.id}',
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    minHeight: 200,
                  ),
                  child: widget.post.isVideo
                      ? _buildVideoPlayer()
                      : _buildImageViewer(theme),
                ),
              ),
              
              // Zoom indicator (for images only)
              if (_isZooming && widget.post.isImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zooming',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Post Actions (like, comment, share)
          PostActions(
            post: widget.post,
            isLiked: isLiked,
            onLikePressed: widget.onLikePressed,
            onCommentPressed: widget.onCommentPressed,
          ),

          // Post Caption and Metadata
          PostCaption(
            post: widget.post,
            onAuthorTapped: widget.onAuthorTapped,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return VideoPlayerWidget(
      videoUrl: widget.post.videoUrl,
      autoPlay: false, // Don't auto-play in feed
      muted: true, // Start muted for better UX
      showControls: true, // Show controls for better UX
      onTap: () {
        // Haptic feedback is handled in the OptimizedVideoPlayer
      },
      onFullscreen: () {
        HapticService.navigation();
        widget.onImageTapped?.call(); // Use same callback for fullscreen
      },
    );
  }

  Widget _buildImageViewer(ThemeData theme) {
    return PinchZoom(
      maxScale: 3.0,
      zoomEnabled: true,
      onZoomStart: () {
        setState(() {
          _isZooming = true;
        });
        HapticService.lightImpact();
        print('🔍 Smooth zoom started');
      },
      onZoomEnd: () {
        setState(() {
          _isZooming = false;
        });
        print('🔍 Smooth zoom ended, returning to original size');
      },
      child: GestureDetector(
        onTap: () {
          HapticService.navigation();
          widget.onImageTapped?.call();
        },
        child: CachedNetworkImage(
          imageUrl: widget.post.mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
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
    );
  }
}
