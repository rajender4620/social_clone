import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import 'bookmark_event.dart';
import 'bookmark_state.dart';

class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  final FeedRepository _feedRepository;
  final int _postsPerPage = 20;

  BookmarkBloc({
    required FeedRepository feedRepository,
  })  : _feedRepository = feedRepository,
        super(BookmarkState.initial()) {
    
    // Register event handlers
    on<BookmarkLoadRequested>(_onBookmarkLoadRequested);
    on<BookmarkLoadMoreRequested>(_onBookmarkLoadMoreRequested);
    on<BookmarkToggleRequested>(_onBookmarkToggleRequested);
    on<BookmarkRefreshRequested>(_onBookmarkRefreshRequested);
    on<BookmarkErrorCleared>(_onBookmarkErrorCleared);
  }

  // Load bookmarked posts
  Future<void> _onBookmarkLoadRequested(
    BookmarkLoadRequested event,
    Emitter<BookmarkState> emit,
  ) async {
    emit(state.copyWithLoading());

    try {
      final posts = await _feedRepository.getBookmarkedPosts(
        userId: event.userId,
        limit: _postsPerPage,
      );

      // Get last document for pagination
      DocumentSnapshot? lastDocument;
      if (posts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: event.userId)
            .where('postId', isEqualTo: posts.last.id)
            .limit(1)
            .get();
        
        if (lastPostRef.docs.isNotEmpty) {
          lastDocument = lastPostRef.docs.first;
        }
      }

      emit(state.copyWithLoaded(
        posts: posts,
        lastDocument: lastDocument,
        hasMore: posts.length >= _postsPerPage,
      ));

    } catch (e) {
      emit(state.copyWithError('Failed to load bookmarks: $e'));
    }
  }

  // Load more bookmarked posts
  Future<void> _onBookmarkLoadMoreRequested(
    BookmarkLoadMoreRequested event,
    Emitter<BookmarkState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWithLoadingMore());

    try {
      final newPosts = await _feedRepository.getBookmarkedPosts(
        userId: event.userId,
        limit: _postsPerPage,
        lastDocument: state.lastDocument,
      );

      // Get last document for pagination
      DocumentSnapshot? lastDocument;
      if (newPosts.isNotEmpty) {
        final lastPostRef = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: event.userId)
            .where('postId', isEqualTo: newPosts.last.id)
            .limit(1)
            .get();
        
        if (lastPostRef.docs.isNotEmpty) {
          lastDocument = lastPostRef.docs.first;
        }
      }

      emit(state.copyWithMoreLoaded(
        newPosts: newPosts,
        lastDocument: lastDocument,
        hasMore: newPosts.length >= _postsPerPage,
      ));

    } catch (e) {
      emit(state.copyWithError('Failed to load more bookmarks: $e'));
    }
  }

  // Toggle bookmark
  Future<void> _onBookmarkToggleRequested(
    BookmarkToggleRequested event,
    Emitter<BookmarkState> emit,
  ) async {
    try {
      final isBookmarked = await _feedRepository.togglePostBookmark(
        postId: event.postId,
        userId: event.userId,
      );

      // Update the local state
      if (!isBookmarked) {
        // Post was unbookmarked, remove from list
        final updatedPosts = state.posts.where((post) => post.id != event.postId).toList();
        emit(state.copyWith(posts: updatedPosts));
      }

    } catch (e) {
      emit(state.copyWithError('Failed to toggle bookmark: $e'));
    }
  }

  // Refresh bookmarks
  Future<void> _onBookmarkRefreshRequested(
    BookmarkRefreshRequested event,
    Emitter<BookmarkState> emit,
  ) async {
    add(BookmarkLoadRequested(userId: event.userId));
  }

  // Clear error
  void _onBookmarkErrorCleared(
    BookmarkErrorCleared event,
    Emitter<BookmarkState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }
}
