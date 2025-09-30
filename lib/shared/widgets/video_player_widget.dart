import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_controller_manager.dart';
import '../services/haptic_service.dart';

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

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = false;
  bool _hasError = false;
  bool _disposed = false;

  final VideoControllerManager _controllerManager = VideoControllerManager();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _releaseController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !mounted) return;
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause video when app goes to background
        if (_controller != null && _controller!.value.isPlaying) {
          try {
            _controller!.pause();
          } catch (e) {
            print('⚠️ Error pausing video on app pause: $e');
          }
        }
        break;
      case AppLifecycleState.resumed:
        // Check if controller needs reinitializing after app resume
        _checkAndReinitializeAfterResume();
        break;
      case AppLifecycleState.detached:
        // App is being destroyed
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  Future<void> _initializeVideo() async {
    if (_disposed) return;
    
    try {
      _controller = await _controllerManager.getController(widget.videoUrl);
      
      if (_disposed || _controller == null) return;

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Set volume based on muted preference
        _controller!.setVolume(widget.muted ? 0.0 : 1.0);

        // Auto play if requested
        if (widget.autoPlay) {
          _playPause();
        }

        // Listen for video state changes
        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      print('❌ Video initialization failed: $e');
      if (mounted && !_disposed) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _reinitializeVideo() async {
    if (_disposed) return;
    
    print('🔄 Reinitializing video after app resume');
    
    // Reset state
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });
    
    // Clear the current controller to force fresh surface connection
    if (_controller != null) {
      _controllerManager.releaseController(widget.videoUrl);
      _controller = null;
    }
    
    // Force refresh the controller from manager to clear stale surfaces
    await _controllerManager.refreshController(widget.videoUrl);
    
    // Longer delay to ensure surface is completely ready and stale buffers are cleared
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Reinitialize the video
    await _initializeVideo();
  }

  Future<void> _checkAndReinitializeAfterResume() async {
    if (_disposed || !mounted) return;
    
    // Add a small delay to avoid immediate conflicts with other lifecycle events
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_disposed || !mounted) return;
    
    bool needsReinitializing = false;
    
    if (_controller == null) {
      needsReinitializing = true;
    } else {
      // Check if controller is in a bad state after app resume
      try {
        // Try to access controller value - this will throw if disposed
        final isInitialized = _controller!.value.isInitialized;
        if (!isInitialized || _hasError) {
          needsReinitializing = true;
        }
      } catch (e) {
        // Controller is in bad state, needs reinitializing
        needsReinitializing = true;
        print('🔄 Controller in bad state after resume: $e');
      }
    }
    
    if (needsReinitializing) {
      print('🔄 Reinitializing video controller after app resume');
      await _reinitializeVideo();
    }
  }

  void _releaseController() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controllerManager.releaseController(widget.videoUrl);
      _controller = null;
    }
  }

  void _videoListener() {
    if (_disposed || !mounted || _controller == null) return;
    
    try {
      // Check if controller is still valid and initialized
      if (!_controller!.value.isInitialized) return;
      
      if (_controller!.value.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    } catch (e) {
      // Controller was disposed during access - ignore silently
      print('⚠️ Video listener accessing disposed controller: $e');
    }
  }

  void _playPause() {
    if (_controller == null || _disposed || !mounted) return;
    
    try {
      if (!_controller!.value.isInitialized) return;
      
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        // Pause all other videos first
        _controllerManager.pauseAll();
        _controller!.play();
      }
      HapticService.lightImpact();
    } catch (e) {
      print('⚠️ Error in play/pause: $e');
    }
  }

  void _toggleControls() {
    if (_disposed) return;
    
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 3 seconds
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls && !_disposed) {
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
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_disposed) {
      return Container(); // Return empty container if disposed
    }

    if (_hasError) {
      return _buildErrorWidget(theme);
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget(theme);
    }

    // Additional safety check for controller state
    try {
      if (!_controller!.value.isInitialized) {
        return _buildLoadingWidget(theme);
      }
    } catch (e) {
      print('⚠️ Controller error in build: $e');
      return _buildErrorWidget(theme);
    }

    return GestureDetector(
      onTap: _onVideoTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: widget.aspectRatio ?? 
                (_controller != null && _controller!.value.isInitialized 
                    ? _controller!.value.aspectRatio 
                    : 16 / 9), // fallback aspect ratio
            child: _controller != null 
                ? VideoPlayer(_controller!) 
                : Container(color: Colors.black), // fallback if controller is null
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
                      _formatDuration(_controller!.value.duration),
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
            TextButton(
              onPressed: () async {
                // Force refresh the controller and reinitialize
                await _controllerManager.refreshController(widget.videoUrl);
                await _initializeVideo();
              },
              child: Text(
                'Tap to retry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
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
                _controller!,
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
              '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
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
