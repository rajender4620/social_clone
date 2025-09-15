import 'package:flutter/material.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Post Details Screen')));
  }
}
