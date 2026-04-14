import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../core/result.dart';

/// Merkezi Dio yapılandırması
class ApiService {
  late final Dio _dio;

  /// Token süresi dolunca veya 401 dönünce çağrılır (auth_provider tarafından set edilir)
  void Function()? onUnauthorized;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Dio hatasını AppError'a çevirir
  static AppError handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppError('Sunucuya ulaşılamıyor, lütfen tekrar deneyin.');
      case DioExceptionType.connectionError:
        return const AppError('İnternet bağlantısı yok.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['errors']?[0] ??
            e.response?.data?['message'] ??
            'Bir hata oluştu.';
        return AppError(message.toString(), statusCode: statusCode);
      default:
        return const AppError('Beklenmeyen bir hata oluştu.');
    }
  }
}
