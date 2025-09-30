import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/upload_progress_widget.dart';
import '../bloc/post_creation_bloc.dart';
import '../bloc/post_creation_event.dart';
import '../bloc/post_creation_state.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/caption_input_widget.dart';
import '../widgets/enhanced_location_picker.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/services/snackbar_service.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../../../shared/services/location_service.dart';
import 'package:image_picker/image_picker.dart' as picker;

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
                    color: state.canSubmit && !state.isUploading
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: state.canSubmit && !state.isUploading
                          ? () {
                              HapticService.buttonPress();
                              context.read<PostCreationBloc>().add(const PostSubmitted());
                            }
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                color: state.canSubmit && !state.isUploading
                                    ? Colors.white
                                    : theme.colorScheme.onSurface.withOpacity(0.4),
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
                    context.read<PostCreationBloc>().add(const PostCreationErrorCleared());
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Selection/Preview
                  ImagePreviewWidget(
                    selectedImage: state.selectedImage,
                    onImageTap: () => _showImagePickerOptions(context),
                    onImageRemove: state.hasImage
                        ? () {
                            context.read<PostCreationBloc>().add(const ImageRemoved());
                          }
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // Caption Input
                  if (state.hasImage) ...[
                    CaptionInputWidget(
                      caption: state.caption,
                      onCaptionChanged: (caption) {
                        context.read<PostCreationBloc>().add(
                          CaptionChanged(caption: caption),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Location Picker
                    EnhancedLocationPicker(
                      selectedLocation: _parseLocationData(state.location),
                      onLocationChanged: (locationData) {
                        context.read<PostCreationBloc>().add(
                          LocationChanged(location: locationData?.shortAddress),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Post Guidelines
                    _buildPostGuidelines(theme),

                    const SizedBox(height: 16),

                    // Posting Tips
                    _buildPostingTips(theme),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Parse location string to LocationData for the enhanced picker
  LocationData? _parseLocationData(String? location) {
    if (location == null || location.isEmpty) return null;
    
    // For now, create a simple LocationData from the string
    // In a real app, you might want to store more detailed location data
    return LocationData(
      latitude: 0,
      longitude: 0,
      address: location,
    );
  }

  Future<void> _showImagePickerOptions(BuildContext context) async {
    final imageSource = await ImagePickerService.showImageSourceDialog(context);
    
    if (imageSource != null && context.mounted) {
      switch (imageSource) {
        case picker.ImageSource.camera:
          context.read<PostCreationBloc>().add(const ImageSelectedFromCamera());
          break;
        case picker.ImageSource.gallery:
          context.read<PostCreationBloc>().add(const ImageSelectedFromGallery());
          break;
      }
    }
  }

  Widget _buildPostGuidelines(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tips for Great Posts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedTip(theme, Icons.wb_sunny_outlined, 'Use good lighting', 'Natural light works best for photos'),
          _buildEnhancedTip(theme, Icons.edit_outlined, 'Write engaging captions', 'Tell your story and connect with your audience'),
          _buildEnhancedTip(theme, Icons.location_on_outlined, 'Add your location', 'Help others discover your post'),
          _buildEnhancedTip(theme, Icons.favorite_outline, 'Be authentic', 'Share your unique perspective', isLast: true),
        ],
      ),
    );
  }

  Widget _buildPostingTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Did you know?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Posts with locations get 79% more engagement and captions with emojis receive 47% more interactions! 📸✨',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTip(ThemeData theme, IconData icon, String title, String description, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
