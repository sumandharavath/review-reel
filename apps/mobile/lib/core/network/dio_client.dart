import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  DioClient({required this.secureStorage, Dio? customDio})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) {
          String message = 'An unexpected error occurred. Please try again.';

          if (err.response != null && err.response?.data != null) {
            final data = err.response?.data;
            if (data is Map<String, dynamic> && data['message'] != null) {
              message = data['message'].toString();
            } else if (err.response?.statusMessage != null) {
              message = err.response!.statusMessage!;
            }
          } else if (err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout) {
            message = 'Connection timed out. Please check your network connection.';
          } else if (err.type == DioExceptionType.connectionError) {
            message = 'Unable to connect to the server. Please check if the API is running.';
          }

          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ApiException(
                message: message,
                statusCode: err.response?.statusCode,
                details: err.response?.data,
              ),
              response: err.response,
              type: err.type,
            ),
          );
        },
      ),
    );
  }
}
