import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorDisplayName;
  final String? authorProfileImageUrl;
  final String imageUrl;
  final String caption;
  final String? location;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Author verification status

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorDisplayName,
    this.authorProfileImageUrl,
    required this.imageUrl,
    required this.caption,
    this.location,
    this.likes = const [],
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  // Empty post for initial state
  static final empty = PostModel(
    id: '',
    authorId: '',
    authorUsername: '',
    imageUrl: '',
    caption: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Check if post is empty
  bool get isEmpty => this == PostModel.empty;
  bool get isNotEmpty => this != PostModel.empty;

  // Getters for engagement metrics
  int get likesCount => likes.length;
  bool hasLikeFrom(String userId) => likes.contains(userId);

  // Display name or fallback to username
  String get displayAuthorName => authorDisplayName ?? authorUsername;

  // Factory constructor to create PostModel from Firestore
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorDisplayName: data['authorDisplayName'],
      authorProfileImageUrl: data['authorProfileImageUrl'],
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      location: data['location'],
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
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

  // Convert PostModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorProfileImageUrl': authorProfileImageUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  // Create a copy with modified fields
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorDisplayName,
    String? authorProfileImageUrl,
    String? imageUrl,
    String? caption,
    String? location,
    List<String>? likes,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorProfileImageUrl: authorProfileImageUrl ?? this.authorProfileImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Toggle like for a user
  PostModel toggleLike(String userId) {
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

  // Update comments count
  PostModel updateCommentsCount(int newCount) {
    return copyWith(
      commentsCount: newCount,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorUsername,
        authorDisplayName,
        authorProfileImageUrl,
        imageUrl,
        caption,
        location,
        likes,
        commentsCount,
        createdAt,
        updatedAt,
        isVerified,
      ];

  @override
  String toString() {
    return 'PostModel(id: $id, authorUsername: $authorUsername, caption: ${caption.length > 50 ? caption.substring(0, 50) + "..." : caption}, likesCount: $likesCount, commentsCount: $commentsCount)';
  }
}
