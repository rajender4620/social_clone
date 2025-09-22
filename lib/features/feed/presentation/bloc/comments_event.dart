import 'package:equatable/equatable.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => [];
}

class CommentsLoadRequested extends CommentsEvent {
  final String postId;

  const CommentsLoadRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class CommentsRefreshRequested extends CommentsEvent {
  final String postId;

  const CommentsRefreshRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class CommentsLoadMoreRequested extends CommentsEvent {
  final String postId;

  const CommentsLoadMoreRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class CommentAdded extends CommentsEvent {
  final String postId;
  final String content;

  const CommentAdded({
    required this.postId,
    required this.content,
  });

  @override
  List<Object?> get props => [postId, content];
}

class CommentLikeToggled extends CommentsEvent {
  final String postId;
  final String commentId;
  final String userId;

  const CommentLikeToggled({
    required this.postId,
    required this.commentId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, commentId, userId];
}

class CommentsErrorCleared extends CommentsEvent {
  const CommentsErrorCleared();
}
