import '../domain/bildirim_model.dart';
import '../../../core/result.dart';

abstract class BildirimRepository {
  Future<Result<List<BildirimModel>, AppError>> getBildirimler();
  Future<Result<int, AppError>> getUnreadCount();
  Future<Result<void, AppError>> markAsRead(int bildirimId);
}
