import '../domain/oylama_model.dart';
import '../../../core/result.dart';

abstract class OylamaRepository {
  Future<Result<List<OylamaModel>, AppError>> getAll();
  Future<Result<OylamaDetailModel, AppError>> getById(int id);
  Future<Result<OylamaDetailModel, AppError>> create({
    required String baslik,
    String? aciklama,
    required DateTime bitisTarihi,
    required List<String> secenekler,
  });
  Future<Result<void, AppError>> oyVer(int oylamaId, int secenekId);
  Future<Result<void, AppError>> oyGeriAl(int oylamaId);
  Future<Result<void, AppError>> toggleAktif(int id);
  Future<Result<void, AppError>> delete(int id);
}
