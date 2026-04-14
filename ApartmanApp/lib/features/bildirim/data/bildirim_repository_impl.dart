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
}
