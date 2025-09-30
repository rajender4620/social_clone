import 'dart:io';
import 'package:video_player/video_player.dart';

class VideoControllerManager {
  static final VideoControllerManager _instance = VideoControllerManager._internal();
  factory VideoControllerManager() => _instance;
  VideoControllerManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _usageCount = {};

  /// Get or create a video controller for the given URL
  Future<VideoPlayerController> getController(String videoUrl) async {
    // If controller already exists, check if it's still valid
    if (_controllers.containsKey(videoUrl)) {
      final controller = _controllers[videoUrl]!;
      
      // Check if controller is still valid and initialized
      if (controller.value.isInitialized) {
        _usageCount[videoUrl] = (_usageCount[videoUrl] ?? 0) + 1;
        return controller;
      } else {
        // Controller is invalid, remove it and create new one
        controller.dispose();
        _controllers.remove(videoUrl);
        _usageCount.remove(videoUrl);
      }
    }

    // Create new controller
    late VideoPlayerController controller;
    
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    } else {
      controller = VideoPlayerController.file(File(videoUrl));
    }

    // Initialize the controller
    await controller.initialize();
    
    // Cache it
    _controllers[videoUrl] = controller;
    _usageCount[videoUrl] = 1;
    
    return controller;
  }

  /// Force refresh a controller (useful for app lifecycle issues and stale buffer clearing)
  Future<VideoPlayerController?> refreshController(String videoUrl) async {
    // Remove existing controller
    if (_controllers.containsKey(videoUrl)) {
      final oldController = _controllers[videoUrl]!;
      final currentUsage = _usageCount[videoUrl] ?? 0;
      
      print('🔄 Refreshing controller to clear stale surface buffers');
      
      // Properly pause and dispose to clear stale buffers
      try {
        if (oldController.value.isPlaying) {
          await oldController.pause();
        }
        
        // Wait longer to ensure all surfaces and buffers are cleared
        await Future.delayed(const Duration(milliseconds: 200));
        
        await oldController.dispose();
        print('🗑️ Disposed old controller with stale buffers');
      } catch (e) {
        print('Warning: Error during controller cleanup: $e');
      }
      
      _controllers.remove(videoUrl);
      _usageCount.remove(videoUrl);
      
      // Additional wait to ensure Android surfaces are completely released
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Create new controller if it was being used
      if (currentUsage > 0) {
        try {
          final newController = await getController(videoUrl);
          _usageCount[videoUrl] = currentUsage; // Restore usage count
          print('✅ Created fresh controller with clean surface');
          return newController;
        } catch (e) {
          print('❌ Failed to refresh controller: $e');
          return null;
        }
      }
    }
    return null;
  }

  /// Release a video controller (decrement usage count)
  void releaseController(String videoUrl) {
    if (_controllers.containsKey(videoUrl)) {
      final currentCount = _usageCount[videoUrl] ?? 0;
      if (currentCount <= 1) {
        // No more users, dispose and remove
        _controllers[videoUrl]?.dispose();
        _controllers.remove(videoUrl);
        _usageCount.remove(videoUrl);
      } else {
        // Still has users, just decrement count
        _usageCount[videoUrl] = currentCount - 1;
      }
    }
  }

  /// Pause all videos
  void pauseAll() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  /// Clean up controllers that haven't been used recently
  void cleanup() {
    final toRemove = <String>[];
    for (final entry in _usageCount.entries) {
      if (entry.value <= 0) {
        toRemove.add(entry.key);
      }
    }
    
    for (final url in toRemove) {
      _controllers[url]?.dispose();
      _controllers.remove(url);
      _usageCount.remove(url);
    }
  }

  /// Dispose all controllers (call this when app is closing)
  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _usageCount.clear();
  }
  
  /// Refresh all active controllers to fix potential stale surface issues after app resume
  Future<void> refreshAllActiveControllers() async {
    final activeUrls = _usageCount.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
        
    if (activeUrls.isEmpty) return;
    
    print('🔄 Refreshing ${activeUrls.length} active controllers to fix stale surfaces');
    
    for (final url in activeUrls) {
      try {
        await refreshController(url);
      } catch (e) {
        print('❌ Failed to refresh controller for $url: $e');
      }
    }
    
    print('✅ Completed refreshing all active controllers');
  }
}
