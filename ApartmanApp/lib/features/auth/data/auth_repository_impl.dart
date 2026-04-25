import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import '../../../core/constants.dart';
import '../../../core/result.dart';
import '../../../shared/services/api_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _api;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  Future<Result<UserModel, AppError>> login(
      String email, String password) async {
    try {
      final response = await _api.dio.post('/api/auth/login', data: {
        'email': email,
        'sifre': password,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      // Token, refresh token ve kullanıcıyı sakla
      await _storage.write(key: AppConstants.storageKeyToken, value: token);
      if (refreshToken != null) {
        await _storage.write(
            key: AppConstants.storageKeyRefreshToken, value: refreshToken);
      }
      await _storage.write(
        key: AppConstants.storageKeyUser,
        value: jsonEncode(user.toJson()),
      );

      // API servisine token'ı set et
      _api.setAuthToken(token);

      return Success(user);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> logout() async {
    // Sunucuya da logout çağrısı yap (refresh token'ı revoke et)
    final rt =
        await _storage.read(key: AppConstants.storageKeyRefreshToken);
    if (rt != null && rt.isNotEmpty) {
      try {
        await _api.dio.post('/api/auth/logout', data: {'refreshToken': rt});
      } catch (_) {
        // Sessizce yut — local cleanup zaten yapılacak
      }
    }

    await _storage.delete(key: AppConstants.storageKeyUser);
    await _storage.delete(key: AppConstants.storageKeyToken);
    await _storage.delete(key: AppConstants.storageKeyRefreshToken);
    _api.clearAuthToken();
    return const Success(null);
  }

  @override
  Future<Result<UserModel?, AppError>> getCurrentUser() async {
    try {
      final json = await _storage.read(key: AppConstants.storageKeyUser);
      if (json == null) return const Success(null);

      // Saklı token'ı yükle ve API servisine set et
      final token = await _storage.read(key: AppConstants.storageKeyToken);
      if (token != null) {
        _api.setAuthToken(token);
      }

      final user =
          UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      return Success(user);
    } catch (_) {
      return const Success(null);
    }
  }
}
