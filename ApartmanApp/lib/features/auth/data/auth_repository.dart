import '../domain/user_model.dart';
import '../../../core/result.dart';

/// Auth repository
abstract class AuthRepository {
  Future<Result<UserModel, AppError>> login(String email, String password);
  Future<Result<void, AppError>> logout();
  Future<Result<UserModel?, AppError>> getCurrentUser();
}
