import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // --- CONFIGURATION ---
  static const bool isPhysicalDevice = true; // Set to true for Wireless Debugging
  static const String localHostIp = '192.168.0.161'; // Your PC's LAN IP
  // ---------------------

  /// Base URL for API endpoints (e.g. http://domain/api)
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://backend_services.test/api';
    } 
    
    // If we are debugging on a physical device (Android OR iOS), we must use the LAN IP
    if (isPhysicalDevice) {
       return 'https://$localHostIp/api'; 
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 is the special alias to host loopback interface on Android Emulator
      return 'https://10.0.2.2/api'; 
    } else {
      // Fallback for iOS Simulator
      return 'https://backend_services.test/api';
    }
  }

  /// Base Domain URL (e.g. http://domain) without /api suffix
  /// Useful for constructing file/image URLs
  static String get domain {
     if (kIsWeb) {
      return 'https://backend_services.test';
    }

    // Physical Device Support
    if (isPhysicalDevice) {
       return 'https://$localHostIp';
    }

    if (Platform.isAndroid) {
      return 'https://10.0.2.2';
    } else {
      return 'https://backend_services.test';
    }
  }
}
