import 'dart:io';
import '../domain/ariza_model.dart';
import '../../../core/result.dart';

abstract class ArizaRepository {
  Future<Result<List<ArizaModel>, AppError>> getArizalar();
  Future<Result<ArizaModel, AppError>> getById(int id);
  Future<Result<ArizaModel, AppError>> createAriza({
    required String baslik,
    required String aciklama,
    required ArizaOncelik oncelik,
    required int bildirenId,
  });
  Future<Result<ArizaModel, AppError>> updateDurum(
    int id,
    ArizaDurum durum, {
    String? redNedeni,
  });
  Future<Result<void, AppError>> deleteAriza(int id);
  Future<Result<void, AppError>> uploadFoto(int arizaId, File file);
  Future<Result<List<String>, AppError>> getFotolar(int arizaId);

  // Takip
  Future<Result<TakipDurumuModel, AppError>> getTakipDurumu(int arizaId);
  Future<Result<void, AppError>> takipEt(int arizaId);
  Future<Result<void, AppError>> takiptenCik(int arizaId);
}
