import 'package:equatable/equatable.dart';
import '../../data/models/comment_model.dart';

enum CommentsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  refreshing,
  error,
  submitting,
}

class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentModel> comments;
  final String postId;
  final bool hasReachedMax;
  final String? errorMessage;
  final bool isSubmittingComment;

  const CommentsState({
    required this.status,
    required this.comments,
    required this.postId,
    required this.hasReachedMax,
    this.errorMessage,
    this.isSubmittingComment = false,
  });

  // Initial state
  static CommentsState initial({required String postId}) {
    return CommentsState(
      status: CommentsStatus.initial,
      comments: const [],
      postId: postId,
      hasReachedMax: false,
    );
  }

  // Getters for convenience
  bool get isLoading => status == CommentsStatus.loading;
  bool get isLoaded => status == CommentsStatus.loaded;
  bool get isLoadingMore => status == CommentsStatus.loadingMore;
  bool get isRefreshing => status == CommentsStatus.refreshing;
  bool get hasError => status == CommentsStatus.error;
  bool get isSubmitting => status == CommentsStatus.submitting || isSubmittingComment;

  // Copy with methods for state transitions
  CommentsState copyWithLoading() {
    return copyWith(
      status: CommentsStatus.loading,
      errorMessage: null,
    );
  }

  CommentsState copyWithLoaded({
    required List<CommentModel> comments,
    bool? hasReachedMax,
  }) {
    return copyWith(
      status: CommentsStatus.loaded,
      comments: comments,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: null,
    );
  }

  CommentsState copyWithLoadingMore() {
    return copyWith(
      status: CommentsStatus.loadingMore,
      errorMessage: null,
    );
  }

  CommentsState copyWithRefreshing() {
    return copyWith(
      status: CommentsStatus.refreshing,
      errorMessage: null,
    );
  }

  CommentsState copyWithError(String error) {
    return copyWith(
      status: CommentsStatus.error,
      errorMessage: error,
    );
  }

  CommentsState copyWithSubmitting() {
    return copyWith(
      status: CommentsStatus.submitting,
      isSubmittingComment: true,
      errorMessage: null,
    );
  }

  CommentsState copyWithNewComment(CommentModel comment) {
    return copyWith(
      status: CommentsStatus.loaded,
      comments: [comment, ...comments],
      isSubmittingComment: false,
      errorMessage: null,
    );
  }

  CommentsState copyWithUpdatedComment(CommentModel updatedComment) {
    final updatedComments = comments.map((comment) {
      return comment.id == updatedComment.id ? updatedComment : comment;
    }).toList();

    return copyWith(
      status: CommentsStatus.loaded,
      comments: updatedComments,
      errorMessage: null,
    );
  }

  CommentsState copyWithoutError() {
    return copyWith(errorMessage: null);
  }

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentModel>? comments,
    String? postId,
    bool? hasReachedMax,
    String? errorMessage,
    bool? isSubmittingComment,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      postId: postId ?? this.postId,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
    );
  }

  @override
  List<Object?> get props => [
        status,
        comments,
        postId,
        hasReachedMax,
        errorMessage,
        isSubmittingComment,
      ];
}
