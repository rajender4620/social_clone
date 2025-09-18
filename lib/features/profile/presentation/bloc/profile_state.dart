import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../feed/data/models/post_model.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
  editing,
}

enum ProfilePostsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserModel? user;
  final Map<String, int> userStats;
  final String? errorMessage;
  
  // Posts related
  final ProfilePostsStatus postsStatus;
  final List<PostModel> posts;
  final bool hasMorePosts;
  final DocumentSnapshot? lastPostDocument;
  final String? postsErrorMessage;
  
  // UI state
  final int selectedTabIndex;
  final bool isOwnProfile;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.userStats = const {'posts': 0, 'followers': 0, 'following': 0},
    this.errorMessage,
    this.postsStatus = ProfilePostsStatus.initial,
    this.posts = const [],
    this.hasMorePosts = true,
    this.lastPostDocument,
    this.postsErrorMessage,
    this.selectedTabIndex = 0,
    this.isOwnProfile = false,
  });

  // Initial state
  factory ProfileState.initial() {
    return const ProfileState();
  }

  // Copy with methods
  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    Map<String, int>? userStats,
    String? errorMessage,
    ProfilePostsStatus? postsStatus,
    List<PostModel>? posts,
    bool? hasMorePosts,
    DocumentSnapshot? lastPostDocument,
    String? postsErrorMessage,
    int? selectedTabIndex,
    bool? isOwnProfile,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      userStats: userStats ?? this.userStats,
      errorMessage: errorMessage,
      postsStatus: postsStatus ?? this.postsStatus,
      posts: posts ?? this.posts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      lastPostDocument: lastPostDocument ?? this.lastPostDocument,
      postsErrorMessage: postsErrorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
    );
  }

  // Specific state modifiers
  ProfileState copyWithLoading() {
    return copyWith(
      status: ProfileStatus.loading,
      errorMessage: null,
    );
  }

  ProfileState copyWithRefreshing() {
    return copyWith(
      status: ProfileStatus.refreshing,
      errorMessage: null,
    );
  }

  ProfileState copyWithLoaded({
    required UserModel user,
    required Map<String, int> userStats,
    required bool isOwnProfile,
  }) {
    return copyWith(
      status: ProfileStatus.loaded,
      user: user,
      userStats: userStats,
      isOwnProfile: isOwnProfile,
      errorMessage: null,
    );
  }

  ProfileState copyWithError(String message) {
    return copyWith(
      status: ProfileStatus.error,
      errorMessage: message,
    );
  }

  ProfileState copyWithEditing() {
    return copyWith(
      status: ProfileStatus.editing,
      errorMessage: null,
    );
  }

  // Posts state modifiers
  ProfileState copyWithPostsLoading() {
    return copyWith(
      postsStatus: ProfilePostsStatus.loading,
      postsErrorMessage: null,
    );
  }

  ProfileState copyWithPostsLoaded({
    required List<PostModel> posts,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      postsStatus: ProfilePostsStatus.loaded,
      posts: posts,
      lastPostDocument: lastDocument,
      hasMorePosts: hasMore ?? true,
      postsErrorMessage: null,
    );
  }

  ProfileState copyWithPostsLoadingMore() {
    return copyWith(
      postsStatus: ProfilePostsStatus.loadingMore,
      postsErrorMessage: null,
    );
  }

  ProfileState copyWithMorePostsLoaded({
    required List<PostModel> newPosts,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      postsStatus: ProfilePostsStatus.loaded,
      posts: [...posts, ...newPosts],
      lastPostDocument: lastDocument,
      hasMorePosts: hasMore ?? true,
      postsErrorMessage: null,
    );
  }

  ProfileState copyWithPostsError(String message) {
    return copyWith(
      postsStatus: ProfilePostsStatus.error,
      postsErrorMessage: message,
    );
  }

  ProfileState copyWithTabChanged(int tabIndex) {
    return copyWith(
      selectedTabIndex: tabIndex,
    );
  }

  // Computed properties
  bool get isLoading => status == ProfileStatus.loading;
  bool get isLoaded => status == ProfileStatus.loaded;
  bool get isRefreshing => status == ProfileStatus.refreshing;
  bool get isEditing => status == ProfileStatus.editing;
  bool get hasError => status == ProfileStatus.error;
  
  bool get arePostsLoading => postsStatus == ProfilePostsStatus.loading;
  bool get arePostsLoaded => postsStatus == ProfilePostsStatus.loaded;
  bool get arePostsLoadingMore => postsStatus == ProfilePostsStatus.loadingMore;
  bool get havePostsError => postsStatus == ProfilePostsStatus.error;

  String get displayName => user?.displayName ?? user?.username ?? 'Unknown User';
  String get username => user?.username ?? '';
  String get bio => user?.bio ?? '';
  String? get profileImageUrl => user?.profileImageUrl;
  
  int get postsCount => userStats['posts'] ?? 0;
  int get followersCount => userStats['followers'] ?? 0;
  int get followingCount => userStats['following'] ?? 0;

  @override
  List<Object?> get props => [
    status,
    user,
    userStats,
    errorMessage,
    postsStatus,
    posts,
    hasMorePosts,
    lastPostDocument,
    postsErrorMessage,
    selectedTabIndex,
    isOwnProfile,
  ];

  @override
  String toString() {
    return '''ProfileState {
      status: $status,
      user: ${user?.username ?? 'null'},
      userStats: $userStats,
      postsStatus: $postsStatus,
      postsCount: ${posts.length},
      selectedTab: $selectedTabIndex,
      isOwnProfile: $isOwnProfile,
      errorMessage: $errorMessage,
      postsErrorMessage: $postsErrorMessage
    }''';
  }
}
