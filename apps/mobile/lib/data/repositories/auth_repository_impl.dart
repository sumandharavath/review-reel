import 'dart:convert';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      email: email,
      password: password,
    );

    await secureStorage.saveToken(response.token);
    await secureStorage.saveUserJson(jsonEncode(response.user.toJson()));

    return response.user;
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    await secureStorage.saveToken(response.token);
    await secureStorage.saveUserJson(jsonEncode(response.user.toJson()));

    return response.user;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await secureStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await remoteDataSource.getMe();
      await secureStorage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      // If offline or network error, fallback to cached user data if available
      final cachedJson = await secureStorage.getUserJson();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final map = jsonDecode(cachedJson) as Map<String, dynamic>;
          return UserModel.fromJson(map);
        } catch (_) {}
      }
      // If token expired (401), clear storage
      await secureStorage.clearAll();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await secureStorage.clearAll();
    }
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
