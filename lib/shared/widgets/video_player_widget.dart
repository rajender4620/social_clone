import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final bool muted;
  final VoidCallback? onTap;
  final VoidCallback? onFullscreen;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.aspectRatio,
    this.autoPlay = false,
    this.showControls = true,
    this.muted = true,
    this.onTap,
    this.onFullscreen,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if it's a local file path or network URL
      if (widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        // Local file path
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Set volume based on muted preference
        _controller.setVolume(widget.muted ? 0.0 : 1.0);

        // Auto play if requested
        if (widget.autoPlay) {
          _playPause();
        }

        // Listen for video completion
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      print('❌ Video initialization failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  void _playPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 3 seconds
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onVideoTap() {
    if (widget.showControls) {
      // If video is paused, play it immediately, otherwise toggle controls
      if (!_isPlaying) {
        _playPause();
      } else {
        _toggleControls();
      }
    } else {
      _playPause();
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasError) {
      return _buildErrorWidget(theme);
    }

    if (!_isInitialized) {
      return _buildLoadingWidget(theme);
    }

    return GestureDetector(
      onTap: _onVideoTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: widget.aspectRatio ?? _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),

          // Play/pause button overlay
          if (!widget.showControls || !_isPlaying || _showControls)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                onPressed: _playPause,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),

          // Controls overlay
          if (widget.showControls && _showControls)
            _buildControlsOverlay(theme),

          // Volume indicator when muted
          if (widget.muted && _isPlaying)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_off,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

          // Video indicator (when paused)
          if (!_isPlaying)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_controller.value.duration),
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

          // Fullscreen button
          if (widget.onFullscreen != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: widget.onFullscreen,
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Container(
      height: 200,
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading video...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Container(
      height: 200,
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load video',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to retry',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            // Progress bar
            Expanded(
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white10,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            
            // Duration text
            Text(
              '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
