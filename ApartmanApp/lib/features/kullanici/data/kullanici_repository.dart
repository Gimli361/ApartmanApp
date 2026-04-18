import '../../../core/result.dart';
import '../../../features/auth/domain/user_model.dart';

abstract interface class KullaniciRepository {
  Future<Result<List<UserModel>, AppError>> getAll();
  Future<Result<UserModel, AppError>> create({
    required String ad,
    required String soyad,
    required String email,
    required String sifre,
    required String rol,
    String? daireNo,
    String? blokNo,
  });
  Future<Result<UserModel, AppError>> update({
    required int id,
    required String ad,
    required String soyad,
    String? daireNo,
    String? blokNo,
  });
  Future<Result<void, AppError>> resetSifre({
    required int id,
    required String yeniSifre,
  });
  Future<Result<void, AppError>> delete(int id);
}
