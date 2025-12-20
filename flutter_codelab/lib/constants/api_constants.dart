import 'dart:io';
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
  ); // For Expose/Ngrok
  // ---------------------

  /// Base URL for API endpoints (e.g. http://domain/api)
  static String get baseUrl {
    // 1. Priority: Custom URL (Expose)
    if (customBaseUrl.isNotEmpty) {
      return '$customBaseUrl/api';
    }

    if (kIsWeb) {
         return 'https://kalmnest.test/api';
      
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

    if (Platform.isAndroid) {
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
    // 1. Priority: Custom URL (Expose)
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }

    if (kIsWeb) {
       return 'https://kalmnest.test';
    
    }

    // Physical Device Support
    if (isPhysicalDevice) {
      if (!useHerd) {
        return 'http://$localHostIp:8000';
      }
      return 'https://$localHostIp';
    }

    if (Platform.isAndroid) {
      return 'https://10.0.2.2';
    } else {
       return 'https://kalmnest.test';
    
    }
  }
}