import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/follow_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'follow_event.dart';
import 'follow_state.dart';

class FollowBloc extends Bloc<FollowEvent, FollowState> {
  final FollowRepository _followRepository;
  final AuthBloc _authBloc;
  final int _usersPerPage = 20;

  FollowBloc({
    required FollowRepository followRepository,
    required AuthBloc authBloc,
  })  : _followRepository = followRepository,
        _authBloc = authBloc,
        super(FollowState.initial()) {
    
    // Register event handlers
    on<FollowStatusCheckRequested>(_onFollowStatusCheckRequested);
    on<FollowToggleRequested>(_onFollowToggleRequested);
    on<UserStatsLoadRequested>(_onUserStatsLoadRequested);
    on<UserStatsRefreshRequested>(_onUserStatsRefreshRequested);
    on<FollowersLoadRequested>(_onFollowersLoadRequested);
    on<FollowersLoadMoreRequested>(_onFollowersLoadMoreRequested);
    on<FollowingLoadRequested>(_onFollowingLoadRequested);
    on<FollowingLoadMoreRequested>(_onFollowingLoadMoreRequested);
    on<MutualFollowersLoadRequested>(_onMutualFollowersLoadRequested);
    on<FollowErrorCleared>(_onFollowErrorCleared);
    on<FollowStatusUpdated>(_onFollowStatusUpdated);
    on<UserStatsUpdated>(_onUserStatsUpdated);
  }

