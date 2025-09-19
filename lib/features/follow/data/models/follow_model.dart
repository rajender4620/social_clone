import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class FollowModel extends Equatable {
  final String id;
  final String followerId; // User who is following
  final String followingId; // User being followed
  final DateTime createdAt;
  
  const FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  // Empty follow for initial state
  static final empty = FollowModel(
    id: '',
    followerId: '',
    followingId: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Check if follow is empty
  bool get isEmpty => this == FollowModel.empty;
  bool get isNotEmpty => this != FollowModel.empty;

  // Factory constructor to create from Firestore
  factory FollowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FollowModel(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? createdAt,
  }) {
    return FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, followerId, followingId, createdAt];

  @override
  String toString() {
    return 'FollowModel{id: $id, followerId: $followerId, followingId: $followingId, createdAt: $createdAt}';
  }
}

// Model for user relationship counts
class UserStatsModel extends Equatable {
  final String userId;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime updatedAt;

  const UserStatsModel({
    required this.userId,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.updatedAt,
  });

  // Empty stats
  static final empty = UserStatsModel(
    userId: '',
    followersCount: 0,
    followingCount: 0,
    postsCount: 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Factory constructor from Firestore
  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserStatsModel(
      userId: doc.id,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method
  UserStatsModel copyWith({
    String? userId,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      userId: userId ?? this.userId,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    followersCount,
    followingCount,
    postsCount,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserStatsModel{userId: $userId, followers: $followersCount, following: $followingCount, posts: $postsCount}';
  }
}
