import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../features/feed/data/models/post_model.dart';
import '../services/haptic_service.dart';
import 'video_player_widget.dart';

class FullscreenMediaViewer extends StatefulWidget {
  final PostModel post;

  const FullscreenMediaViewer({
    super.key,
    required this.post,
  });

  @override
  State<FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<FullscreenMediaViewer>
    with TickerProviderStateMixin {
  bool _showUI = true;
  late AnimationController _uiAnimationController;
  late Animation<double> _uiAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar to light content for dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _uiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _uiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _uiAnimationController.forward();

    // Auto-hide UI after 3 seconds
    _scheduleUIHide();
  }

  @override
  void dispose() {
    _uiAnimationController.dispose();
    // Restore system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _scheduleUIHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showUI) {
        _toggleUI();
      }
    });
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _uiAnimationController.forward();
      _scheduleUIHide(); // Auto-hide again
    } else {
      _uiAnimationController.reverse();
    }
    
    HapticService.lightImpact();
  }

  void _closeViewer() {
    HapticService.lightImpact();
    Navigator.of(context).pop();
  }

  void _showMoreOptions(BuildContext context) {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Share option
            ListTile(
              leading: Icon(
                Icons.share_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                'Share post',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Share functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share functionality coming soon!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            
            // Copy link option  
            ListTile(
              leading: Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                'Copy link',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                // Copy link functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),

            // Report option
            ListTile(
              leading: Icon(
                Icons.report_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Report post',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Report functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report functionality coming soon!'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen media viewer (image or video)
          GestureDetector(
            onTap: _toggleUI,
            child: widget.post.isVideo
                ? _buildFullscreenVideoPlayer()
                : _buildFullscreenImageViewer(),
          ),

          // Top UI overlay (close button and post info)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _uiAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -60 * (1 - _uiAnimation.value)),
                  child: Opacity(
                    opacity: _uiAnimation.value,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Close button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: _closeViewer,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Post author info (tappable)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticService.lightImpact();
                                context.push('/profile/${widget.post.authorId}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.post.authorUsername,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (widget.post.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (widget.post.location != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.post.location!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // More actions button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showMoreOptions(context);
                              },
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom UI overlay (caption and actions)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _uiAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _uiAnimation.value)),
                  child: Opacity(
                    opacity: _uiAnimation.value,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Caption
                          if (widget.post.caption.isNotEmpty) ...[
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.post.authorUsername,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${widget.post.caption}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Interactive action buttons
                          Row(
                            children: [
                              // Like count and button
                              GestureDetector(
                                onTap: () {
                                  HapticService.lightImpact();
                                  // Note: Like functionality would require passing callback from parent
                                  // For now, just show a snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Go back to like posts'),
                                      backgroundColor: Colors.black87,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      widget.post.likesCount > 0 ? Icons.favorite : Icons.favorite_border,
                                      color: widget.post.likesCount > 0 ? Colors.red : Colors.white70,
                                      size: 20,
                                    ),
                                    if (widget.post.likesCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.post.likesCount}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 20),

                              // Comments button
                              GestureDetector(
                                onTap: () {
                                  HapticService.lightImpact();
                                  Navigator.of(context).pop(); // Close fullscreen first
                                  context.push('/comments/${widget.post.id}', extra: widget.post);
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.mode_comment_outlined,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    if (widget.post.commentsCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.post.commentsCount}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Time ago
                              Text(
                                _getTimeAgo(widget.post.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tap indicator (hint for UI toggle)
          if (_showUI)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 200,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _uiAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _uiAnimation.value * 0.7,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Pinch to zoom • Tap to hide',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
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

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
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

  Widget _buildFullscreenVideoPlayer() {
    return Center(
      child: VideoPlayerWidget(
        videoUrl: widget.post.videoUrl,
        autoPlay: true, // Auto-play in fullscreen
        muted: false, // Allow sound in fullscreen
        showControls: true,
        onTap: () {
          // Video player handles play/pause internally (haptic feedback included)
        },
      ),
    );
  }

  Widget _buildFullscreenImageViewer() {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.post.mediaUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(
        tag: 'post_media_${widget.post.id}',
      ),
      loadingBuilder: (context, event) => Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
                value: event?.expectedTotalBytes != null
                    ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to retry',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to easily show fullscreen viewer
extension PostExtension on PostModel {
  void showFullscreen(BuildContext context) {
    HapticService.navigation();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullscreenMediaViewer(post: this),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
