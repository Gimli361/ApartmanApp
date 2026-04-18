import 'package:dio/dio.dart';
import '../domain/bildirim_model.dart';
import '../../../core/result.dart';
import '../../../shared/services/api_service.dart';
import 'bildirim_repository.dart';

class BildirimRepositoryImpl implements BildirimRepository {
  final ApiService _api;

  BildirimRepositoryImpl(this._api);

  @override
  Future<Result<List<BildirimModel>, AppError>> getBildirimler() async {
    try {
      final response = await _api.dio.get('/api/bildirim');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      final bildirimler = data
          .cast<Map<String, dynamic>>()
          .map(BildirimModel.fromJson)
          .toList();
      return Success(bildirimler);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<int, AppError>> getUnreadCount() async {
    try {
      final response = await _api.dio.get('/api/bildirim/okunmamis-sayi');
      final count = response.data['count'] as int;
      return Success(count);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> markAsRead(int bildirimId) async {
    try {
      await _api.dio.patch('/api/bildirim/$bildirimId/okundu');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> markAllAsRead() async {
    try {
      await _api.dio.patch('/api/bildirim/tumu-okundu');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> sendDuyuru(
      String baslik, String icerik) async {
    try {
      await _api.dio.post('/api/bildirim/duyuru',
          data: {'baslik': baslik, 'icerik': icerik});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> sendBlokBildirim(
      String blokNo, String baslik, String icerik) async {
    try {
      await _api.dio.post('/api/bildirim/blok',
          data: {'blokNo': blokNo, 'baslik': baslik, 'icerik': icerik});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> sendDaireBildirim(
      String daireNo, String baslik, String icerik, {String? blokNo}) async {
    try {
      final body = <String, dynamic>{
        'daireNo': daireNo,
        'baslik': baslik,
        'icerik': icerik,
      };
      if (blokNo != null && blokNo.isNotEmpty) body['blokNo'] = blokNo;
      await _api.dio.post('/api/bildirim/daire', data: body);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }
}
