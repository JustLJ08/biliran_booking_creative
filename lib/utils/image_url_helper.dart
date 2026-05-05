import 'package:flutter/foundation.dart';

/// Fixes image URLs so they resolve correctly on all platforms:
/// - Production (release APK): returns Cloudinary URLs as-is, or prepends production base
/// - Web: uses 127.0.0.1
/// - Android Emulator: uses 10.0.2.2 (proxy to host machine)
/// - Linux/macOS/Windows/iOS Simulator: uses 127.0.0.1
String fixImageUrl(String url) {
  // If URL is already a Cloudinary URL or any external HTTPS URL, return as-is.
  // This is the production case — Cloudinary storage returns full URLs.
  if (url.startsWith('https://res.cloudinary.com') ||
      url.startsWith('http://res.cloudinary.com')) {
    return url;
  }

  // Check if we're in production (release) mode
  const bool isProduction = bool.fromEnvironment('dart.vm.product');

  if (isProduction) {
    // In production release APK, image URLs should point to the production server
    // or already be absolute Cloudinary URLs (handled above).
    if (url.startsWith('http')) {
      // Already absolute — could be pointing to localhost from a bad serializer response.
      // Replace any localhost/10.0.2.2 references with the production server.
      if (url.contains('127.0.0.1') || url.contains('localhost') || url.contains('10.0.2.2')) {
        String cleanPath = url.replaceAll(RegExp(r'https?://[^/]+'), '');
        return 'https://biliran-booking-creative.onrender.com$cleanPath';
      }
      return url;
    } else {
      // Relative URL — prepend production base
      return 'https://biliran-booking-creative.onrender.com$url';
    }
  }

  // --- DEBUG MODE BELOW ---

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
