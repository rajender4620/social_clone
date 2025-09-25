import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom refresh indicator with branded design and smooth animations
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final double displacement;
  final double edgeOffset;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      edgeOffset: edgeOffset,
      backgroundColor: theme.colorScheme.surface,
      color: primaryColor,
      strokeWidth: 3.0,
      // Custom refresh indicator builder
      child: child,
      // We'll use a NotificationListener to add our custom indicator
    );
  }
}

/// A more advanced custom refresh indicator with gradient and icons
class EnhancedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double displacement;
  final double edgeOffset;

  const EnhancedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.primaryColor,
    this.secondaryColor,
    this.displacement = 60.0,
    this.edgeOffset = 0.0,
  });

  @override
  State<EnhancedRefreshIndicator> createState() => _EnhancedRefreshIndicatorState();
}

class _EnhancedRefreshIndicatorState extends State<EnhancedRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _iconController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _iconRotation;
  
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    ));

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();
    _iconController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      _iconController.stop();
      _refreshController.reverse();
      
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      backgroundColor: Colors.transparent,
      color: Colors.transparent,
      strokeWidth: 0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Handle custom refresh indicator positioning and animation
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            
            // Custom refresh indicator overlay
            if (_isRefreshing)
              Positioned(
                top: widget.displacement + widget.edgeOffset,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _refreshAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _refreshAnimation.value,
                        child: _CustomRefreshWidget(
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          iconRotation: _iconRotation,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The actual custom refresh widget with beautiful design
class _CustomRefreshWidget extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Animation<double> iconRotation;

  const _CustomRefreshWidget({
    required this.primaryColor,
    required this.secondaryColor,
    required this.iconRotation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: iconRotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: iconRotation.value,
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}

/// Simpler branded refresh indicator
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final double displacement;
  final double edgeOffset;
  final String? refreshText;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.refreshText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      edgeOffset: edgeOffset,
      backgroundColor: theme.colorScheme.surface,
      color: primaryColor,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}

/// Pull-to-refresh with custom animation and branding
class PumpkinRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? primaryColor;
  final double displacement;
  final double edgeOffset;

  const PumpkinRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.primaryColor,
    this.displacement = 50.0,
    this.edgeOffset = 0.0,
  });

  @override
  State<PumpkinRefreshIndicator> createState() => _PumpkinRefreshIndicatorState();
}

class _PumpkinRefreshIndicatorState extends State<PumpkinRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _controller.forward();
    try {
      await widget.onRefresh();
    } finally {
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;

    return RefreshIndicator.adaptive(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
      color: primaryColor,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: widget.child,
    );
  }
}

/// Extension for easy usage throughout the app
extension RefreshIndicatorExtension on Widget {
  /// Wrap widget with custom refresh indicator
  Widget withCustomRefresh(
    Future<void> Function() onRefresh, {
    Color? color,
    double displacement = 40.0,
    double edgeOffset = 0.0,
  }) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: this,
    );
  }

  /// Wrap widget with branded refresh indicator
  Widget withBrandedRefresh(
    Future<void> Function() onRefresh, {
    Color? color,
    double displacement = 40.0,
    double edgeOffset = 0.0,
  }) {
    return BrandedRefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: this,
    );
  }

  /// Wrap widget with pumpkin-themed refresh indicator
  Widget withPumpkinRefresh(
    Future<void> Function() onRefresh, {
    Color? primaryColor,
    double displacement = 50.0,
    double edgeOffset = 0.0,
  }) {
    return PumpkinRefreshIndicator(
      onRefresh: onRefresh,
      primaryColor: primaryColor,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: this,
    );
  }
}
