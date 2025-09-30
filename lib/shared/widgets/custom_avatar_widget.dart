import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final String username;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const CustomAvatarWidget({
    super.key,
    this.imageUrl,
    this.displayName,
    required this.username,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Generate initials from display name or username
    final initials = _generateInitials(displayName ?? username);
    
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.8);
    final defaultTextColor = textColor ?? Colors.white;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: defaultBackgroundColor,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: defaultTextColor,
                fontSize: radius * 0.6, // Scale font size with avatar size
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            )
          : null,
    );

    // Add loading and error handling for cached network image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: defaultBackgroundColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: radius * 2,
              height: radius * 2,
              color: defaultBackgroundColor.withOpacity(0.3),
              child: Center(
                child: SizedBox(
                  width: radius * 0.5,
                  height: radius * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: radius * 2,
              height: radius * 2,
              color: defaultBackgroundColor,
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: defaultTextColor,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add tap functionality if provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  /// Generate initials from a name string
  String _generateInitials(String name) {
    if (name.isEmpty) return '?';
    
    // Split by spaces and take first letter of each word
    final words = name.trim().split(RegExp(r'\s+'));
    
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      // Single word - take first letter, or first 2 if it's long enough
      final word = words[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.substring(0, 1).toUpperCase();
    } else {
      // Multiple words - take first letter of first two words
      return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
    }
  }

  /// Small avatar (16px radius) - for comments, small lists
  static CustomAvatarWidget small({
    Key? key,
    String? imageUrl,
    String? displayName,
    required String username,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return CustomAvatarWidget(
      key: key,
      imageUrl: imageUrl,
      displayName: displayName,
      username: username,
      radius: 16,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
    );
  }

  /// Medium avatar (24px radius) - for navigation, medium lists
  static CustomAvatarWidget medium({
    Key? key,
    String? imageUrl,
    String? displayName,
    required String username,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return CustomAvatarWidget(
      key: key,
      imageUrl: imageUrl,
      displayName: displayName,
      username: username,
      radius: 24,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
    );
  }

  /// Large avatar (45px radius) - for profiles, detailed views
  static CustomAvatarWidget large({
    Key? key,
    String? imageUrl,
    String? displayName,
    required String username,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return CustomAvatarWidget(
      key: key,
      imageUrl: imageUrl,
      displayName: displayName,
      username: username,
      radius: 45,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
    );
  }

  /// Extra large avatar (60px radius) - for main profile pages
  static CustomAvatarWidget extraLarge({
    Key? key,
    String? imageUrl,
    String? displayName,
    required String username,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return CustomAvatarWidget(
      key: key,
      imageUrl: imageUrl,
      displayName: displayName,
      username: username,
      radius: 60,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onTap: onTap,
    );
  }
}
