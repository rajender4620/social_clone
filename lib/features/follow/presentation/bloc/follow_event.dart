import 'package:equatable/equatable.dart';

abstract class FollowEvent extends Equatable {
  const FollowEvent();

  @override
  List<Object?> get props => [];
}

// Follow status events
class FollowStatusCheckRequested extends FollowEvent {
  final String targetUserId;

  const FollowStatusCheckRequested({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

class FollowToggleRequested extends FollowEvent {
  final String targetUserId;

  const FollowToggleRequested({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

// User stats events
class UserStatsLoadRequested extends FollowEvent {
  final String userId;

  const UserStatsLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UserStatsRefreshRequested extends FollowEvent {
  final String userId;

  const UserStatsRefreshRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Followers/Following list events
class FollowersLoadRequested extends FollowEvent {
  final String userId;

  const FollowersLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FollowersLoadMoreRequested extends FollowEvent {
  final String userId;

  const FollowersLoadMoreRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FollowingLoadRequested extends FollowEvent {
  final String userId;

  const FollowingLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FollowingLoadMoreRequested extends FollowEvent {
  final String userId;

  const FollowingLoadMoreRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Mutual followers events
class MutualFollowersLoadRequested extends FollowEvent {
  final String targetUserId;

  const MutualFollowersLoadRequested({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

// Error handling
class FollowErrorCleared extends FollowEvent {
  const FollowErrorCleared();
}

// Real-time updates
class FollowStatusUpdated extends FollowEvent {
  final String targetUserId;
  final bool isFollowing;

  const FollowStatusUpdated({
    required this.targetUserId,
    required this.isFollowing,
  });

  @override
  List<Object?> get props => [targetUserId, isFollowing];
}

class UserStatsUpdated extends FollowEvent {
  final String userId;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const UserStatsUpdated({
    required this.userId,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  });

  @override
  List<Object?> get props => [userId, followersCount, followingCount, postsCount];
}
