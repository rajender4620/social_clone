import 'package:flutter/material.dart';

/// Types of animations available for list items
enum AnimationType {
  fadeIn,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scale,
  fadeSlideUp,
  fadeSlideDown,
}

/// An animated wrapper for list items with various animation types
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final AnimationType animationType;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double? slideDistance;
  final double? scaleBegin;
  final bool autoStart;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.animationType = AnimationType.fadeSlideUp,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.slideDistance = 50.0,
    this.scaleBegin = 0.8,
    this.autoStart = true,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeAnimations();

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _initializeAnimations() {
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: widget.scaleBegin ?? 0.8,
      end: 1.0,
    ).animate(curvedAnimation);

    // Slide animation based on type
    Offset beginOffset;
    switch (widget.animationType) {
      case AnimationType.slideUp:
      case AnimationType.fadeSlideUp:
        beginOffset = Offset(0, widget.slideDistance! / 100);
        break;
      case AnimationType.slideDown:
      case AnimationType.fadeSlideDown:
        beginOffset = Offset(0, -widget.slideDistance! / 100);
        break;
      case AnimationType.slideLeft:
        beginOffset = Offset(widget.slideDistance! / 100, 0);
        break;
      case AnimationType.slideRight:
        beginOffset = Offset(-widget.slideDistance! / 100, 0);
        break;
      default:
        beginOffset = Offset.zero;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(curvedAnimation);
  }

  void _startAnimation() {
    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Method to manually trigger animation
  void animate() {
    _controller.forward();
  }

  /// Method to reverse animation
  void reverseAnimate() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget animatedChild = widget.child;

        // Apply animations based on type
        switch (widget.animationType) {
          case AnimationType.fadeIn:
            animatedChild = FadeTransition(
              opacity: _fadeAnimation,
              child: animatedChild,
            );
            break;

          case AnimationType.slideUp:
          case AnimationType.slideDown:
          case AnimationType.slideLeft:
          case AnimationType.slideRight:
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: animatedChild,
            );
            break;

          case AnimationType.scale:
            animatedChild = ScaleTransition(
              scale: _scaleAnimation,
              child: animatedChild,
            );
            break;

          case AnimationType.fadeSlideUp:
          case AnimationType.fadeSlideDown:
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: animatedChild,
              ),
            );
            break;
        }

        return animatedChild;
      },
    );
  }
}

/// A widget that animates its children with staggered delays
class StaggeredAnimatedList extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final AnimationType animationType;
  final Duration duration;
  final Curve curve;
  final double? slideDistance;
  final double? scaleBegin;
  final bool autoStart;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis direction;

  const StaggeredAnimatedList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.animationType = AnimationType.fadeSlideUp,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.slideDistance = 30.0,
    this.scaleBegin = 0.9,
    this.autoStart = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredAnimatedList> createState() => _StaggeredAnimatedListState();
}

class _StaggeredAnimatedListState extends State<StaggeredAnimatedList> {
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: widget.direction,
      mainAxisAlignment: widget.mainAxisAlignment,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return AnimatedListItem(
          animationType: widget.animationType,
          duration: widget.duration,
          delay: widget.staggerDelay * index,
          curve: widget.curve,
          slideDistance: widget.slideDistance,
          scaleBegin: widget.scaleBegin,
          autoStart: widget.autoStart,
          child: child,
        );
      }).toList(),
    );
  }
}

/// A specialized widget for animating posts in the feed
class AnimatedPostItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? customDelay;

  const AnimatedPostItem({
    super.key,
    required this.child,
    required this.index,
    this.customDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedListItem(
      animationType: AnimationType.fadeSlideUp,
      duration: const Duration(milliseconds: 800),
      delay: customDelay ?? Duration(milliseconds: 150 * index),
      curve: Curves.easeOutCubic,
      slideDistance: 40.0,
      scaleBegin: 0.95,
      child: child,
    );
  }
}

/// A specialized widget for animating comments
class AnimatedCommentItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? customDelay;

  const AnimatedCommentItem({
    super.key,
    required this.child,
    required this.index,
    this.customDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedListItem(
      animationType: AnimationType.fadeSlideUp,
      duration: const Duration(milliseconds: 500),
      delay: customDelay ?? Duration(milliseconds: 80 * index),
      curve: Curves.easeOutQuart,
      slideDistance: 25.0,
      scaleBegin: 0.98,
      child: child,
    );
  }
}

/// A widget for animating profile posts grid items
class AnimatedGridItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int crossAxisCount;
  final Duration? customDelay;

  const AnimatedGridItem({
    super.key,
    required this.child,
    required this.index,
    this.crossAxisCount = 3,
    this.customDelay,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate delay based on grid position
    final row = index ~/ crossAxisCount;
    final baseDelay = Duration(milliseconds: 100 * row);
    
    return AnimatedListItem(
      animationType: AnimationType.scale,
      duration: const Duration(milliseconds: 600),
      delay: customDelay ?? baseDelay,
      curve: Curves.easeOutBack,
      scaleBegin: 0.8,
      child: child,
    );
  }
}

/// Extension methods for easy usage
extension AnimatedWidgetExtension on Widget {
  /// Wrap widget with fade-in animation
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) {
    return AnimatedListItem(
      animationType: AnimationType.fadeIn,
      duration: duration,
      delay: delay,
      curve: curve,
      child: this,
    );
  }

  /// Wrap widget with slide-up animation
  Widget slideUp({
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutCubic,
    double slideDistance = 50.0,
  }) {
    return AnimatedListItem(
      animationType: AnimationType.slideUp,
      duration: duration,
      delay: delay,
      curve: curve,
      slideDistance: slideDistance,
      child: this,
    );
  }

  /// Wrap widget with fade + slide-up animation
  Widget fadeSlideUp({
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutCubic,
    double slideDistance = 30.0,
  }) {
    return AnimatedListItem(
      animationType: AnimationType.fadeSlideUp,
      duration: duration,
      delay: delay,
      curve: curve,
      slideDistance: slideDistance,
      child: this,
    );
  }

  /// Wrap widget with scale animation
  Widget scaleIn({
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOutBack,
    double scaleBegin = 0.8,
  }) {
    return AnimatedListItem(
      animationType: AnimationType.scale,
      duration: duration,
      delay: delay,
      curve: curve,
      scaleBegin: scaleBegin,
      child: this,
    );
  }
}
