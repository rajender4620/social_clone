import 'package:flutter/material.dart';

/// Types of snackbars available
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Service for showing enhanced snackbars throughout the app
class SnackbarService {
  SnackbarService._();

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context,
      message,
      SnackbarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context,
      message,
      SnackbarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context,
      message,
      SnackbarType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context,
      message,
      SnackbarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Internal method to show the snackbar
  static void _showSnackbar(
    BuildContext context,
    String message,
    SnackbarType type, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final theme = Theme.of(context);
    final config = _getSnackbarConfig(type, theme);

    final snackBar = SnackBar(
      content: _SnackbarContent(
        message: message,
        icon: config.icon,
        iconColor: config.iconColor,
      ),
      backgroundColor: config.backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 8,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: config.actionTextColor,
              onPressed: onActionPressed ?? () {},
            )
          : null,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Get configuration for different snackbar types
  static _SnackbarConfig _getSnackbarConfig(SnackbarType type, ThemeData theme) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarConfig(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF4CAF50), // Green
          actionTextColor: Colors.white,
        );

      case SnackbarType.error:
        return _SnackbarConfig(
          icon: Icons.error_rounded,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFFF44336), // Red
          actionTextColor: Colors.white,
        );

      case SnackbarType.warning:
        return _SnackbarConfig(
          icon: Icons.warning_rounded,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFFFF9800), // Orange
          actionTextColor: Colors.white,
        );

      case SnackbarType.info:
        return _SnackbarConfig(
          icon: Icons.info_rounded,
          iconColor: Colors.white,
          backgroundColor: theme.colorScheme.primary,
          actionTextColor: Colors.white,
        );
    }
  }
}

/// Configuration for different snackbar types
class _SnackbarConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color actionTextColor;

  const _SnackbarConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.actionTextColor,
  });
}

/// Custom snackbar content widget with icon and message
class _SnackbarContent extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const _SnackbarContent({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_SnackbarContent> createState() => _SnackbarContentState();
}

class _SnackbarContentState extends State<_SnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Message
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extensions for easy usage
extension SnackbarContextExtension on BuildContext {
  /// Show success snackbar
  void showSuccessSnackbar(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    SnackbarService.showSuccess(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show error snackbar
  void showErrorSnackbar(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    SnackbarService.showError(
      this,
      message,
      duration: duration ?? const Duration(seconds: 4),
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show warning snackbar
  void showWarningSnackbar(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    SnackbarService.showWarning(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show info snackbar
  void showInfoSnackbar(
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    SnackbarService.showInfo(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }
}
