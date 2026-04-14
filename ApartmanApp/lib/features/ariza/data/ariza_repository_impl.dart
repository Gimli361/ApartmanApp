import 'dart:io';
import 'package:dio/dio.dart';
import '../domain/ariza_model.dart';
import '../../../core/constants.dart';
import '../../../core/result.dart';
import '../../../shared/services/api_service.dart';
import 'ariza_repository.dart';

class ArizaRepositoryImpl implements ArizaRepository {
  final ApiService _api;

  ArizaRepositoryImpl(this._api);

  List<ArizaModel> _parseList(dynamic data) =>
      (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ArizaModel.fromJson)
          .toList();

  @override
  Future<Result<List<ArizaModel>, AppError>> getArizalar() async {
    try {
      final res = await _api.dio.get('/api/ariza');
      return Success(_parseList(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<ArizaModel, AppError>> getById(int id) async {
    try {
      final res = await _api.dio.get('/api/ariza/$id');
      return Success(ArizaModel.fromJson(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<ArizaModel, AppError>> createAriza({
    required String baslik,
    required String aciklama,
    required ArizaOncelik oncelik,
    required int bildirenId,
  }) async {
    try {
      final res = await _api.dio.post('/api/ariza', data: {
        'baslik': baslik,
        'aciklama': aciklama,
        'oncelik': oncelik.toApiString(),
        'bildirenId': bildirenId,
      });
      return Success(ArizaModel.fromJson(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<ArizaModel, AppError>> updateDurum(
    int id,
    ArizaDurum durum, {
    String? redNedeni,
  }) async {
    try {
      final body = <String, dynamic>{'durum': durum.toApiString()};
      if (redNedeni != null && redNedeni.isNotEmpty) {
        body['redNedeni'] = redNedeni;
      }
      final res = await _api.dio.patch('/api/ariza/$id/durum', data: body);
      return Success(ArizaModel.fromJson(res.data['data']));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> deleteAriza(int id) async {
    try {
      await _api.dio.delete('/api/ariza/$id');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<List<String>, AppError>> getFotolar(int arizaId) async {
    try {
      final res = await _api.dio.get('/api/ariza/$arizaId/foto');
      final data = res.data['data'] as List<dynamic>;
      final baseUrl = AppConstants.baseUrl;
      final urls = data.cast<Map<String, dynamic>>().map((f) {
        final raw = f['url'] as String;
        // URL'deki host kısmını emülatör için baseUrl ile değiştir
        final uri = Uri.tryParse(raw);
        if (uri != null && uri.hasAuthority) {
          return '$baseUrl${uri.path}';
        }
        return raw;
      }).toList();
      return Success(urls);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<TakipDurumuModel, AppError>> getTakipDurumu(
      int arizaId) async {
    try {
      final res = await _api.dio.get('/api/ariza/$arizaId/takip-durumu');
      return Success(TakipDurumuModel.fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> takipEt(int arizaId) async {
    try {
      await _api.dio.post('/api/ariza/$arizaId/takip');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> takiptenCik(int arizaId) async {
    try {
      await _api.dio.delete('/api/ariza/$arizaId/takip');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }

  @override
  Future<Result<void, AppError>> uploadFoto(int arizaId, File file) async {
    try {
      final formData = FormData.fromMap({
        'dosya': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      await _api.dio.post('/api/ariza/$arizaId/foto', data: formData);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    }
  }
}
