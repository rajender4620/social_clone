import 'dart:io';
import 'package:equatable/equatable.dart';

enum PostCreationStatus {
  initial,
  imageSelecting,
  imageSelected,
  uploading,
  uploaded,
  error,
}

class PostCreationState extends Equatable {
  final PostCreationStatus status;
  final File? selectedImage;
  final String caption;
  final String? location;
  final double uploadProgress;
  final String? errorMessage;

  const PostCreationState({
    this.status = PostCreationStatus.initial,
    this.selectedImage,
    this.caption = '',
    this.location,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  // Initial state
  factory PostCreationState.initial() {
    return const PostCreationState();
  }

  // Image selecting state
  PostCreationState copyWithImageSelecting() {
    return PostCreationState(
      status: PostCreationStatus.imageSelecting,
      selectedImage: selectedImage,
      caption: caption,
      location: location,
    );
  }

  // Image selected state
  PostCreationState copyWithImageSelected(File image) {
    return PostCreationState(
      status: PostCreationStatus.imageSelected,
      selectedImage: image,
      caption: caption,
      location: location,
    );
  }

  // Caption updated
  PostCreationState copyWithCaption(String newCaption) {
    return PostCreationState(
      status: status,
      selectedImage: selectedImage,
      caption: newCaption,
      location: location,
      uploadProgress: uploadProgress,
    );
  }

  // Location updated
  PostCreationState copyWithLocation(String? newLocation) {
    return PostCreationState(
      status: status,
      selectedImage: selectedImage,
      caption: caption,
      location: newLocation,
      uploadProgress: uploadProgress,
    );
  }

  // Uploading state
  PostCreationState copyWithUploading({double? progress}) {
    return PostCreationState(
      status: PostCreationStatus.uploading,
      selectedImage: selectedImage,
      caption: caption,
      location: location,
      uploadProgress: progress ?? uploadProgress,
    );
  }

  // Uploaded state
  PostCreationState copyWithUploaded() {
    return const PostCreationState(
      status: PostCreationStatus.uploaded,
    );
  }

  // Error state
  PostCreationState copyWithError(String message) {
    return PostCreationState(
      status: PostCreationStatus.error,
      selectedImage: selectedImage,
      caption: caption,
      location: location,
      uploadProgress: uploadProgress,
      errorMessage: message,
    );
  }

  // Reset state
  PostCreationState copyWithReset() {
    return const PostCreationState();
  }

  // Clear error
  PostCreationState copyWithoutError() {
    return PostCreationState(
      status: status == PostCreationStatus.error 
          ? PostCreationStatus.imageSelected 
          : status,
      selectedImage: selectedImage,
      caption: caption,
      location: location,
      uploadProgress: uploadProgress,
    );
  }

  // Computed properties
  bool get hasImage => selectedImage != null;
  bool get canSubmit => hasImage && caption.trim().isNotEmpty;
  bool get isUploading => status == PostCreationStatus.uploading;
  bool get isCompleted => status == PostCreationStatus.uploaded;

  @override
  List<Object?> get props => [
        status,
        selectedImage,
        caption,
        location,
        uploadProgress,
        errorMessage,
      ];

  @override
  String toString() {
    return '''PostCreationState {
      status: $status,
      hasImage: $hasImage,
      captionLength: ${caption.length},
      location: $location,
      uploadProgress: $uploadProgress,
      errorMessage: $errorMessage
    }''';
  }
}
