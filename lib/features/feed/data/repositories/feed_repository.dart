import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../../auth/data/models/user_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FeedRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Get paginated feed posts
  Future<List<PostModel>> getFeedPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    List<String>? followingIds,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true);

      // Filter by following users if provided (for personalized feed)
      if (followingIds != null && followingIds.isNotEmpty) {
        query = query.where('authorId', whereIn: followingIds);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch feed posts: $e');
    }
  }

  // Get posts by specific user
  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  // Create a new post
  Future<PostModel> createPost({
    required String authorId,
    required UserModel author,
    required File imageFile,
    required String caption,
    String? location,
  }) async {
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadPostImage(imageFile);

      // Create post document
      final postData = PostModel(
        id: '', // Will be set by Firestore
        authorId: authorId,
        authorUsername: author.username,
        authorDisplayName: author.displayName,
        authorProfileImageUrl: author.profileImageUrl,
        imageUrl: imageUrl,
        caption: caption,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: author.isVerified,
      );

      final docRef = await _firestore
          .collection('posts')
          .add(postData.toFirestore());

      // Return post with generated ID
      return postData.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Toggle like on a post
  Future<PostModel> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      
      return await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final post = PostModel.fromFirestore(postDoc);
        final updatedPost = post.toggleLike(userId);

        transaction.update(postRef, {
          'likes': updatedPost.likes,
          'updatedAt': Timestamp.fromDate(updatedPost.updatedAt),
        });

        return updatedPost;
      });
    } catch (e) {
      throw Exception('Failed to toggle post like: $e');
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments({
    required String postId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false); // Oldest first for comments

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Add comment to a post
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required UserModel author,
    required String content,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Create comment document
        final commentData = CommentModel(
          id: '', // Will be set by Firestore
          postId: postId,
          authorId: authorId,
          authorUsername: author.username,
          authorDisplayName: author.displayName,
          authorProfileImageUrl: author.profileImageUrl,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: author.isVerified,
        );

        // Add comment to subcollection
        final commentRef = _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc();

        transaction.set(commentRef, commentData.toFirestore());

        // Update post comments count
        final postRef = _firestore.collection('posts').doc(postId);
        transaction.update(postRef, {
          'commentsCount': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        return commentData.copyWith(id: commentRef.id);
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Toggle like on a comment
  Future<CommentModel> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      
      return await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final comment = CommentModel.fromFirestore(commentDoc);
        final updatedComment = comment.toggleLike(userId);

        transaction.update(commentRef, {
          'likes': updatedComment.likes,
          'updatedAt': Timestamp.fromDate(updatedComment.updatedAt),
        });

        return updatedComment;
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        
        // Delete all comments first
        final commentsSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .get();

        for (final commentDoc in commentsSnapshot.docs) {
          transaction.delete(commentDoc.reference);
        }

        // Delete the post
        transaction.delete(postRef);
      });
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Get real-time feed stream
  Stream<List<PostModel>> getFeedStream({
    int limit = 10,
    List<String>? followingIds,
  }) {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true);

      if (followingIds != null && followingIds.isNotEmpty) {
        query = query.where('authorId', whereIn: followingIds);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
    } catch (e) {
      throw Exception('Failed to get feed stream: $e');
    }
  }

  // Helper method to upload post image
  Future<String> _uploadPostImage(File imageFile) async {
    try {
      print('📤 Starting image upload...');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.jpg';
      final ref = _storage.ref().child('posts').child(fileName);
      
      print('📁 Upload path: posts/$fileName');
      
      // Add metadata for better web support
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'pumpkinsocial_app',
          'upload_time': DateTime.now().toIso8601String(),
        },
      );
      
      print('⏳ Uploading to Firebase Storage...');
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('🔄 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      await uploadTask;
      print('✅ Upload complete, getting download URL...');
      
      final downloadURL = await ref.getDownloadURL();
      print('🔗 Download URL: $downloadURL');
      
      return downloadURL;
    } catch (e) {
      print('❌ Image upload failed: $e');
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Storage permission denied. Please check Firebase Storage rules.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error during upload. Please check your connection.');
      } else {
        throw Exception('Failed to upload image: $e');
      }
    }
  }
}
