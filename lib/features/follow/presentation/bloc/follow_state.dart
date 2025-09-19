import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/follow_model.dart';

enum FollowStatus {
  initial,
  loading,
  loaded,
  error,
}

enum FollowButtonStatus {
  unknown,
  notFollowing,
  following,
  loading,
}

class FollowState extends Equatable {
  final FollowStatus status;
  final FollowButtonStatus followButtonStatus;
  final UserStatsModel userStats;
  final String? errorMessage;
  
  // Followers and following lists
  final List<UserModel> followers;
  final List<UserModel> following;
  final List<UserModel> mutualFollowers;
  
  // Pagination
  final bool hasMoreFollowers;
  final bool hasMoreFollowing;
  final DocumentSnapshot? lastFollowerDocument;
  final DocumentSnapshot? lastFollowingDocument;
  
  // Loading states
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final bool isLoadingMoreFollowers;
  final bool isLoadingMoreFollowing;
  
  // Target user for follow operations
  final String? targetUserId;

  const FollowState({
    this.status = FollowStatus.initial,
    this.followButtonStatus = FollowButtonStatus.unknown,
    required this.userStats,
    this.errorMessage,
    this.followers = const [],
    this.following = const [],
    this.mutualFollowers = const [],
    this.hasMoreFollowers = true,
    this.hasMoreFollowing = true,
    this.lastFollowerDocument,
    this.lastFollowingDocument,
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.isLoadingMoreFollowers = false,
    this.isLoadingMoreFollowing = false,
    this.targetUserId,
  });

  // Initial state
  factory FollowState.initial() {
    return FollowState(
      userStats: UserStatsModel(
        userId: '',
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  // Copy with method
  FollowState copyWith({
    FollowStatus? status,
    FollowButtonStatus? followButtonStatus,
    UserStatsModel? userStats,
    String? errorMessage,
    List<UserModel>? followers,
    List<UserModel>? following,
    List<UserModel>? mutualFollowers,
    bool? hasMoreFollowers,
    bool? hasMoreFollowing,
    DocumentSnapshot? lastFollowerDocument,
    DocumentSnapshot? lastFollowingDocument,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    bool? isLoadingMoreFollowers,
    bool? isLoadingMoreFollowing,
    String? targetUserId,
  }) {
    return FollowState(
      status: status ?? this.status,
      followButtonStatus: followButtonStatus ?? this.followButtonStatus,
      userStats: userStats ?? this.userStats,
      errorMessage: errorMessage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      mutualFollowers: mutualFollowers ?? this.mutualFollowers,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      lastFollowerDocument: lastFollowerDocument ?? this.lastFollowerDocument,
      lastFollowingDocument: lastFollowingDocument ?? this.lastFollowingDocument,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      isLoadingMoreFollowers: isLoadingMoreFollowers ?? this.isLoadingMoreFollowers,
      isLoadingMoreFollowing: isLoadingMoreFollowing ?? this.isLoadingMoreFollowing,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }

  // Specific state modifiers
  FollowState copyWithLoading() {
    return copyWith(
      status: FollowStatus.loading,
      errorMessage: null,
    );
  }

  FollowState copyWithLoaded({
    UserStatsModel? userStats,
    FollowButtonStatus? followButtonStatus,
  }) {
    return copyWith(
      status: FollowStatus.loaded,
      userStats: userStats,
      followButtonStatus: followButtonStatus,
      errorMessage: null,
    );
  }

  FollowState copyWithError(String message) {
    return copyWith(
      status: FollowStatus.error,
      errorMessage: message,
    );
  }

  FollowState copyWithFollowButtonLoading() {
    return copyWith(
      followButtonStatus: FollowButtonStatus.loading,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowButtonStatus(FollowButtonStatus status) {
    return copyWith(
      followButtonStatus: status,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowersLoading() {
    return copyWith(
      isLoadingFollowers: true,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowersLoaded({
    required List<UserModel> followers,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      followers: followers,
      lastFollowerDocument: lastDocument,
      hasMoreFollowers: hasMore ?? true,
      isLoadingFollowers: false,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowersLoadingMore() {
    return copyWith(
      isLoadingMoreFollowers: true,
      errorMessage: null,
    );
  }

  FollowState copyWithMoreFollowersLoaded({
    required List<UserModel> newFollowers,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      followers: [...followers, ...newFollowers],
      lastFollowerDocument: lastDocument,
      hasMoreFollowers: hasMore ?? true,
      isLoadingMoreFollowers: false,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowingLoading() {
    return copyWith(
      isLoadingFollowing: true,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowingLoaded({
    required List<UserModel> following,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      following: following,
      lastFollowingDocument: lastDocument,
      hasMoreFollowing: hasMore ?? true,
      isLoadingFollowing: false,
      errorMessage: null,
    );
  }

  FollowState copyWithFollowingLoadingMore() {
    return copyWith(
      isLoadingMoreFollowing: true,
      errorMessage: null,
    );
  }

  FollowState copyWithMoreFollowingLoaded({
    required List<UserModel> newFollowing,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
  }) {
    return copyWith(
      following: [...following, ...newFollowing],
      lastFollowingDocument: lastDocument,
      hasMoreFollowing: hasMore ?? true,
      isLoadingMoreFollowing: false,
      errorMessage: null,
    );
  }

  FollowState copyWithMutualFollowers(List<UserModel> mutualFollowers) {
    return copyWith(
      mutualFollowers: mutualFollowers,
      errorMessage: null,
    );
  }

  FollowState copyWithTargetUser(String targetUserId) {
    return copyWith(
      targetUserId: targetUserId,
    );
  }

  // Computed properties
  bool get isLoading => status == FollowStatus.loading;
  bool get isLoaded => status == FollowStatus.loaded;
  bool get hasError => status == FollowStatus.error;
  
  bool get isFollowButtonLoading => followButtonStatus == FollowButtonStatus.loading;
  bool get isFollowing => followButtonStatus == FollowButtonStatus.following;
  bool get isNotFollowing => followButtonStatus == FollowButtonStatus.notFollowing;
  bool get isFollowStatusUnknown => followButtonStatus == FollowButtonStatus.unknown;

  int get followersCount => userStats.followersCount;
  int get followingCount => userStats.followingCount;
  int get postsCount => userStats.postsCount;

  @override
  List<Object?> get props => [
    status,
    followButtonStatus,
    userStats,
    errorMessage,
    followers,
    following,
    mutualFollowers,
    hasMoreFollowers,
    hasMoreFollowing,
    lastFollowerDocument,
    lastFollowingDocument,
    isLoadingFollowers,
    isLoadingFollowing,
    isLoadingMoreFollowers,
    isLoadingMoreFollowing,
    targetUserId,
  ];

  @override
  String toString() {
    return '''FollowState {
      status: $status,
      followButtonStatus: $followButtonStatus,
      userStats: $userStats,
      followersCount: ${followers.length},
      followingCount: ${following.length},
      mutualFollowersCount: ${mutualFollowers.length},
      targetUserId: $targetUserId,
      errorMessage: $errorMessage
    }''';
  }
}
