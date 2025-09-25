import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BookmarkModel extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  const BookmarkModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  // Empty bookmark for initial state
  static final empty = BookmarkModel(
    id: '',
    userId: '',
    postId: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // Check if bookmark is empty
  bool get isEmpty => this == BookmarkModel.empty;
  bool get isNotEmpty => this != BookmarkModel.empty;

  // Factory constructor to create BookmarkModel from Firestore
  factory BookmarkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BookmarkModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
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

  // Convert BookmarkModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with modified fields
  BookmarkModel copyWith({
    String? id,
    String? userId,
    String? postId,
    DateTime? createdAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, postId, createdAt];

  @override
  String toString() {
    return 'BookmarkModel(id: $id, userId: $userId, postId: $postId)';
  }
}
