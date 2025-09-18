import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

// Load initial feed
class FeedLoadRequested extends FeedEvent {
  final bool isRefresh;

  const FeedLoadRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

// Load more posts (pagination)
class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}

// Like/unlike a post
class PostLikeToggled extends FeedEvent {
  final String postId;
  final String userId;

  const PostLikeToggled({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

// Refresh feed
class FeedRefreshRequested extends FeedEvent {
  const FeedRefreshRequested();
}

// Post was created (to update feed)
class PostCreated extends FeedEvent {
  final String postId;

  const PostCreated({required this.postId});

  @override
  List<Object?> get props => [postId];
}

// Post was deleted (to update feed)
class PostDeleted extends FeedEvent {
  final String postId;

  const PostDeleted({required this.postId});

  @override
  List<Object?> get props => [postId];
}

// Clear feed error
class FeedErrorCleared extends FeedEvent {
  const FeedErrorCleared();
}
