import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepository;
  final int _postsPerPage = 10;
  DocumentSnapshot? _lastDocument;
  List<String>? _followingIds;

  FeedBloc({
    required FeedRepository feedRepository,
    List<String>? followingIds,
  })  : _feedRepository = feedRepository,
        _followingIds = followingIds,
        super(FeedState.initial()) {
    
    // Register event handlers
    on<FeedLoadRequested>(_onFeedLoadRequested);
    on<FeedLoadMoreRequested>(_onFeedLoadMoreRequested);
    on<PostLikeToggled>(_onPostLikeToggled);
    on<FeedRefreshRequested>(_onFeedRefreshRequested);
    on<PostCreated>(_onPostCreated);
    on<PostDeleted>(_onPostDeleted);
    on<FeedErrorCleared>(_onFeedErrorCleared);
  }

  // Update following list for personalized feed
  void updateFollowingIds(List<String> followingIds) {
    _followingIds = followingIds;
  }

  // Load initial feed
  Future<void> _onFeedLoadRequested(
    FeedLoadRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWithRefreshing());
    } else {
      emit(state.copyWithLoading());
    }

    try {
      // Reset pagination for fresh load
      _lastDocument = null;

      final posts = await _feedRepository.getFeedPosts(
        limit: _postsPerPage,
        followingIds: _followingIds,
      );

      // Update last document for pagination
      if (posts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(posts.last.id)
            .get();
        _lastDocument = lastPostRef;
      }

      emit(state.copyWithLoaded(
        posts: posts,
        hasReachedMax: posts.length < _postsPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load feed: $e'));
    }
  }

  // Load more posts (pagination)
  Future<void> _onFeedLoadMoreRequested(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (state.hasReachedMax || state.status == FeedStatus.loadingMore) {
      return;
    }

    emit(state.copyWithLoadingMore());

    try {
      final newPosts = await _feedRepository.getFeedPosts(
        limit: _postsPerPage,
        lastDocument: _lastDocument,
        followingIds: _followingIds,
      );

      // Update last document for next pagination
      if (newPosts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(newPosts.last.id)
            .get();
        _lastDocument = lastPostRef;
      }

      final allPosts = [...state.posts, ...newPosts];

      emit(state.copyWithLoaded(
        posts: allPosts,
        hasReachedMax: newPosts.length < _postsPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load more posts: $e'));
    }
  }

  // Toggle like on a post
  Future<void> _onPostLikeToggled(
    PostLikeToggled event,
    Emitter<FeedState> emit,
  ) async {
    try {
      // Optimistically update UI
      final postIndex = state.posts.indexWhere((post) => post.id == event.postId);
      if (postIndex == -1) return;

      final currentPost = state.posts[postIndex];
      final optimisticPost = currentPost.toggleLike(event.userId);
      emit(state.copyWithUpdatedPost(optimisticPost));

      // Perform actual update
      final updatedPost = await _feedRepository.togglePostLike(
        postId: event.postId,
        userId: event.userId,
      );

      // Update with server response
      emit(state.copyWithUpdatedPost(updatedPost));
    } catch (e) {
      // Revert optimistic update on error
      final postIndex = state.posts.indexWhere((post) => post.id == event.postId);
      if (postIndex != -1) {
        final originalPost = state.posts[postIndex].toggleLike(event.userId);
        emit(state.copyWithUpdatedPost(originalPost));
      }
      
      emit(state.copyWithError('Failed to toggle like: $e'));
    }
  }

  // Refresh feed
  Future<void> _onFeedRefreshRequested(
    FeedRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    add(const FeedLoadRequested(isRefresh: true));
  }

  // Handle new post creation
  Future<void> _onPostCreated(
    PostCreated event,
    Emitter<FeedState> emit,
  ) async {
    try {
      // Fetch the new post and add it to the top of the feed
      final posts = await _feedRepository.getFeedPosts(limit: 1);
      if (posts.isNotEmpty && posts.first.id == event.postId) {
        emit(state.copyWithNewPost(posts.first));
      }
    } catch (e) {
      // Silently fail for this non-critical operation
    }
  }

  // Handle post deletion
  void _onPostDeleted(
    PostDeleted event,
    Emitter<FeedState> emit,
  ) {
    emit(state.copyWithRemovedPost(event.postId));
  }

  // Clear feed error
  void _onFeedErrorCleared(
    FeedErrorCleared event,
    Emitter<FeedState> emit,
  ) {
    emit(state.copyWithoutError());
  }
}
