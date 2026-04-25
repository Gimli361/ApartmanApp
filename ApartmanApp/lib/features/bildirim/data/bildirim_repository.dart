import '../domain/bildirim_model.dart';
import '../../../core/paged_result.dart';
import '../../../core/result.dart';

abstract class BildirimRepository {
  Future<Result<List<BildirimModel>, AppError>> getBildirimler();
  Future<Result<PagedResult<BildirimModel>, AppError>> getBildirimlerPaged({
    int page = 1,
    int pageSize = 20,
  });
  Future<Result<int, AppError>> getUnreadCount();
  Future<Result<void, AppError>> markAsRead(int bildirimId);
  Future<Result<void, AppError>> markAllAsRead();
  Future<Result<void, AppError>> sendDuyuru(String baslik, String icerik);
  Future<Result<void, AppError>> sendBlokBildirim(
      String blokNo, String baslik, String icerik);
  Future<Result<void, AppError>> sendDaireBildirim(
      String daireNo, String baslik, String icerik, {String? blokNo});
}
