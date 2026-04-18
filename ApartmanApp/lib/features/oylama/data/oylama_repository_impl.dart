import 'package:dio/dio.dart';
import '../domain/oylama_model.dart';
import '../../../core/result.dart';
import '../../../shared/services/api_service.dart';
import 'oylama_repository.dart';

class OylamaRepositoryImpl implements OylamaRepository {
  final ApiService _api;

  OylamaRepositoryImpl(this._api);

  @override
  Future<Result<List<OylamaModel>, AppError>> getAll() async {
    try {
      final response = await _api.dio.get('/api/oylama');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final oylamalar = data
          .cast<Map<String, dynamic>>()
          .map(OylamaModel.fromJson)
          .toList();
      return Success(oylamalar);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<OylamaDetailModel, AppError>> getById(int id) async {
    try {
      final response = await _api.dio.get('/api/oylama/$id');
      return Success(OylamaDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<OylamaDetailModel, AppError>> create({
    required String baslik,
    String? aciklama,
    required DateTime bitisTarihi,
    required List<String> secenekler,
  }) async {
    try {
      final response = await _api.dio.post('/api/oylama', data: {
        'baslik': baslik,
        'aciklama': aciklama,
        'bitisTarihi': bitisTarihi.toUtc().toIso8601String(),
        'secenekler': secenekler,
      });
      return Success(OylamaDetailModel.fromJson(
          response.data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> oyVer(int oylamaId, int secenekId) async {
    try {
      await _api.dio.post('/api/oylama/$oylamaId/oy',
          data: {'secenekId': secenekId});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> oyGeriAl(int oylamaId) async {
    try {
      await _api.dio.delete('/api/oylama/$oylamaId/oy');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> toggleAktif(int id) async {
    try {
      await _api.dio.patch('/api/oylama/$id/toggle');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> delete(int id) async {
    try {
      await _api.dio.delete('/api/oylama/$id');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }
}
