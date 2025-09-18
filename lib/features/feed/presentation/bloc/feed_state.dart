import 'package:equatable/equatable.dart';
import '../../data/models/post_model.dart';

enum FeedStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  refreshing,
  error,
}

class FeedState extends Equatable {
  final FeedStatus status;
  final List<PostModel> posts;
  final String? errorMessage;
  final bool hasReachedMax;
  final bool isRefreshing;

  const FeedState({
    this.status = FeedStatus.initial,
    this.posts = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.isRefreshing = false,
  });

  // Initial state
  factory FeedState.initial() {
    return const FeedState();
  }

  // Loading state
  FeedState copyWithLoading() {
    return FeedState(
      status: FeedStatus.loading,
      posts: posts,
      hasReachedMax: hasReachedMax,
    );
  }

  // Loaded state
  FeedState copyWithLoaded({
    required List<PostModel> posts,
    bool? hasReachedMax,
  }) {
    return FeedState(
      status: FeedStatus.loaded,
      posts: posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  // Loading more state
  FeedState copyWithLoadingMore() {
    return FeedState(
      status: FeedStatus.loadingMore,
      posts: posts,
      hasReachedMax: hasReachedMax,
    );
  }

  // Refreshing state
  FeedState copyWithRefreshing() {
    return FeedState(
      status: FeedStatus.refreshing,
      posts: posts,
      hasReachedMax: hasReachedMax,
      isRefreshing: true,
    );
  }

  // Error state
  FeedState copyWithError(String message) {
    return FeedState(
      status: FeedStatus.error,
      posts: posts,
      errorMessage: message,
      hasReachedMax: hasReachedMax,
    );
  }

  // Update specific post (for likes, etc.)
  FeedState copyWithUpdatedPost(PostModel updatedPost) {
    final updatedPosts = posts.map((post) {
      return post.id == updatedPost.id ? updatedPost : post;
    }).toList();

    return FeedState(
      status: status,
      posts: updatedPosts,
      hasReachedMax: hasReachedMax,
      isRefreshing: isRefreshing,
    );
  }

  // Remove post from feed
  FeedState copyWithRemovedPost(String postId) {
    final updatedPosts = posts.where((post) => post.id != postId).toList();

    return FeedState(
      status: status,
      posts: updatedPosts,
      hasReachedMax: hasReachedMax,
      isRefreshing: isRefreshing,
    );
  }

  // Add new post to beginning of feed
  FeedState copyWithNewPost(PostModel newPost) {
    final updatedPosts = [newPost, ...posts];

    return FeedState(
      status: status,
      posts: updatedPosts,
      hasReachedMax: hasReachedMax,
      isRefreshing: isRefreshing,
    );
  }

  // Clear error
  FeedState copyWithoutError() {
    return FeedState(
      status: FeedStatus.loaded,
      posts: posts,
      hasReachedMax: hasReachedMax,
      isRefreshing: isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        errorMessage,
        hasReachedMax,
        isRefreshing,
      ];

  @override
  String toString() {
    return '''FeedState {
      status: $status,
      postsCount: ${posts.length},
      hasReachedMax: $hasReachedMax,
      isRefreshing: $isRefreshing,
      errorMessage: $errorMessage
    }''';
  }
}
