import 'package:dio/dio.dart';
import '../domain/aidat_model.dart';
import '../../../core/result.dart';
import '../../../shared/services/api_service.dart';
import 'aidat_repository.dart';

class AidatRepositoryImpl implements AidatRepository {
  final ApiService _api;

  AidatRepositoryImpl(this._api);

  @override
  Future<Result<List<AidatModel>, AppError>> getAll() async {
    try {
      final response = await _api.dio.get('/api/aidat');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final aidatlar = data
          .cast<Map<String, dynamic>>()
          .map(AidatModel.fromJson)
          .toList();
      return Success(aidatlar);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<List<AidatModel>, AppError>> getByKullanici(
      int kullaniciId) async {
    try {
      final response =
          await _api.dio.get('/api/aidat/kullanici/$kullaniciId');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final aidatlar = data
          .cast<Map<String, dynamic>>()
          .map(AidatModel.fromJson)
          .toList();
      return Success(aidatlar);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<AidatModel, AppError>> create({
    required int kullaniciId,
    required double tutar,
    required int ay,
    required int yil,
  }) async {
    try {
      final response = await _api.dio.post('/api/aidat', data: {
        'kullaniciId': kullaniciId,
        'tutar': tutar,
        'ay': ay,
        'yil': yil,
      });
      return Success(AidatModel.fromJson(
          response.data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<AidatModel, AppError>> updateOdemeDurum(
      int id, OdemeDurumu durum) async {
    final durumStr = switch (durum) {
      OdemeDurumu.odendi => 'Odendi',
      OdemeDurumu.gecikti => 'Gecikti',
      OdemeDurumu.beklemede => 'Beklemede',
    };
    try {
      final response = await _api.dio.patch(
        '/api/aidat/$id/odemeDurumu',
        data: {'odemeDurumu': durumStr},
      );
      return Success(AidatModel.fromJson(
          response.data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }
}
