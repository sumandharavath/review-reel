import 'package:flutter/foundation.dart' show ValueNotifier;

class ApiConstants {
  ApiConstants._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static final ValueNotifier<String> baseUrlNotifier = ValueNotifier<String>(_resolveInitialUrl());

  static String _resolveInitialUrl() {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    // Default to localhost:5001 which works for:
    // 1. Android physical phones via 'adb reverse tcp:5001 tcp:5001'
    // 2. iOS Simulator
    // 3. Web & Desktop
    return 'http://localhost:5001/api/v1';
  }

  static String get baseUrl => baseUrlNotifier.value;

  static void setBaseUrl(String newUrl) {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api/v1')) {
      cleanUrl = '$cleanUrl/api/v1';
    }
    baseUrlNotifier.value = cleanUrl;
  }

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
}
