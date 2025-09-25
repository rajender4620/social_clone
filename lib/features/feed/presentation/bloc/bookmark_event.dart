import 'package:equatable/equatable.dart';

abstract class BookmarkEvent extends Equatable {
  const BookmarkEvent();

  @override
  List<Object?> get props => [];
}

// Load bookmarked posts
class BookmarkLoadRequested extends BookmarkEvent {
  final String userId;

  const BookmarkLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Load more bookmarked posts
class BookmarkLoadMoreRequested extends BookmarkEvent {
  final String userId;

  const BookmarkLoadMoreRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Toggle bookmark status
class BookmarkToggleRequested extends BookmarkEvent {
  final String postId;
  final String userId;

  const BookmarkToggleRequested({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

// Refresh bookmarks
class BookmarkRefreshRequested extends BookmarkEvent {
  final String userId;

  const BookmarkRefreshRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Clear error
class BookmarkErrorCleared extends BookmarkEvent {
  const BookmarkErrorCleared();
}
