import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/upload_progress_widget.dart';
import '../bloc/post_creation_bloc.dart';
import '../bloc/post_creation_event.dart';
import '../bloc/post_creation_state.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';
import '../../../../shared/widgets/video_player_widget.dart';

class PostCreationPage extends StatelessWidget {
  const PostCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'New Post',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            HapticService.lightImpact();
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BlocBuilder<PostCreationBloc, PostCreationState>(
              builder: (context, state) {
                return Container(
                  decoration: BoxDecoration(
                    color:
                        state.canSubmit && !state.isUploading
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          state.canSubmit && !state.isUploading
                              ? () {
                                HapticService.buttonPress();
                                context.read<PostCreationBloc>().add(
                                  const PostSubmitted(),
                                );
                              }
                              : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.isUploading) ...[
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              state.isUploading ? 'Sharing...' : 'Share',
                              style: TextStyle(
                                color:
                                    state.canSubmit && !state.isUploading
                                        ? Colors.white
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
      body: BlocListener<PostCreationBloc, PostCreationState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: theme.colorScheme.onError,
                  onPressed: () {
                    context.read<PostCreationBloc>().add(
                      const PostCreationErrorCleared(),
                    );
                  },
                ),
              ),
            );
          }

          if (state.isCompleted) {
            // Add haptic feedback for success
            HapticService.postCreated();

            // Show success message
            context.showSuccessSnackbar('Post shared successfully! 🎉');

            // Navigate back to feed
            context.go('/home');
          }
        },
        child: BlocBuilder<PostCreationBloc, PostCreationState>(
          builder: (context, state) {
            if (state.isUploading) {
              return const UploadProgressWidget();
            }

            return _buildSimplifiedPostCreation(context, state, theme);
          },
        ),
      ),
    );
  }

  /// Simplified single-screen post creation interface
  Widget _buildSimplifiedPostCreation(
    BuildContext context,
    PostCreationState state,
    ThemeData theme,
  ) {
    if (!state.hasMedia) {
      return _buildMediaSelectionScreen(context, theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean media preview (image or video)
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: state.hasVideo
                      ? _buildVideoPreview(state.selectedMedia!)
                      : Image.file(
                          state.selectedMedia!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),

                // Remove image button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        HapticService.lightImpact();
                        context.read<PostCreationBloc>().add(
                          const MediaRemoved(),
                        );
                      },
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Caption input
          Text(
            'Caption',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              onChanged: (caption) {
                context.read<PostCreationBloc>().add(
                  CaptionChanged(caption: caption),
                );
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Share what\'s on your mind...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              minLines: 2,
            ),
          ),

          const SizedBox(height: 20),

          // Location input
          Text(
            'Location (Optional)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              onChanged: (location) {
                context.read<PostCreationBloc>().add(
                  LocationChanged(location: location),
                );
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Where are you?',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.primary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Engagement tip (clean and minimal)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro Tip',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Posts with captions and locations get more engagement!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clean media selection screen
  Widget _buildMediaSelectionScreen(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Share a moment',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          BlocBuilder<PostCreationBloc, PostCreationState>(
            builder: (context, state) {
              return Text(
                state.mediaType == MediaType.video 
                    ? 'Choose a video to get started'
                    : 'Choose a photo to get started',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

            // Media type selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlocBuilder<PostCreationBloc, PostCreationState>(
                    builder: (context, state) {
                      return _buildMediaTypeButton(
                        context,
                        icon: Icons.photo_library_outlined,
                        label: 'Photos',
                        isSelected: state.mediaType == MediaType.image,
                        onTap: () {
                          HapticService.lightImpact();
                          context.read<PostCreationBloc>().add(
                            MediaTypeChanged(mediaType: MediaType.image),
                          );
                        },
                      );
                    },
                  ),
                  BlocBuilder<PostCreationBloc, PostCreationState>(
                    builder: (context, state) {
                      return _buildMediaTypeButton(
                        context,
                        icon: Icons.videocam_outlined,
                        label: 'Videos',
                        isSelected: state.mediaType == MediaType.video,
                        onTap: () {
                          HapticService.lightImpact();
                          context.read<PostCreationBloc>().add(
                            MediaTypeChanged(mediaType: MediaType.video),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Source selection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera button
                BlocBuilder<PostCreationBloc, PostCreationState>(
                  builder: (context, state) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        HapticService.lightImpact();
                        if (state.mediaType == MediaType.video) {
                          context.read<PostCreationBloc>().add(
                            const VideoSelectedFromCamera(),
                          );
                        } else {
                          context.read<PostCreationBloc>().add(
                            const ImageSelectedFromCamera(),
                          );
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                ),
 
                const SizedBox(width: 16),
 
                // Gallery button
                BlocBuilder<PostCreationBloc, PostCreationState>(
                  builder: (context, state) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        HapticService.lightImpact();
                        if (state.mediaType == MediaType.video) {
                          context.read<PostCreationBloc>().add(
                            const VideoSelectedFromGallery(),
                          );
                        } else {
                          context.read<PostCreationBloc>().add(
                            const ImageSelectedFromGallery(),
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                ? Colors.white 
                : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected 
                  ? Colors.white 
                  : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(File videoFile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Actual video preview - centered and properly fitted
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: VideoPlayerWidget(
                  videoUrl: videoFile.path, // Local file path
                  autoPlay: false,          // Don't auto-play in preview
                  muted: true,              // Muted by default
                  showControls: true,       // Show play/pause controls
                  // No fixed aspectRatio - use video's natural ratio
                ),
              ),
            ),
          ),
          
          // Video indicator overlay
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Video Preview',
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
          
          // Helpful tip overlay
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to play/pause • Your video is ready to share',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
