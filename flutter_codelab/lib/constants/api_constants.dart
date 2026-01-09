import 'package:flutter/foundation.dart';

class ApiConstants {
  // --- CONFIGURATION ---
  // These are set via --dart-define in launch.json
  static const bool isPhysicalDevice = bool.fromEnvironment(
    'PHYSICAL_DEVICE',
    defaultValue: false,
  );
  static const bool useHerd = bool.fromEnvironment(
    'USE_HERD',
    defaultValue: true,
  );
  static const String localHostIp = String.fromEnvironment(
    'LOCAL_IP',
    defaultValue: '192.168.1.242',
  );
  static const String customBaseUrl = String.fromEnvironment(
    'CUSTOM_BASE_URL',
    defaultValue: '',
  ); // For production (Vercel) or Expose/Ngrok
  
  // Production backend URL (Render)
  static const String productionBackendUrl = 'https://kalmnest-9xvv.onrender.com';
  // ---------------------

  /// Base URL for API endpoints (e.g. http://domain/api)
  static String get baseUrl {
    // 1. Priority: Custom URL (from environment variable)
    if (customBaseUrl.isNotEmpty) {
      // Remove trailing slash if present
      final url = customBaseUrl.endsWith('/') 
          ? customBaseUrl.substring(0, customBaseUrl.length - 1) 
          : customBaseUrl;
      return '$url/api';
    }

    if (kIsWeb) {
      // In production (Vercel), use Render backend as default
      // If CUSTOM_BASE_URL is not set, assume production environment
      // For local development, set CUSTOM_BASE_URL to 'https://kalmnest.test'
      return '$productionBackendUrl/api';
    }

    // If we are debugging on a physical device (Android OR iOS)
    if (isPhysicalDevice) {
      // Profile: "Physical Device (Artisan)" -> HTTP on Port 8000
      if (!useHerd) {
        return 'http://$localHostIp:8000/api';
      }
      // Profile: "Physical Device (Herd)" -> HTTPS on Port 80 (Requires matching Wi-Fi/DNS)
      return 'https://$localHostIp/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the special alias to host loopback interface on Android Emulator
      return 'https://10.0.2.2/api';
    } else {
      // Fallback for iOS Simulator
      return 'https://kalmnest.test/api';
    }
  }

  /// Base Domain URL (e.g. http://domain) without /api suffix
  /// Useful for constructing file/image URLs
  static String get domain {
    // 1. Priority: Custom URL (from environment variable)
    if (customBaseUrl.isNotEmpty) {
      // Remove trailing slash if present
      return customBaseUrl.endsWith('/') 
          ? customBaseUrl.substring(0, customBaseUrl.length - 1) 
          : customBaseUrl;
    }

    if (kIsWeb) {
      // In production (Vercel), use Render backend as default
      // If CUSTOM_BASE_URL is not set, assume production environment
      // For local development, set CUSTOM_BASE_URL to 'https://kalmnest.test'
      return productionBackendUrl;
    }

    // Physical Device Support
    if (isPhysicalDevice) {
      if (!useHerd) {
        return 'http://$localHostIp:8000';
      }
      return 'https://$localHostIp';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://10.0.2.2';
    } else {
      return 'https://kalmnest.test';
    }
  }
}
