import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/follow_bloc.dart';
import '../bloc/follow_event.dart';
import '../bloc/follow_state.dart';

class FollowButton extends StatelessWidget {
  final String targetUserId;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.width,
    this.height = 32,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FollowBloc(
        followRepository: context.read(),
        authBloc: context.read(),
      )..add(FollowStatusCheckRequested(targetUserId: targetUserId)),
      child: _FollowButtonView(
        targetUserId: targetUserId,
        width: width,
        height: height,
        padding: padding,
      ),
    );
  }
}

class _FollowButtonView extends StatelessWidget {
  final String targetUserId;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const _FollowButtonView({
    required this.targetUserId,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<FollowBloc, FollowState>(
      listener: (context, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
          // Clear error after showing
          context.read<FollowBloc>().add(const FollowErrorCleared());
        }
      },
      builder: (context, state) {
        if (state.isFollowStatusUnknown) {
          return _LoadingButton(
            width: width,
            height: height,
            padding: padding,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildButton(context, state, theme),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, FollowState state, ThemeData theme) {
    if (state.isFollowButtonLoading) {
      return _LoadingButton(
        width: width,
        height: height,
        padding: padding,
      );
    }

    if (state.isFollowing) {
      return _FollowingButton(
        onPressed: () => _onButtonPressed(context),
        width: width,
        height: height,
        padding: padding,
        theme: theme,
      );
    } else {
      return _FollowButton(
        onPressed: () => _onButtonPressed(context),
        width: width,
        height: height,
        padding: padding,
        theme: theme,
      );
    }
  }

  void _onButtonPressed(BuildContext context) {
    context.read<FollowBloc>().add(
      FollowToggleRequested(targetUserId: targetUserId),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ThemeData theme;

  const _FollowButton({
    required this.onPressed,
    this.width,
    this.height,
    this.padding,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FollowingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ThemeData theme;

  const _FollowingButton({
    required this.onPressed,
    this.width,
    this.height,
    this.padding,
    required this.theme,
  });

  @override
  State<_FollowingButton> createState() => _FollowingButtonState();
}

class _FollowingButtonState extends State<_FollowingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _isHovered 
              ? Colors.red.withOpacity(0.1)
              : Colors.transparent,
            foregroundColor: _isHovered 
              ? Colors.red 
              : widget.theme.colorScheme.onSurface,
            side: BorderSide(
              color: _isHovered 
                ? Colors.red 
                : widget.theme.dividerColor,
              width: 1,
            ),
            elevation: 0,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHovered ? Icons.person_remove : Icons.check,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _isHovered ? 'Unfollow' : 'Following',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingButton extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const _LoadingButton({
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.dividerColor),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// Simple follow button without BlocProvider (for use when FollowBloc is already provided)
class SimpleFollowButton extends StatelessWidget {
  final String targetUserId;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const SimpleFollowButton({
    super.key,
    required this.targetUserId,
    this.width,
    this.height = 32,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return _FollowButtonView(
      targetUserId: targetUserId,
      width: width,
      height: height,
      padding: padding,
    );
  }
}
