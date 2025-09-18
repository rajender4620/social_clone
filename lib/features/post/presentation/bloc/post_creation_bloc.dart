import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/data/repositories/feed_repository.dart';
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
    on<ImageRemoved>(_onImageRemoved);
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
    emit(state.copyWithImageSelecting());

    try {
      final imageFile = await _imagePickerService.pickImage(ImageSource.camera);
      if (imageFile != null) {
        emit(state.copyWithImageSelected(imageFile));
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
    emit(state.copyWithImageSelecting());

    try {
      final imageFile = await _imagePickerService.pickImage(ImageSource.gallery);
      if (imageFile != null) {
        emit(state.copyWithImageSelected(imageFile));
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
    emit(state.copyWithImageSelected(event.imageFile));
  }

  // Handle image removal
  void _onImageRemoved(
    ImageRemoved event,
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
      emit(state.copyWithError('Please select an image and add a caption'));
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
      print('   Image file: ${state.selectedImage!.path}');

      // Create the post
      final newPost = await _feedRepository.createPost(
        authorId: authState.user.uid,
        author: authState.user,
        imageFile: state.selectedImage!,
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
