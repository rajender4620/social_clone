import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../../auth/data/models/user_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FeedRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
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

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
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

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
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

      // Ensure we have proper user data with fallbacks
      final validatedAuthor = _validateUserDataForComment(author);

      // Create post document
      final postData = PostModel(
        id: '', // Will be set by Firestore
        authorId: authorId,
        authorUsername: validatedAuthor['username']!,
        authorDisplayName: validatedAuthor['displayName'],
        authorProfileImageUrl: validatedAuthor['profileImageUrl'],
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
        // Ensure we have proper user data with fallbacks
        final validatedAuthor = _validateUserDataForComment(author);

        // Create comment document
        final commentData = CommentModel(
          id: '', // Will be set by Firestore
          postId: postId,
          authorId: authorId,
          authorUsername: validatedAuthor['username']!,
          authorDisplayName: validatedAuthor['displayName'],
          authorProfileImageUrl: validatedAuthor['profileImageUrl'],
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: author.isVerified,
        );

        // Add comment to subcollection
        final commentRef =
            _firestore
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
      print('❌ Failed to add comment: $e');
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
        final commentsSnapshot =
            await _firestore
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

      return query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
      );
    } catch (e) {
      throw Exception('Failed to get feed stream: $e');
    }
  }

  // Helper method to upload post image
  Future<String> _uploadPostImage(File imageFile) async {
    try {
      print('📤 Starting image upload...');
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.jpg';
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
        throw Exception(
          'Storage permission denied. Please check Firebase Storage rules.',
        );
      } else if (e.toString().contains('network')) {
        throw Exception(
          'Network error during upload. Please check your connection.',
        );
      } else {
        throw Exception('Failed to upload image: $e');
      }
    }
  }

  // Bookmark functionality

  // Toggle bookmark on a post
  Future<bool> togglePostBookmark({
    required String postId,
    required String userId,
  }) async {
    try {
      final bookmarkRef = _firestore
          .collection('bookmarks')
          .doc('${userId}_$postId');

      return await _firestore.runTransaction((transaction) async {
        final bookmarkDoc = await transaction.get(bookmarkRef);

        if (bookmarkDoc.exists) {
          // Remove bookmark
          transaction.delete(bookmarkRef);
          print('✅ Removed bookmark');
          return false;
        } else {
          // Add bookmark
          transaction.set(bookmarkRef, {
            'userId': userId,
            'postId': postId,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
          print('✅ Added bookmark');
          return true;
        }
      });
    } catch (e) {
      print('❌ Failed to toggle bookmark: $e');
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Check if post is bookmarked by user
  Future<bool> isPostBookmarked({
    required String postId,
    required String userId,
  }) async {
    try {
      final docId = '${userId}_$postId';
      print('🔍 Checking bookmark document: $docId');

      final bookmarkDoc =
          await _firestore.collection('bookmarks').doc(docId).get();

      final exists = bookmarkDoc.exists;
      print('📌 Bookmark exists: $exists');
      return exists;
    } catch (e) {
      print('❌ Failed to check bookmark status: $e');
      throw Exception('Failed to check bookmark status: $e');
    }
  }

  // Get user's bookmarked posts
  Future<List<PostModel>> getBookmarkedPosts({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query bookmarkQuery = _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        bookmarkQuery = bookmarkQuery.startAfterDocument(lastDocument);
      }

      bookmarkQuery = bookmarkQuery.limit(limit);

      final bookmarkSnapshot = await bookmarkQuery.get();

      if (bookmarkSnapshot.docs.isEmpty) {
        return [];
      }

      // Get the post IDs from bookmarks
      final postIds =
          bookmarkSnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['postId'] as String,
              )
              .toList();

      // Fetch the actual posts
      final posts = <PostModel>[];
      for (final postId in postIds) {
        try {
          final postDoc =
              await _firestore.collection('posts').doc(postId).get();
          if (postDoc.exists) {
            posts.add(PostModel.fromFirestore(postDoc));
          }
        } catch (e) {
          // Skip posts that no longer exist
          continue;
        }
      }

      return posts;
    } catch (e) {
      print('❌ Failed to fetch bookmarked posts: $e');
      throw Exception('Failed to fetch bookmarked posts: $e');
    }
  }

  // Get bookmark status for multiple posts
  Future<Map<String, bool>> getBookmarkStatusForPosts({
    required List<String> postIds,
    required String userId,
  }) async {
    try {
      final results = <String, bool>{};

      for (final postId in postIds) {
        final isBookmarked = await isPostBookmarked(
          postId: postId,
          userId: userId,
        );
        results[postId] = isBookmarked;
      }

      return results;
    } catch (e) {
      print('❌ Failed to get bookmark statuses: $e');
      throw Exception('Failed to get bookmark statuses: $e');
    }
  }

  // Helper method to validate and provide fallbacks for user data in comments
  Map<String, String?> _validateUserDataForComment(UserModel author) {
    // Ensure username is not empty
    String username = author.username.trim();
    if (username.isEmpty) {
      // Generate username from email as fallback
      username = _generateUsernameFromEmail(author.email);
    }

    // Provide displayName fallback
    String? displayName = author.displayName?.trim();
    if (displayName == null || displayName.isEmpty) {
      // Use email prefix as display name fallback
      displayName = _generateDisplayNameFromEmail(author.email);
    }

    // Provide default profile image fallback
    String? profileImageUrl = author.profileImageUrl;
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      // Use a default avatar or avatar service
      profileImageUrl = _getDefaultAvatarUrl(username);
    }

    return {
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Generate username from email
  String _generateUsernameFromEmail(String email) {
    final emailPrefix = email.split('@')[0];
    final cleanUsername = emailPrefix.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_]'),
      '_',
    );
    return cleanUsername.isEmpty
        ? 'user_${DateTime.now().millisecondsSinceEpoch}'
        : cleanUsername;
  }

  // Generate display name from email
  String _generateDisplayNameFromEmail(String email) {
    final emailPrefix = email.split('@')[0];
    // Capitalize first letter and replace dots/underscores with spaces
    final cleanName = emailPrefix.replaceAll(RegExp(r'[._]'), ' ');
    return cleanName
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
        )
        .where((word) => word.isNotEmpty)
        .join(' ');
  }

  // Get default avatar URL (using a free avatar service)
  String _getDefaultAvatarUrl(String identifier) {
    // Using DiceBear API for consistent, deterministic avatars
    // You can also use other services like Gravatar, Identicon, etc.
    return 'https://api.dicebear.com/7.x/initials/svg?seed=${Uri.encodeComponent(identifier)}&backgroundColor=6366f1&textColor=ffffff';
  }
}
