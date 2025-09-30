import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../feed/data/models/post_model.dart';

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
  final File? selectedMedia;
  final MediaType mediaType;
  final String caption;
  final String? location;
  final double uploadProgress;
  final String? errorMessage;

  const PostCreationState({
    this.status = PostCreationStatus.initial,
    this.selectedMedia,
    this.mediaType = MediaType.image,
    this.caption = '',
    this.location,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  // Initial state
  factory PostCreationState.initial() {
    return const PostCreationState();
  }

  // Media selecting state
  PostCreationState copyWithMediaSelecting() {
    return PostCreationState(
      status: PostCreationStatus.imageSelecting,
      selectedMedia: selectedMedia,
      mediaType: mediaType,
      caption: caption,
      location: location,
    );
  }

  // Media selected state
  PostCreationState copyWithMediaSelected(File mediaFile, MediaType type) {
    return PostCreationState(
      status: PostCreationStatus.imageSelected,
      selectedMedia: mediaFile,
      mediaType: type,
      caption: caption,
      location: location,
    );
  }

  // Caption updated
  PostCreationState copyWithCaption(String newCaption) {
    return PostCreationState(
      status: status,
      selectedMedia: selectedMedia,
      mediaType: mediaType,
      caption: newCaption,
      location: location,
      uploadProgress: uploadProgress,
    );
  }

  // Location updated
  PostCreationState copyWithLocation(String? newLocation) {
    return PostCreationState(
      status: status,
      selectedMedia: selectedMedia,
      mediaType: mediaType,
      caption: caption,
      location: newLocation,
      uploadProgress: uploadProgress,
    );
  }

  // Uploading state
  PostCreationState copyWithUploading({double? progress}) {
    return PostCreationState(
      status: PostCreationStatus.uploading,
      selectedMedia: selectedMedia,
      mediaType: mediaType,
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
      selectedMedia: selectedMedia,
      mediaType: mediaType,
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
      selectedMedia: selectedMedia,
      mediaType: mediaType,
      caption: caption,
      location: location,
      uploadProgress: uploadProgress,
    );
  }

  // Computed properties
  bool get hasMedia => selectedMedia != null;
  bool get hasImage => hasMedia && mediaType == MediaType.image;
  bool get hasVideo => hasMedia && mediaType == MediaType.video;
  bool get canSubmit => hasMedia && caption.trim().isNotEmpty;
  
  // Backward compatibility
  File? get selectedImage => selectedMedia;
  bool get isUploading => status == PostCreationStatus.uploading;
  bool get isCompleted => status == PostCreationStatus.uploaded;

  @override
  List<Object?> get props => [
        status,
        selectedMedia,
        mediaType,
        caption,
        location,
        uploadProgress,
        errorMessage,
      ];

  @override
  String toString() {
    return '''PostCreationState {
      status: $status,
      hasMedia: $hasMedia,
      mediaType: $mediaType,
      captionLength: ${caption.length},
      location: $location,
      uploadProgress: $uploadProgress,
      errorMessage: $errorMessage
    }''';
  }
}
