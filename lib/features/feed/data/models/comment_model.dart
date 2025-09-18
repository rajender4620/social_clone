import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorDisplayName;
  final String? authorProfileImageUrl;
  final String content;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Author verification status

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorDisplayName,
    this.authorProfileImageUrl,
    required this.content,
    this.likes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  // Empty comment for initial state
  static final empty = CommentModel(
    id: '',
    postId: '',
    authorId: '',
    authorUsername: '',
    content: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Check if comment is empty
  bool get isEmpty => this == CommentModel.empty;
  bool get isNotEmpty => this != CommentModel.empty;

  // Getters for engagement metrics
  int get likesCount => likes.length;
  bool hasLikeFrom(String userId) => likes.contains(userId);

  // Display name or fallback to username
  String get displayAuthorName => authorDisplayName ?? authorUsername;

  // Factory constructor to create CommentModel from Firestore
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorDisplayName: data['authorDisplayName'],
      authorProfileImageUrl: data['authorProfileImageUrl'],
      content: data['content'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isVerified: data['isVerified'] ?? false,
    );
  }

  // Helper method to safely parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  // Convert CommentModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorProfileImageUrl': authorProfileImageUrl,
      'content': content,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  // Create a copy with modified fields
  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorUsername,
    String? authorDisplayName,
    String? authorProfileImageUrl,
    String? content,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorProfileImageUrl: authorProfileImageUrl ?? this.authorProfileImageUrl,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Toggle like for a user
  CommentModel toggleLike(String userId) {
    final newLikes = List<String>.from(likes);
    if (newLikes.contains(userId)) {
      newLikes.remove(userId);
    } else {
      newLikes.add(userId);
    }
    
    return copyWith(
      likes: newLikes,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorUsername,
        authorDisplayName,
        authorProfileImageUrl,
        content,
        likes,
        createdAt,
        updatedAt,
        isVerified,
      ];

  @override
  String toString() {
    return 'CommentModel(id: $id, authorUsername: $authorUsername, content: ${content.length > 30 ? content.substring(0, 30) + "..." : content}, likesCount: $likesCount)';
  }
}
