import 'package:flutter/material.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';

class FeedLoadingWidget extends StatelessWidget {
  const FeedLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeedSkeleton(itemCount: 4);
  }
}