import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String? id;
  final String? authorId;
  final String? content;
  final String? mediaUrl;
  final String? userProfilePicture;
  final String? createdAt;
  final String? updatedAt;
  final int? likesCount;
  final int? commentsCount;

  const Post({
    this.id,
    this.authorId,
    this.content,
    this.mediaUrl,
    this.userProfilePicture,
    this.createdAt,
    this.updatedAt,
    this.likesCount,
    this.commentsCount,
  });

  @override
  List<Object?> get props => [
    id,
    authorId,
    content,
    mediaUrl,
    userProfilePicture,
    createdAt,
    updatedAt,
    likesCount,
    commentsCount,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'content': content,
      'mediaUrl': mediaUrl,
      'userProfilePicture': userProfilePicture,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      authorId: json['authorId'],
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      userProfilePicture: json['userProfilePicture'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      likesCount: json['likesCount'],
      commentsCount: json['commentsCount'],
    );
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? content,
    String? mediaUrl,
    String? userProfilePicture,
    String? createdAt,
    String? updatedAt,
    int? likesCount,
    int? commentsCount,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
