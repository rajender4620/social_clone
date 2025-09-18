import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../feed/data/models/post_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Get user profile data by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get user's posts
  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Use a simpler query approach to avoid composite index requirement
      Query query = _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId);

      // If we have a lastDocument, use it for pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      // Convert to PostModel and sort in memory for now
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      // Sort by creation date in descending order (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return posts;
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  // Get user's post count
  Future<int> getUserPostCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get post count: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    File? profileImage,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update display name if provided
      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      // Update bio if provided
      if (bio != null) {
        updateData['bio'] = bio;
      }

      // Upload new profile image if provided
      if (profileImage != null) {
        final imageUrl = await _uploadProfileImage(userId, profileImage);
        updateData['profileImageUrl'] = imageUrl;
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update(updateData);

      // Return updated user data
      final updatedUser = await getUserProfile(userId);
      if (updatedUser == null) {
        throw Exception('Failed to retrieve updated user data');
      }

      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final ref = _storage.ref().child('profile_images').child(fileName);
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get post count
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .count()
          .get();

      // For now, return basic stats (followers/following will be added later)
      return {
        'posts': postsSnapshot.count ?? 0,
        'followers': 0, // TODO: Implement followers count
        'following': 0, // TODO: Implement following count
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  // Search users by username
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
