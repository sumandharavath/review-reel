import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyToken = 'review_reel_auth_token';
  static const String _keyUser = 'review_reel_user_profile';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

