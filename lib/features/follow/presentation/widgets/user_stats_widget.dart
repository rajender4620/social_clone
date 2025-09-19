import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/follow_bloc.dart';
import '../bloc/follow_event.dart';
import '../bloc/follow_state.dart';

class UserStatsWidget extends StatelessWidget {
  final String userId;
  final VoidCallback? onPostsTapped;
  final VoidCallback? onFollowersTapped;
  final VoidCallback? onFollowingTapped;

  const UserStatsWidget({
    super.key,
    required this.userId,
    this.onPostsTapped,
    this.onFollowersTapped,
    this.onFollowingTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FollowBloc(
        followRepository: context.read(),
        authBloc: context.read(),
      )..add(UserStatsLoadRequested(userId: userId)),
      child: _UserStatsView(
        onPostsTapped: onPostsTapped,
        onFollowersTapped: onFollowersTapped,
        onFollowingTapped: onFollowingTapped,
      ),
    );
  }
}

class _UserStatsView extends StatelessWidget {
  final VoidCallback? onPostsTapped;
  final VoidCallback? onFollowersTapped;
  final VoidCallback? onFollowingTapped;

  const _UserStatsView({
    this.onPostsTapped,
    this.onFollowersTapped,
    this.onFollowingTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FollowBloc, FollowState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _LoadingStats();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              label: 'Posts',
              count: state.postsCount,
              onTap: onPostsTapped,
            ),
            _StatItem(
              label: 'Followers',
              count: state.followersCount,
              onTap: onFollowersTapped,
            ),
            _StatItem(
              label: 'Following',
              count: state.followingCount,
              onTap: onFollowingTapped,
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: onTap != null 
            ? theme.colorScheme.primary.withOpacity(0.05)
            : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCount(count),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }
}

class _LoadingStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LoadingStatItem(theme: theme),
        _LoadingStatItem(theme: theme),
        _LoadingStatItem(theme: theme),
      ],
    );
  }
}

class _LoadingStatItem extends StatelessWidget {
  final ThemeData theme;

  const _LoadingStatItem({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// Simple version without BlocProvider (for use when FollowBloc is already provided)
class SimpleUserStatsWidget extends StatelessWidget {
  final VoidCallback? onPostsTapped;
  final VoidCallback? onFollowersTapped;
  final VoidCallback? onFollowingTapped;

  const SimpleUserStatsWidget({
    super.key,
    this.onPostsTapped,
    this.onFollowersTapped,
    this.onFollowingTapped,
  });

  @override
  Widget build(BuildContext context) {
    return _UserStatsView(
      onPostsTapped: onPostsTapped,
      onFollowersTapped: onFollowersTapped,
      onFollowingTapped: onFollowingTapped,
    );
  }
}

// Compact version for smaller spaces
class CompactUserStats extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final VoidCallback? onFollowersTapped;
  final VoidCallback? onFollowingTapped;

  const CompactUserStats({
    super.key,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.onFollowersTapped,
    this.onFollowingTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        GestureDetector(
          onTap: onFollowersTapped,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatCount(followersCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' followers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onFollowingTapped,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatCount(followingCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' following',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }
}
