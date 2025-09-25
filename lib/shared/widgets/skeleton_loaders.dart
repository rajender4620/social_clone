import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoaders {
  /// Creates a shimmer effect container
  static Widget shimmerContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Creates a circular shimmer effect (for profile pictures)
  static Widget shimmerCircle({
    required double diameter,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Creates a text line shimmer effect
  static Widget shimmerText({
    required double width,
    double height = 14,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Skeleton loader for individual posts in the feed
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header Skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile picture
                SkeletonLoaders.shimmerCircle(diameter: 40),
                const SizedBox(width: 12),
                
                // Username and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoaders.shimmerText(width: 120, height: 16),
                      const SizedBox(height: 4),
                      SkeletonLoaders.shimmerText(width: 80, height: 12),
                    ],
                  ),
                ),
                
                // More button
                SkeletonLoaders.shimmerContainer(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),

          // Post Image Skeleton
          SkeletonLoaders.shimmerContainer(
            width: double.infinity,
            height: 300,
            borderRadius: BorderRadius.zero,
          ),

          // Post Actions and Info Skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons row
                Row(
                  children: [
                    SkeletonLoaders.shimmerCircle(diameter: 32),
                    const SizedBox(width: 16),
                    SkeletonLoaders.shimmerCircle(diameter: 32),
                    const SizedBox(width: 16),
                    SkeletonLoaders.shimmerCircle(diameter: 32),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Likes count
                SkeletonLoaders.shimmerText(width: 100, height: 14),
                
                const SizedBox(height: 8),
                
                // Caption lines
                SkeletonLoaders.shimmerText(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                SkeletonLoaders.shimmerText(width: 250, height: 14),
                
                const SizedBox(height: 8),
                
                // Comments and timestamp
                SkeletonLoaders.shimmerText(width: 150, height: 12),
                const SizedBox(height: 4),
                SkeletonLoaders.shimmerText(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for the feed loading state
class FeedSkeleton extends StatelessWidget {
  final int itemCount;
  
  const FeedSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const PostSkeleton(),
    );
  }
}

/// Skeleton loader for profile header
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile picture
              SkeletonLoaders.shimmerCircle(diameter: 90),
              const SizedBox(width: 20),
              
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        SkeletonLoaders.shimmerText(width: 40, height: 20),
                        const SizedBox(height: 4),
                        SkeletonLoaders.shimmerText(width: 60, height: 14),
                      ],
                    ),
                    Column(
                      children: [
                        SkeletonLoaders.shimmerText(width: 40, height: 20),
                        const SizedBox(height: 4),
                        SkeletonLoaders.shimmerText(width: 60, height: 14),
                      ],
                    ),
                    Column(
                      children: [
                        SkeletonLoaders.shimmerText(width: 40, height: 20),
                        const SizedBox(height: 4),
                        SkeletonLoaders.shimmerText(width: 60, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Name and bio
          SkeletonLoaders.shimmerText(width: 150, height: 18),
          const SizedBox(height: 8),
          SkeletonLoaders.shimmerText(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          SkeletonLoaders.shimmerText(width: 200, height: 14),
          
          const SizedBox(height: 16),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: SkeletonLoaders.shimmerContainer(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              SkeletonLoaders.shimmerContainer(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for profile posts grid
class ProfilePostsGridSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ProfilePostsGridSkeleton({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => SkeletonLoaders.shimmerContainer(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.zero,
        ),
        childCount: itemCount,
      ),
    );
  }
}

/// Skeleton loader for comments
class CommentSkeleton extends StatelessWidget {
  const CommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          SkeletonLoaders.shimmerCircle(diameter: 32),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoaders.shimmerText(width: 80, height: 14),
                    const SizedBox(width: 8),
                    SkeletonLoaders.shimmerText(width: 40, height: 12),
                  ],
                ),
                const SizedBox(height: 4),
                SkeletonLoaders.shimmerText(width: double.infinity, height: 14),
                const SizedBox(height: 2),
                SkeletonLoaders.shimmerText(width: 150, height: 14),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonLoaders.shimmerText(width: 30, height: 12),
                    const SizedBox(width: 16),
                    SkeletonLoaders.shimmerText(width: 40, height: 12),
                    const SizedBox(width: 16),
                    SkeletonLoaders.shimmerText(width: 35, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for multiple comments
class CommentsSkeleton extends StatelessWidget {
  final int itemCount;
  
  const CommentsSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const CommentSkeleton(),
      ),
    );
  }
}
