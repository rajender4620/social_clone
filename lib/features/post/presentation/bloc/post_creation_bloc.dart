import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/data/repositories/feed_repository.dart';
import '../../../feed/data/models/post_model.dart';
import '../../../feed/presentation/bloc/feed_bloc.dart';
import '../../../feed/presentation/bloc/feed_event.dart';
import '../../../../shared/services/image_picker_service.dart';
import 'post_creation_event.dart';
import 'post_creation_state.dart';

class PostCreationBloc extends Bloc<PostCreationEvent, PostCreationState> {
  final FeedRepository _feedRepository;
  final ImagePickerService _imagePickerService;
  final AuthBloc _authBloc;
  final FeedBloc _feedBloc;

  PostCreationBloc({
    required FeedRepository feedRepository,
    required ImagePickerService imagePickerService,
    required AuthBloc authBloc,
    required FeedBloc feedBloc,
  })  : _feedRepository = feedRepository,
        _imagePickerService = imagePickerService,
        _authBloc = authBloc,
        _feedBloc = feedBloc,
        super(PostCreationState.initial()) {
    
    // Register event handlers
    on<ImageSelectedFromCamera>(_onImageSelectedFromCamera);
    on<ImageSelectedFromGallery>(_onImageSelectedFromGallery);
    on<ImageSelected>(_onImageSelected);
    on<VideoSelectedFromCamera>(_onVideoSelectedFromCamera);
    on<VideoSelectedFromGallery>(_onVideoSelectedFromGallery);
    on<VideoSelected>(_onVideoSelected);
    on<MediaSelected>(_onMediaSelected);
    on<MediaTypeChanged>(_onMediaTypeChanged);
    on<MediaRemoved>(_onMediaRemoved);
    on<CaptionChanged>(_onCaptionChanged);
    on<LocationChanged>(_onLocationChanged);
    on<PostSubmitted>(_onPostSubmitted);
    on<PostCreationReset>(_onPostCreationReset);
    on<PostCreationErrorCleared>(_onPostCreationErrorCleared);
  }

  // Handle camera image selection
  Future<void> _onImageSelectedFromCamera(
    ImageSelectedFromCamera event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(state.copyWithMediaSelecting());

    try {
      final imageFile = await _imagePickerService.pickImage(ImageSource.camera);
      if (imageFile != null) {
        emit(state.copyWithMediaSelected(imageFile, MediaType.image));
      } else {
        // User cancelled, go back to previous state
        emit(state.copyWithoutError());
      }
    } catch (e) {
      emit(state.copyWithError('Failed to capture image: $e'));
    }
  }

  // Handle gallery image selection
  Future<void> _onImageSelectedFromGallery(
    ImageSelectedFromGallery event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(state.copyWithMediaSelecting());

    try {
      final imageFile = await _imagePickerService.pickImage(ImageSource.gallery);
      if (imageFile != null) {
        emit(state.copyWithMediaSelected(imageFile, MediaType.image));
      } else {
        // User cancelled, go back to previous state
        emit(state.copyWithoutError());
      }
    } catch (e) {
      emit(state.copyWithError('Failed to select image: $e'));
    }
  }

  // Handle direct image selection (for future use)
  void _onImageSelected(
    ImageSelected event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithMediaSelected(event.imageFile, MediaType.image));
  }


  // Handle camera video selection
  Future<void> _onVideoSelectedFromCamera(
    VideoSelectedFromCamera event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(state.copyWithMediaSelecting());

    try {
      final videoFile = await _imagePickerService.pickVideo(ImageSource.camera);
      if (videoFile != null) {
        emit(state.copyWithMediaSelected(videoFile, MediaType.video));
      } else {
        // User cancelled, go back to previous state
        emit(state.copyWithoutError());
      }
    } catch (e) {
      emit(state.copyWithError('Failed to capture video: $e'));
    }
  }

  // Handle gallery video selection
  Future<void> _onVideoSelectedFromGallery(
    VideoSelectedFromGallery event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(state.copyWithMediaSelecting());

    try {
      final videoFile = await _imagePickerService.pickVideo(ImageSource.gallery);
      if (videoFile != null) {
        emit(state.copyWithMediaSelected(videoFile, MediaType.video));
      } else {
        // User cancelled, go back to previous state
        emit(state.copyWithoutError());
      }
    } catch (e) {
      emit(state.copyWithError('Failed to select video: $e'));
    }
  }

  // Handle direct video selection
  void _onVideoSelected(
    VideoSelected event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithMediaSelected(event.videoFile, MediaType.video));
  }

  // Handle general media selection
  void _onMediaSelected(
    MediaSelected event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithMediaSelected(event.mediaFile, event.mediaType));
  }

  // Handle media type change
  void _onMediaTypeChanged(
    MediaTypeChanged event,
    Emitter<PostCreationState> emit,
  ) {
    emit(PostCreationState(
      status: state.status,
      selectedMedia: state.selectedMedia,
      mediaType: event.mediaType,
      caption: state.caption,
      location: state.location,
      uploadProgress: state.uploadProgress,
      errorMessage: state.errorMessage,
    ));
  }

  // Handle media removal
  void _onMediaRemoved(
    MediaRemoved event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithReset());
  }

  // Handle caption changes
  void _onCaptionChanged(
    CaptionChanged event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithCaption(event.caption));
  }

  // Handle location changes
  void _onLocationChanged(
    LocationChanged event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithLocation(event.location));
  }

  // Handle post submission
  Future<void> _onPostSubmitted(
    PostSubmitted event,
    Emitter<PostCreationState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWithError('Please select media (image or video) and add a caption'));
      return;
    }

    final authState = _authBloc.state;
    if (authState.status != AuthStatus.authenticated) {
      emit(state.copyWithError('You must be logged in to create a post'));
      return;
    }

    print('🚀 Starting post creation...');
    emit(state.copyWithUploading());

    try {
      print('📝 Post details:');
      print('   Author: ${authState.user.username}');
      print('   Caption: ${state.caption.trim()}');
      print('   Location: ${state.location?.trim()}');
      print('   Media file: ${state.selectedMedia!.path}');
      print('   Media type: ${state.mediaType}');

      // Create the post
      final newPost = await _feedRepository.createPost(
        authorId: authState.user.uid,
        author: authState.user,
        mediaFile: state.selectedMedia!,
        mediaType: state.mediaType,
        caption: state.caption.trim(),
        location: state.location?.trim().isEmpty == true ? null : state.location?.trim(),
      );

      print('✅ Post created successfully: ${newPost.id}');

      // Update upload progress to 100%
      emit(state.copyWithUploading(progress: 1.0));

      // Wait a moment to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      // Mark as uploaded
      emit(state.copyWithUploaded());

      // Notify feed bloc about new post
      _feedBloc.add(PostCreated(postId: newPost.id));

      // Reset state after a delay
      await Future.delayed(const Duration(milliseconds: 1000));
      emit(state.copyWithReset());

    } catch (e) {
      print('❌ Post creation failed: $e');
      emit(state.copyWithError('Failed to create post: $e'));
    }
  }

  // Handle post creation reset
  void _onPostCreationReset(
    PostCreationReset event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithReset());
  }

  // Handle error clearing
  void _onPostCreationErrorCleared(
    PostCreationErrorCleared event,
    Emitter<PostCreationState> emit,
  ) {
    emit(state.copyWithoutError());
  }
}
