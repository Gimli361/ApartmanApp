import '../domain/oylama_model.dart';
import '../../../core/result.dart';

/// Oylama repository
abstract class OylamaRepository {
  Future<Result<List<OylamaModel>, AppError>> getOylamalar();
  Future<Result<OylamaModel, AppError>> getOylamaById(String id);
  Future<Result<void, AppError>> oyVer(String oylamaId, String secenekId);
}
