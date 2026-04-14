import '../domain/aidat_model.dart';
import '../../../core/result.dart';

abstract class AidatRepository {
  /// Admin: tüm aidatlar
  Future<Result<List<AidatModel>, AppError>> getAll();

  /// Belirli kullanıcının aidatları
  Future<Result<List<AidatModel>, AppError>> getByKullanici(int kullaniciId);

  /// Yeni aidat kaydı oluştur (admin)
  Future<Result<AidatModel, AppError>> create({
    required int kullaniciId,
    required double tutar,
    required int ay,
    required int yil,
  });

  /// Ödeme durumunu güncelle (admin)
  Future<Result<AidatModel, AppError>> updateOdemeDurum(
      int id, OdemeDurumu durum);
}
