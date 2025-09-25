import 'package:flutter/services.dart';

/// Service for managing haptic feedback throughout the app
class HapticService {
  HapticService._();
  
  /// Light impact haptic feedback - for subtle interactions like button taps
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Medium impact haptic feedback - for medium interactions like toggles
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Heavy impact haptic feedback - for strong interactions like long press
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Selection click haptic feedback - for picker/selector interactions
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Vibrate pattern for success actions (like successful post upload)
  static Future<void> success() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Vibrate pattern for error actions
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback might not be available on all devices
      // Fail silently
    }
  }
  
  /// Haptic feedback for like actions (posts, comments)
  static Future<void> like() async {
    await mediumImpact();
  }
  
  /// Haptic feedback for unlike actions
  static Future<void> unlike() async {
    await lightImpact();
  }
  
  /// Haptic feedback for follow actions
  static Future<void> follow() async {
    await mediumImpact();
  }
  
  /// Haptic feedback for unfollow actions
  static Future<void> unfollow() async {
    await lightImpact();
  }
  
  /// Haptic feedback for comment submission
  static Future<void> comment() async {
    await lightImpact();
  }
  
  /// Haptic feedback for post creation success
  static Future<void> postCreated() async {
    await success();
  }
  
  /// Haptic feedback for navigation actions
  static Future<void> navigation() async {
    await lightImpact();
  }
  
  /// Haptic feedback for button press
  static Future<void> buttonPress() async {
    await lightImpact();
  }
  
  /// Haptic feedback for refresh action
  static Future<void> refresh() async {
    await selectionClick();
  }
}
