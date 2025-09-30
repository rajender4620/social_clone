import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../feed/data/models/post_model.dart';

abstract class PostCreationEvent extends Equatable {
  const PostCreationEvent();

  @override
  List<Object?> get props => [];
}

// Image selection events
class ImageSelectedFromCamera extends PostCreationEvent {
  const ImageSelectedFromCamera();
}

class ImageSelectedFromGallery extends PostCreationEvent {
  const ImageSelectedFromGallery();
}

class ImageSelected extends PostCreationEvent {
  final File imageFile;

  const ImageSelected({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

// Video selection events
class VideoSelectedFromCamera extends PostCreationEvent {
  const VideoSelectedFromCamera();
}

class VideoSelectedFromGallery extends PostCreationEvent {
  const VideoSelectedFromGallery();
}

class VideoSelected extends PostCreationEvent {
  final File videoFile;

  const VideoSelected({required this.videoFile});

  @override
  List<Object?> get props => [videoFile];
}

// General media events
class MediaSelected extends PostCreationEvent {
  final File mediaFile;
  final MediaType mediaType;

  const MediaSelected({
    required this.mediaFile,
    required this.mediaType,
  });

  @override
  List<Object?> get props => [mediaFile, mediaType];
}

class MediaTypeChanged extends PostCreationEvent {
  final MediaType mediaType;

  const MediaTypeChanged({required this.mediaType});

  @override
  List<Object?> get props => [mediaType];
}

class MediaRemoved extends PostCreationEvent {
  const MediaRemoved();
}

// Caption events
class CaptionChanged extends PostCreationEvent {
  final String caption;

  const CaptionChanged({required this.caption});

  @override
  List<Object?> get props => [caption];
}

// Location events
class LocationChanged extends PostCreationEvent {
  final String? location;

  const LocationChanged({this.location});

  @override
  List<Object?> get props => [location];
}

// Post creation events
class PostSubmitted extends PostCreationEvent {
  const PostSubmitted();
}

class PostCreationReset extends PostCreationEvent {
  const PostCreationReset();
}

// Error handling
class PostCreationErrorCleared extends PostCreationEvent {
  const PostCreationErrorCleared();
}
