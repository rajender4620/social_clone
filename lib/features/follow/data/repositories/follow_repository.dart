import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_model.dart';
import '../../../auth/data/models/user_model.dart';

class FollowRepository {
  final FirebaseFirestore _firestore;

  FollowRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Follow a user
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if already following
        final existingFollow = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: followingId)
            .get();

        if (existingFollow.docs.isNotEmpty) {
          throw Exception('Already following this user');
        }

        // Create follow relationship
        final followData = FollowModel(
          id: '', // Will be set by Firestore
          followerId: followerId,
          followingId: followingId,
          createdAt: DateTime.now(),
        );

        final followRef = _firestore.collection('follows').doc();
        transaction.set(followRef, followData.toFirestore());

        // Update follower count for the followed user
        final followingUserStatsRef = _firestore
            .collection('user_stats')
            .doc(followingId);
        
        final followingUserStats = await transaction.get(followingUserStatsRef);
        if (followingUserStats.exists) {
          transaction.update(followingUserStatsRef, {
            'followersCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(followingUserStatsRef, {
            'followersCount': 1,
            'followingCount': 0,
            'postsCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update following count for the follower
        final followerUserStatsRef = _firestore
            .collection('user_stats')
            .doc(followerId);
        
        final followerUserStats = await transaction.get(followerUserStatsRef);
        if (followerUserStats.exists) {
          transaction.update(followerUserStatsRef, {
            'followingCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(followerUserStatsRef, {
            'followersCount': 0,
            'followingCount': 1,
            'postsCount': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Find the follow relationship
        final followQuery = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: followingId)
            .get();

        if (followQuery.docs.isEmpty) {
          throw Exception('Not following this user');
        }

        // Delete follow relationship
        final followDoc = followQuery.docs.first;
        transaction.delete(followDoc.reference);

        // Update follower count for the unfollowed user
        final followingUserStatsRef = _firestore
            .collection('user_stats')
            .doc(followingId);
        
        transaction.update(followingUserStatsRef, {
          'followersCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update following count for the follower
        final followerUserStatsRef = _firestore
            .collection('user_stats')
            .doc(followerId);
        
        transaction.update(followerUserStatsRef, {
          'followingCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Check if user A is following user B
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final followQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: followerId)
          .where('followingId', isEqualTo: followingId)
          .limit(1)
          .get();

      return followQuery.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Get user statistics
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();
      
      if (doc.exists) {
        return UserStatsModel.fromFirestore(doc);
      } else {
        // Return default stats if no document exists
        return UserStatsModel(
          userId: userId,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  // Get list of followers
  Future<List<UserModel>> getFollowers({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);
      final followsSnapshot = await query.get();

      // Get follower IDs
      final followerIds = followsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      // Get user details for followers
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followerIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  // Get list of following
  Future<List<UserModel>> getFollowing({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);
      final followsSnapshot = await query.get();

      // Get following IDs
      final followingIds = followsSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get user details for following
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get following: $e');
    }
  }

  // Get mutual followers (users you both follow)
  Future<List<UserModel>> getMutualFollowers({
    required String currentUserId,
    required String targetUserId,
    int limit = 10,
  }) async {
    try {
      // Get users that current user follows
      final currentUserFollowingQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .get();

      final currentUserFollowingIds = currentUserFollowingQuery.docs
          .map((doc) => (doc.data())['followingId'] as String)
          .toList();

      if (currentUserFollowingIds.isEmpty) return [];

      // Get users that target user follows from the same list
      final mutualFollowsQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: targetUserId)
          .where('followingId', whereIn: currentUserFollowingIds.take(10).toList())
          .limit(limit)
          .get();

      final mutualFollowingIds = mutualFollowsQuery.docs
          .map((doc) => (doc.data())['followingId'] as String)
          .toList();

      if (mutualFollowingIds.isEmpty) return [];

      // Get user details
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: mutualFollowingIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get mutual followers: $e');
    }
  }

  // Update post count for user stats
  Future<void> updatePostCount(String userId, int increment) async {
    try {
      final userStatsRef = _firestore.collection('user_stats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userStats = await transaction.get(userStatsRef);
        
        if (userStats.exists) {
          transaction.update(userStatsRef, {
            'postsCount': FieldValue.increment(increment),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(userStatsRef, {
            'followersCount': 0,
            'followingCount': 0,
            'postsCount': increment > 0 ? increment : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to update post count: $e');
    }
  }

  // Get follow status stream for real-time updates
  Stream<bool> getFollowStatusStream({
    required String followerId,
    required String followingId,
  }) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Get user stats stream for real-time updates
  Stream<UserStatsModel> getUserStatsStream(String userId) {
    return _firestore
        .collection('user_stats')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserStatsModel.fromFirestore(doc);
      } else {
        return UserStatsModel(
          userId: userId,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          updatedAt: DateTime.now(),
        );
      }
    });
  }
}
