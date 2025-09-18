import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/upload_progress_widget.dart';
import '../bloc/post_creation_bloc.dart';
import '../bloc/post_creation_event.dart';
import '../bloc/post_creation_state.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/caption_input_widget.dart';
import '../widgets/location_input_widget.dart';
import '../../../../shared/services/image_picker_service.dart';
import 'package:image_picker/image_picker.dart' as picker;

class PostCreationPage extends StatelessWidget {
  const PostCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('New Post'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<PostCreationBloc, PostCreationState>(
            builder: (context, state) {
              return TextButton(
                onPressed: state.canSubmit && !state.isUploading
                    ? () {
                        context.read<PostCreationBloc>().add(const PostSubmitted());
                      }
                    : null,
                child: Text(
                  state.isUploading ? 'Sharing...' : 'Share',
                  style: TextStyle(
                    color: state.canSubmit && !state.isUploading
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
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
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post shared successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

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

                    // Location Input
                    LocationInputWidget(
                      location: state.location,
                      onLocationChanged: (location) {
                        context.read<PostCreationBloc>().add(
                          LocationChanged(location: location),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Post Guidelines
                    _buildPostGuidelines(theme),
                  ],
                ],
              ),
            );
          },
        ),
      ),
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
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for Great Posts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(theme, '• Use good lighting for better photo quality'),
          _buildTip(theme, '• Write engaging captions to connect with your audience'),
          _buildTip(theme, '• Add location to help others discover your post'),
          _buildTip(theme, '• Be authentic and share your unique perspective'),
        ],
      ),
    );
  }

  Widget _buildTip(ThemeData theme, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}
