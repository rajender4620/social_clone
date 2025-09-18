import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/post_creation_bloc.dart';
import '../bloc/post_creation_state.dart';

class UploadProgressWidget extends StatelessWidget {
  const UploadProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PostCreationBloc, PostCreationState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Upload animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress indicator
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: state.uploadProgress,
                        strokeWidth: 4,
                        backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    // Upload icon
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Upload status text
              Text(
                _getUploadStatusText(state.uploadProgress),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Progress percentage
              Text(
                '${(state.uploadProgress * 100).toInt()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Upload description
              Text(
                'Please wait while we share your post...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Upload steps
              _buildUploadSteps(theme, state.uploadProgress),
            ],
          ),
        );
      },
    );
  }

  String _getUploadStatusText(double progress) {
    if (progress < 0.3) {
      return 'Preparing your post...';
    } else if (progress < 0.7) {
      return 'Uploading image...';
    } else if (progress < 0.9) {
      return 'Processing...';
    } else if (progress < 1.0) {
      return 'Almost done...';
    } else {
      return 'Post shared successfully!';
    }
  }

  Widget _buildUploadSteps(ThemeData theme, double progress) {
    final steps = [
      {'title': 'Preparing', 'threshold': 0.2},
      {'title': 'Uploading', 'threshold': 0.6},
      {'title': 'Processing', 'threshold': 0.9},
      {'title': 'Complete', 'threshold': 1.0},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = progress >= (step['threshold'] as double);
        final isActive = progress >= (index > 0 ? (steps[index - 1]['threshold'] as double) : 0) &&
                        progress < (step['threshold'] as double);

        return Padding(
          padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
          child: Row(
            children: [
              // Step indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : isActive
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : theme.colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : isActive
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
              ),

              const SizedBox(width: 12),

              // Step title
              Text(
                step['title'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isCompleted || isActive
                      ? theme.colorScheme.onBackground
                      : theme.colorScheme.onBackground.withOpacity(0.5),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
