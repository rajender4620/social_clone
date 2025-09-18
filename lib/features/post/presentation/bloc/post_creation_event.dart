import 'dart:io';
import 'package:equatable/equatable.dart';

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

class ImageRemoved extends PostCreationEvent {
  const ImageRemoved();
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
