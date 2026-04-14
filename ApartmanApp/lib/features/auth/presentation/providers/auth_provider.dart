import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/user_model.dart';
import '../../../../core/result.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/notification_service.dart';

// --- Altyapı provider'ları ---

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(apiServiceProvider),
    ref.read(secureStorageProvider),
  );
});

// --- Auth state ---

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final ApiService _apiService;
  final NotificationService _notificationService;

  AuthNotifier(this._repo, this._apiService, this._notificationService)
      : super(const AuthState()) {
    // 401 gelince otomatik logout
    _apiService.onUnauthorized = () {
      if (state.isLoggedIn) logout();
    };
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    final result = await _repo.getCurrentUser();
    if (result is Success<UserModel?, AppError>) {
      state = state.copyWith(user: result.data);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.login(email, password);

    if (result is Success<UserModel, AppError>) {
      state = state.copyWith(isLoading: false, user: result.data);
      _notificationService.sendTokenToServer(result.data.id);
      return true;
    } else if (result is Failure<UserModel, AppError>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error.message,
      );
      return false;
    }
    return false;
  }

  /// Ad/Soyad/DaireNo/BlokNo güncelle ve local state'i yenile
  Future<Result<void, AppError>> updateProfile({
    required String ad,
    required String soyad,
    required String daireNo,
    String? blokNo,
  }) async {
    final userId = state.user?.id;
    if (userId == null) return Failure(const AppError('Oturum bulunamadı.'));

    try {
      final response = await _apiService.dio.put(
        '/api/kullanici/$userId',
        data: {
          'ad': ad,
          'soyad': soyad,
          'daireNo': daireNo,
          'blokNo': blokNo,
        },
      );
      final updated = UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(user: updated);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  /// Şifre güncelle
  Future<Result<void, AppError>> updateSifre({
    required String eskiSifre,
    required String yeniSifre,
  }) async {
    final userId = state.user?.id;
    if (userId == null) return Failure(const AppError('Oturum bulunamadı.'));

    try {
      await _apiService.dio.patch(
        '/api/kullanici/$userId/sifre',
        data: {'eskiSifre': eskiSifre, 'yeniSifre': yeniSifre},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(apiServiceProvider),
    ref.read(notificationServiceProvider),
  );
});