  // Check follow status
  Future<void> _onFollowStatusCheckRequested(
    FollowStatusCheckRequested event,
    Emitter<FollowState> emit,
  ) async {
    final currentUser = _authBloc.state.user;
    if (currentUser.uid.isEmpty) return;

    emit(state.copyWithTargetUser(event.targetUserId));

    try {
      final isFollowing = await _followRepository.isFollowing(
        followerId: currentUser.uid,
        followingId: event.targetUserId,
      );

      emit(state.copyWithFollowButtonStatus(
        isFollowing 
          ? FollowButtonStatus.following 
          : FollowButtonStatus.notFollowing,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to check follow status: $e'));
    }
  }

  // Toggle follow/unfollow
  Future<void> _onFollowToggleRequested(
    FollowToggleRequested event,
    Emitter<FollowState> emit,
  ) async {
    final currentUser = _authBloc.state.user;
    if (currentUser.uid.isEmpty) {
      emit(state.copyWithError('You must be logged in to follow users'));
      return;
    }

    if (currentUser.uid == event.targetUserId) {
      emit(state.copyWithError('You cannot follow yourself'));
      return;
    }

    emit(state.copyWithFollowButtonLoading());

    try {
      final wasFollowing = state.isFollowing;

      if (wasFollowing) {
        // Unfollow
        await _followRepository.unfollowUser(
          followerId: currentUser.uid,
          followingId: event.targetUserId,
        );
        emit(state.copyWithFollowButtonStatus(FollowButtonStatus.notFollowing));
      } else {
        // Follow
        await _followRepository.followUser(
          followerId: currentUser.uid,
          followingId: event.targetUserId,
        );
        emit(state.copyWithFollowButtonStatus(FollowButtonStatus.following));
      }

      // Refresh user stats for both users
      add(UserStatsRefreshRequested(userId: event.targetUserId));
      add(UserStatsRefreshRequested(userId: currentUser.uid));

    } catch (e) {
      // Revert button state on error
      final originalStatus = state.isFollowing 
        ? FollowButtonStatus.following 
        : FollowButtonStatus.notFollowing;
      emit(state.copyWithFollowButtonStatus(originalStatus));
      emit(state.copyWithError(e.toString()));
    }
  }

  // Load user stats
  Future<void> _onUserStatsLoadRequested(
    UserStatsLoadRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(state.copyWithLoading());

    try {
      final userStats = await _followRepository.getUserStats(event.userId);
      emit(state.copyWithLoaded(userStats: userStats));
    } catch (e) {
      emit(state.copyWithError('Failed to load user stats: $e'));
    }
  }

  // Refresh user stats
  Future<void> _onUserStatsRefreshRequested(
    UserStatsRefreshRequested event,
    Emitter<FollowState> emit,
  ) async {
    try {
      final userStats = await _followRepository.getUserStats(event.userId);
      emit(state.copyWith(userStats: userStats));
    } catch (e) {
      // Don't emit error for refresh failures, just log them
      print('Failed to refresh user stats: $e');
    }
  }

  // Load followers
  Future<void> _onFollowersLoadRequested(
    FollowersLoadRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(state.copyWithFollowersLoading());

    try {
      final followers = await _followRepository.getFollowers(
        userId: event.userId,
        limit: _usersPerPage,
      );

      DocumentSnapshot? lastDocument;
      if (followers.isNotEmpty) {
        // Get the last document for pagination
        final lastFollowRef = await FirebaseFirestore.instance
            .collection('follows')
            .where('followingId', isEqualTo: event.userId)
            .orderBy('createdAt', descending: true)
            .limit(_usersPerPage)
            .get();
        
        if (lastFollowRef.docs.isNotEmpty) {
          lastDocument = lastFollowRef.docs.last;
        }
      }

      emit(state.copyWithFollowersLoaded(
        followers: followers,
        lastDocument: lastDocument,
        hasMore: followers.length >= _usersPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load followers: $e'));
    }
  }

  // Load more followers
  Future<void> _onFollowersLoadMoreRequested(
    FollowersLoadMoreRequested event,
    Emitter<FollowState> emit,
  ) async {
    if (!state.hasMoreFollowers || state.isLoadingMoreFollowers) return;

    emit(state.copyWithFollowersLoadingMore());

    try {
      final newFollowers = await _followRepository.getFollowers(
        userId: event.userId,
        limit: _usersPerPage,
        lastDocument: state.lastFollowerDocument,
      );

      DocumentSnapshot? lastDocument;
      if (newFollowers.isNotEmpty) {
        final lastFollowRef = await FirebaseFirestore.instance
            .collection('follows')
            .where('followingId', isEqualTo: event.userId)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(state.lastFollowerDocument!)
            .limit(_usersPerPage)
            .get();
        
        if (lastFollowRef.docs.isNotEmpty) {
          lastDocument = lastFollowRef.docs.last;
        }
      }

      emit(state.copyWithMoreFollowersLoaded(
        newFollowers: newFollowers,
        lastDocument: lastDocument,
        hasMore: newFollowers.length >= _usersPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load more followers: $e'));
    }
  }

  // Load following
  Future<void> _onFollowingLoadRequested(
    FollowingLoadRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(state.copyWithFollowingLoading());

    try {
      final following = await _followRepository.getFollowing(
        userId: event.userId,
        limit: _usersPerPage,
      );

      DocumentSnapshot? lastDocument;
      if (following.isNotEmpty) {
        final lastFollowRef = await FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: event.userId)
            .orderBy('createdAt', descending: true)
            .limit(_usersPerPage)
            .get();
        
        if (lastFollowRef.docs.isNotEmpty) {
          lastDocument = lastFollowRef.docs.last;
        }
      }

      emit(state.copyWithFollowingLoaded(
        following: following,
        lastDocument: lastDocument,
        hasMore: following.length >= _usersPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load following: $e'));
    }
  }

  // Load more following
  Future<void> _onFollowingLoadMoreRequested(
    FollowingLoadMoreRequested event,
    Emitter<FollowState> emit,
  ) async {
    if (!state.hasMoreFollowing || state.isLoadingMoreFollowing) return;

    emit(state.copyWithFollowingLoadingMore());

    try {
      final newFollowing = await _followRepository.getFollowing(
        userId: event.userId,
        limit: _usersPerPage,
        lastDocument: state.lastFollowingDocument,
      );

      DocumentSnapshot? lastDocument;
      if (newFollowing.isNotEmpty) {
        final lastFollowRef = await FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: event.userId)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(state.lastFollowingDocument!)
            .limit(_usersPerPage)
            .get();
        
        if (lastFollowRef.docs.isNotEmpty) {
          lastDocument = lastFollowRef.docs.last;
        }
      }

      emit(state.copyWithMoreFollowingLoaded(
        newFollowing: newFollowing,
        lastDocument: lastDocument,
        hasMore: newFollowing.length >= _usersPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load more following: $e'));
    }
  }

  // Load mutual followers
  Future<void> _onMutualFollowersLoadRequested(
    MutualFollowersLoadRequested event,
    Emitter<FollowState> emit,
  ) async {
    final currentUser = _authBloc.state.user;
    if (currentUser.uid.isEmpty) return;

    try {
      final mutualFollowers = await _followRepository.getMutualFollowers(
        currentUserId: currentUser.uid,
        targetUserId: event.targetUserId,
      );

      emit(state.copyWithMutualFollowers(mutualFollowers));
    } catch (e) {
      // Don't emit error for mutual followers, just log
      print('Failed to load mutual followers: $e');
    }
  }

  // Clear errors
  void _onFollowErrorCleared(
    FollowErrorCleared event,
    Emitter<FollowState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  // Handle real-time follow status updates
  void _onFollowStatusUpdated(
    FollowStatusUpdated event,
    Emitter<FollowState> emit,
  ) {
    if (state.targetUserId == event.targetUserId) {
      emit(state.copyWithFollowButtonStatus(
        event.isFollowing 
          ? FollowButtonStatus.following 
          : FollowButtonStatus.notFollowing,
      ));
    }
  }

  // Handle real-time user stats updates
  void _onUserStatsUpdated(
    UserStatsUpdated event,
    Emitter<FollowState> emit,
  ) {
    if (state.userStats.userId == event.userId) {
      final updatedStats = state.userStats.copyWith(
        followersCount: event.followersCount,
        followingCount: event.followingCount,
        postsCount: event.postsCount,
        updatedAt: DateTime.now(),
      );
      
      emit(state.copyWith(userStats: updatedStats));
    }
  }
}
