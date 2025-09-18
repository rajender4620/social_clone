import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthBloc _authBloc;
  final int _postsPerPage = 20;

  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthBloc authBloc,
  })  : _profileRepository = profileRepository,
        _authBloc = authBloc,
        super(ProfileState.initial()) {
    
    // Register event handlers
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileRefreshRequested>(_onProfileRefreshRequested);
    on<ProfilePostsLoadRequested>(_onProfilePostsLoadRequested);
    on<ProfilePostsLoadMoreRequested>(_onProfilePostsLoadMoreRequested);
    on<ProfileEditRequested>(_onProfileEditRequested);
    on<ProfileErrorCleared>(_onProfileErrorCleared);
    on<ProfileTabChanged>(_onProfileTabChanged);
  }

  // Load user profile
  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWithLoading());

    try {
      // Get user profile
      final user = await _profileRepository.getUserProfile(event.userId);
      if (user == null) {
        emit(state.copyWithError('User not found'));
        return;
      }

      // Get user stats
      final userStats = await _profileRepository.getUserStats(event.userId);

      // Check if this is the current user's profile
      final currentUser = _authBloc.state.user;
      final isOwnProfile = currentUser.uid == event.userId;

      emit(state.copyWithLoaded(
        user: user,
        userStats: userStats,
        isOwnProfile: isOwnProfile,
      ));

      // Auto-load posts after profile loads
      add(ProfilePostsLoadRequested(userId: event.userId));

    } catch (e) {
      emit(state.copyWithError('Failed to load profile: $e'));
    }
  }

  // Refresh user profile
  Future<void> _onProfileRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWithRefreshing());

    try {
      // Get updated user profile
      final user = await _profileRepository.getUserProfile(event.userId);
      if (user == null) {
        emit(state.copyWithError('User not found'));
        return;
      }

      // Get updated user stats
      final userStats = await _profileRepository.getUserStats(event.userId);

      // Check if this is the current user's profile
      final currentUser = _authBloc.state.user;
      final isOwnProfile = currentUser.uid == event.userId;

      emit(state.copyWithLoaded(
        user: user,
        userStats: userStats,
        isOwnProfile: isOwnProfile,
      ));

      // Refresh posts as well
      add(ProfilePostsLoadRequested(userId: event.userId));

    } catch (e) {
      emit(state.copyWithError('Failed to refresh profile: $e'));
    }
  }

  // Load user posts
  Future<void> _onProfilePostsLoadRequested(
    ProfilePostsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWithPostsLoading());

    try {
      final posts = await _profileRepository.getUserPosts(
        userId: event.userId,
        limit: _postsPerPage,
      );

      // Get last document for pagination
      DocumentSnapshot? lastDocument;
      if (posts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(posts.last.id)
            .get();
        lastDocument = lastPostRef;
      }

      emit(state.copyWithPostsLoaded(
        posts: posts,
        lastDocument: lastDocument,
        hasMore: posts.length >= _postsPerPage,
      ));

    } catch (e) {
      emit(state.copyWithPostsError('Failed to load posts: $e'));
    }
  }

  // Load more posts
  Future<void> _onProfilePostsLoadMoreRequested(
    ProfilePostsLoadMoreRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.hasMorePosts || state.arePostsLoadingMore) return;

    emit(state.copyWithPostsLoadingMore());

    try {
      final newPosts = await _profileRepository.getUserPosts(
        userId: event.userId,
        limit: _postsPerPage,
        lastDocument: state.lastPostDocument,
      );

      // Get last document for pagination
      DocumentSnapshot? lastDocument;
      if (newPosts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(newPosts.last.id)
            .get();
        lastDocument = lastPostRef;
      }

      emit(state.copyWithMorePostsLoaded(
        newPosts: newPosts,
        lastDocument: lastDocument,
        hasMore: newPosts.length >= _postsPerPage,
      ));

    } catch (e) {
      emit(state.copyWithPostsError('Failed to load more posts: $e'));
    }
  }

  // Edit profile
  Future<void> _onProfileEditRequested(
    ProfileEditRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentUser = _authBloc.state.user;
    if (currentUser.uid.isEmpty) {
      emit(state.copyWithError('You must be logged in to edit profile'));
      return;
    }

    emit(state.copyWithEditing());

    try {
      await _profileRepository.updateUserProfile(
        userId: currentUser.uid,
        displayName: event.displayName,
        bio: event.bio,
        profileImage: event.profileImage,
      );

      // Update auth bloc with new user data
      // Note: This would require adding an event to AuthBloc
      
      // Refresh the profile
      add(ProfileRefreshRequested(userId: currentUser.uid));

    } catch (e) {
      emit(state.copyWithError('Failed to update profile: $e'));
    }
  }

  // Clear errors
  void _onProfileErrorCleared(
    ProfileErrorCleared event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(
      errorMessage: null,
      postsErrorMessage: null,
    ));
  }

  // Change tab
  void _onProfileTabChanged(
    ProfileTabChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWithTabChanged(event.tabIndex));
  }
}
