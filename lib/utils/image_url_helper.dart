import 'package:flutter/foundation.dart';

/// Fixes image URLs so they resolve correctly on all platforms:
/// - Web: uses 127.0.0.1
/// - Android Emulator: uses 10.0.2.2 (proxy to host machine)
/// - Linux/macOS/Windows/iOS Simulator: uses 127.0.0.1
String fixImageUrl(String url) {
  // Only Android emulator needs the 10.0.2.2 workaround
  final bool needsEmulatorProxy =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  if (url.startsWith('http')) {
    if (needsEmulatorProxy) {
      // Android emulator: replace localhost/127.0.0.1 with 10.0.2.2
      if (url.contains('127.0.0.1')) {
        return url.replaceFirst('127.0.0.1', '10.0.2.2');
      }
      if (url.contains('localhost')) {
        return url.replaceFirst('localhost', '10.0.2.2');
      }
    } else if (!needsEmulatorProxy && url.contains('10.0.2.2')) {
      // Non-Android platforms: fix any 10.0.2.2 URLs back to 127.0.0.1
      return url.replaceFirst('10.0.2.2', '127.0.0.1');
    }
    return url;
  } else {
    // Relative URL — prepend the correct base
    String base = needsEmulatorProxy
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
    return '$base$url';
  }
}
