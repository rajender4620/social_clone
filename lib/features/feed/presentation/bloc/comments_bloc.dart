import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/feed_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final FeedRepository _feedRepository;
  final AuthBloc _authBloc;
  final int _commentsPerPage = 20;
  DocumentSnapshot? _lastDocument;

  CommentsBloc({
    required FeedRepository feedRepository,
    required AuthBloc authBloc,
    required String postId,
  })  : _feedRepository = feedRepository,
        _authBloc = authBloc,
        super(CommentsState.initial(postId: postId)) {
    
    // Register event handlers
    on<CommentsLoadRequested>(_onCommentsLoadRequested);
    on<CommentsRefreshRequested>(_onCommentsRefreshRequested);
    on<CommentsLoadMoreRequested>(_onCommentsLoadMoreRequested);
    on<CommentAdded>(_onCommentAdded);
    on<CommentLikeToggled>(_onCommentLikeToggled);
    on<CommentsErrorCleared>(_onCommentsErrorCleared);
  }

  // Load initial comments
  Future<void> _onCommentsLoadRequested(
    CommentsLoadRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWithLoading());

    try {
      // Reset pagination for fresh load
      _lastDocument = null;

      final comments = await _feedRepository.getPostComments(
        postId: event.postId,
        limit: _commentsPerPage,
      );

      // Update last document for pagination
      if (comments.isNotEmpty) {
        final lastCommentRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(event.postId)
            .collection('comments')
            .doc(comments.last.id)
            .get();
        _lastDocument = lastCommentRef;
      }

      emit(state.copyWithLoaded(
        comments: comments,
        hasReachedMax: comments.length < _commentsPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load comments: $e'));
    }
  }

  // Refresh comments
  Future<void> _onCommentsRefreshRequested(
    CommentsRefreshRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWithRefreshing());

    try {
      // Reset pagination for fresh load
      _lastDocument = null;

      final comments = await _feedRepository.getPostComments(
        postId: event.postId,
        limit: _commentsPerPage,
      );

      // Update last document for pagination
      if (comments.isNotEmpty) {
        final lastCommentRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(event.postId)
            .collection('comments')
            .doc(comments.last.id)
            .get();
        _lastDocument = lastCommentRef;
      }

      emit(state.copyWithLoaded(
        comments: comments,
        hasReachedMax: comments.length < _commentsPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to refresh comments: $e'));
    }
  }

  // Load more comments (pagination)
  Future<void> _onCommentsLoadMoreRequested(
    CommentsLoadMoreRequested event,
    Emitter<CommentsState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) {
      return;
    }

    emit(state.copyWithLoadingMore());

    try {
      final newComments = await _feedRepository.getPostComments(
        postId: event.postId,
        limit: _commentsPerPage,
        lastDocument: _lastDocument,
      );

      // Update last document for next pagination
      if (newComments.isNotEmpty) {
        final lastCommentRef = await FirebaseFirestore.instance
            .collection('posts')
            .doc(event.postId)
            .collection('comments')
            .doc(newComments.last.id)
            .get();
        _lastDocument = lastCommentRef;
      }

      final allComments = [...state.comments, ...newComments];

      emit(state.copyWithLoaded(
        comments: allComments,
        hasReachedMax: newComments.length < _commentsPerPage,
      ));
    } catch (e) {
      emit(state.copyWithError('Failed to load more comments: $e'));
    }
  }

  // Add new comment
  Future<void> _onCommentAdded(
    CommentAdded event,
    Emitter<CommentsState> emit,
  ) async {
    final currentUser = _authBloc.state.user;
    if (currentUser.isEmpty) {
      emit(state.copyWithError('You must be logged in to comment'));
      return;
    }

    emit(state.copyWithSubmitting());

    try {
      final newComment = await _feedRepository.addComment(
        postId: event.postId,
        authorId: currentUser.uid,
        author: currentUser,
        content: event.content,
      );
      
      print('🚀 New comment added: ${newComment.id}');
      emit(state.copyWithNewComment(newComment));
    } catch (e) {
      emit(state.copyWithError('Failed to add comment: $e'));
    }
  }

  // Toggle like on a comment
  Future<void> _onCommentLikeToggled(
    CommentLikeToggled event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      // Optimistically update UI
      final commentIndex = state.comments.indexWhere(
        (comment) => comment.id == event.commentId,
      );
      if (commentIndex == -1) return;

      final currentComment = state.comments[commentIndex];
      final optimisticComment = currentComment.toggleLike(event.userId);
      emit(state.copyWithUpdatedComment(optimisticComment));

      // Perform actual update
      final updatedComment = await _feedRepository.toggleCommentLike(
        postId: event.postId,
        commentId: event.commentId,
        userId: event.userId,
      );

      // Update with server response
      emit(state.copyWithUpdatedComment(updatedComment));
    } catch (e) {
      // Revert optimistic update on error
      final commentIndex = state.comments.indexWhere(
        (comment) => comment.id == event.commentId,
      );
      if (commentIndex != -1) {
        final originalComment = state.comments[commentIndex].toggleLike(event.userId);
        emit(state.copyWithUpdatedComment(originalComment));
      }
      
      emit(state.copyWithError('Failed to toggle comment like: $e'));
    }
  }

  // Clear error
  void _onCommentsErrorCleared(
    CommentsErrorCleared event,
    Emitter<CommentsState> emit,
  ) {
    emit(state.copyWithoutError());
  }
}
