import 'package:firebase_auth/firebase_auth.dart';
import 'package:pumpkin/data_model/model/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedService {
  // TODO: Replace with actual API calls to your backend

  final _firebase = FirebaseFirestore.instance;

  final String POST = 'posts';

  Future<List<Post>> fetchPosts({int page = 0, int limit = 10}) async {
    final posts =
        await _firebase
            .collection(POST)
            .orderBy('createdAt', descending: true)
            .withConverter(
              fromFirestore:
                  (snapshot, options) => Post.fromJson(snapshot.data()!),
              toFirestore: (value, options) => value.toJson(),
            )
            .limit(10)
            .get();

    return posts.docs.map((pos) => pos.data()).toList();

    // // Simulate API delay
    // await Future.delayed(const Duration(milliseconds: 800));

    // // Mock data for now - replace with actual API calls
    // return _generateMockPosts(page: page, limit: limit);
  }

  Future<List<Post>> refreshPosts({int limit = 10}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Return fresh posts - replace with actual API calls
    return _generateMockPosts(page: 0, limit: limit);
  }

  List<Post> _generateMockPosts({required int page, required int limit}) {
    final startIndex = page * limit;
    return List.generate(limit, (index) {
      final postIndex = startIndex + index;
      return Post(
        id: 'post_$postIndex',
        content:
            'This is mock post #$postIndex ex: Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        authorId: 'user_${postIndex % 5}',
        mediaUrl: null,
        userProfilePicture: null,
        createdAt:
            DateTime.now()
                .subtract(Duration(hours: postIndex))
                .toIso8601String(),
        updatedAt:
            DateTime.now()
                .subtract(Duration(hours: postIndex))
                .toIso8601String(),
        likesCount: 0,
        commentsCount: 0,
      );
    });
  }

  Future<void> createPost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final docRef =
        _firebase.collection(POST).doc(); // generates ID without writing

    final post = Post(
      id: docRef.id,
      authorId: currentUser?.uid,
      content:
          'This is a test post Datetime: ${DateTime.now().toIso8601String()}',
      mediaUrl: null,
      userProfilePicture: currentUser?.photoURL,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      likesCount: 0,
      commentsCount: 0,
    );

    await docRef.set(post.toJson()); // write once
  }

  Future<void> updatePost() async {
    final upDatepost = Post(
      content: 'This is a upadeting post',
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _firebase.collection(POST).doc('La9xVDMCFvoFYi6MkYMj').update({
      'content': upDatepost.content,
      'updatedAt': upDatepost.updatedAt,
    });
  }

  Future<void> deletePost() async {
    await _firebase.collection(POST).doc('La9xVDMCFvoFYi6MkYMj').delete();
  }

  Future<void> getPostById(String id) async {
    final post = await _firebase.collection(POST).doc(id).get();
    print(post.data());
  }
}
