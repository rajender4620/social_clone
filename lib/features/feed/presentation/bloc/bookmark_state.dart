import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/post_model.dart';

enum BookmarkStatus { initial, loading, loaded, error }

class BookmarkState extends Equatable {
  final BookmarkStatus status;
  final List<PostModel> posts;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String? errorMessage;

  const BookmarkState({
    required this.status,
    required this.posts,
    required this.isLoadingMore,
    required this.hasMore,
    this.lastDocument,
    this.errorMessage,
  });

  factory BookmarkState.initial() {
    return const BookmarkState(
      status: BookmarkStatus.initial,
      posts: [],
      isLoadingMore: false,
      hasMore: true,
    );
  }

  // Copy with loading state
  BookmarkState copyWithLoading() {
    return copyWith(
      status: BookmarkStatus.loading,
      errorMessage: null,
    );
  }

  // Copy with loaded state
  BookmarkState copyWithLoaded({
    required List<PostModel> posts,
    DocumentSnapshot? lastDocument,
    required bool hasMore,
  }) {
    return copyWith(
      status: BookmarkStatus.loaded,
      posts: posts,
      lastDocument: lastDocument,
      hasMore: hasMore,
      isLoadingMore: false,
      errorMessage: null,
    );
  }

  // Copy with loading more state
  BookmarkState copyWithLoadingMore() {
    return copyWith(
      isLoadingMore: true,
      errorMessage: null,
    );
  }

  // Copy with more loaded state
  BookmarkState copyWithMoreLoaded({
    required List<PostModel> newPosts,
    DocumentSnapshot? lastDocument,
    required bool hasMore,
  }) {
    return copyWith(
      posts: [...posts, ...newPosts],
      lastDocument: lastDocument,
      hasMore: hasMore,
      isLoadingMore: false,
      errorMessage: null,
    );
  }

  // Copy with error state
  BookmarkState copyWithError(String error) {
    return copyWith(
      status: BookmarkStatus.error,
      errorMessage: error,
      isLoadingMore: false,
    );
  }

  // Generic copy with
  BookmarkState copyWith({
    BookmarkStatus? status,
    List<PostModel>? posts,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? errorMessage,
  }) {
    return BookmarkState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        isLoadingMore,
        hasMore,
        lastDocument,
        errorMessage,
      ];
}
