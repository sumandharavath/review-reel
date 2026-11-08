import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine from Android Emulator
      return 'http://10.0.2.2:5001/api/v1';
    }

    // iOS Simulator, macOS Desktop, etc.
    return 'http://localhost:5001/api/v1';
  }

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
}

