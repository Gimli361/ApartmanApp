import 'package:dio/dio.dart';
import '../../../core/result.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../shared/services/api_service.dart';
import 'kullanici_repository.dart';

class KullaniciRepositoryImpl implements KullaniciRepository {
  final ApiService _api;

  KullaniciRepositoryImpl(this._api);

  @override
  Future<Result<List<UserModel>, AppError>> getAll() async {
    try {
      final res = await _api.dio.get('/api/kullanici');
      final data = res.data['data'] as List<dynamic>;
      return Success(
        data.cast<Map<String, dynamic>>().map(UserModel.fromJson).toList(),
      );
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<UserModel, AppError>> create({
    required String ad,
    required String soyad,
    required String email,
    required String sifre,
    required String rol,
    String? daireNo,
    String? blokNo,
  }) async {
    try {
      final res = await _api.dio.post('/api/kullanici', data: {
        'ad': ad,
        'soyad': soyad,
        'email': email,
        'sifre': sifre,
        'rol': rol,
        'daireNo': daireNo ?? '',
        'blokNo': blokNo,
      });
      return Success(UserModel.fromJson(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<UserModel, AppError>> update({
    required int id,
    required String ad,
    required String soyad,
    String? daireNo,
    String? blokNo,
  }) async {
    try {
      final res = await _api.dio.put('/api/kullanici/$id', data: {
        'ad': ad,
        'soyad': soyad,
        'daireNo': daireNo ?? '',
        'blokNo': blokNo,
      });
      return Success(UserModel.fromJson(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> resetSifre({
    required int id,
    required String yeniSifre,
  }) async {
    try {
      await _api.dio.patch('/api/kullanici/$id/sifre-sifirla', data: {
        'yeniSifre': yeniSifre,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> delete(int id) async {
    try {
      await _api.dio.delete('/api/kullanici/$id');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }
}
