import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../core/result.dart';

/// Merkezi Dio yapılandırması
class ApiService {
  late final Dio _dio;
  // Refresh için ayrı bir Dio (interceptor loop'u önlemek için)
  late final Dio _refreshDio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Refresh başarısız olursa (refresh token da expire olmuş) çağrılır.
  /// auth_provider tarafından set edilir; logout flow'unu tetikler.
  void Function()? onUnauthorized;

  // Eşzamanlı 401'lerde tek bir refresh çağrısını paylaş
  Future<bool>? _refreshing;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _refreshDio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        // 401 → refresh dene, başarılıysa orijinal isteği yeniden gönder
        final req = e.requestOptions;
        final isAuthEndpoint = req.path.contains('/api/auth/login') ||
            req.path.contains('/api/auth/refresh');

        if (e.response?.statusCode == 401 &&
            !isAuthEndpoint &&
            req.extra['__retry'] != true) {
          final refreshed = await _ensureRefreshing();
          if (refreshed) {
            try {
              // Yeni token ile orijinal isteği tekrar dene (sadece bir kez)
              req.extra['__retry'] = true;
              req.headers['Authorization'] =
                  _dio.options.headers['Authorization'];
              final clone = await _dio.fetch(req);
              return handler.resolve(clone);
            } catch (retryErr) {
              if (retryErr is DioException) {
                return handler.next(retryErr);
              }
              return handler.next(e);
            }
          } else {
            // Refresh başarısız → tam logout
            onUnauthorized?.call();
          }
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

  /// Refresh akışını paylaşılan bir future üzerinden çalıştırır;
  /// aynı anda gelen birden fazla 401, tek bir HTTP çağrısına eşlenir.
  Future<bool> _ensureRefreshing() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final rt = await _storage.read(key: AppConstants.storageKeyRefreshToken);
      if (rt == null || rt.isEmpty) return false;

      final res = await _refreshDio.post('/api/auth/refresh',
          data: {'refreshToken': rt});

      if (res.statusCode != 200 || res.data == null) return false;
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final newAccess = data['token'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) return false;

      await _storage.write(
          key: AppConstants.storageKeyToken, value: newAccess);
      await _storage.write(
          key: AppConstants.storageKeyRefreshToken, value: newRefresh);
      setAuthToken(newAccess);
      return true;
    } catch (_) {
      return false;
    }
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
