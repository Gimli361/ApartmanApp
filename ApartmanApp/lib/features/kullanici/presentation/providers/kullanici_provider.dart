import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/kullanici_repository.dart';
import '../../data/kullanici_repository_impl.dart';
import '../../../../features/auth/domain/user_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final kullaniciRepositoryProvider = Provider<KullaniciRepository>((ref) {
  return KullaniciRepositoryImpl(ref.read(apiServiceProvider));
});

class KullaniciListState {
  final List<UserModel> kullanicilar;
  final bool isLoading;
  final String? errorMessage;

  const KullaniciListState({
    this.kullanicilar = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  KullaniciListState copyWith({
    List<UserModel>? kullanicilar,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return KullaniciListState(
      kullanicilar: kullanicilar ?? this.kullanicilar,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class KullaniciListNotifier extends StateNotifier<KullaniciListState> {
  final KullaniciRepository _repo;

  KullaniciListNotifier(this._repo) : super(const KullaniciListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getAll();
    if (result is Success<List<UserModel>, AppError>) {
      state = state.copyWith(isLoading: false, kullanicilar: result.data);
    } else if (result is Failure<List<UserModel>, AppError>) {
      state = state.copyWith(
          isLoading: false, errorMessage: result.error.message);
    }
  }

  Future<bool> create({
    required String ad,
    required String soyad,
    required String email,
    required String sifre,
    required String rol,
    String? daireNo,
    String? blokNo,
  }) async {
    final result = await _repo.create(
      ad: ad,
      soyad: soyad,
      email: email,
      sifre: sifre,
      rol: rol,
      daireNo: daireNo,
      blokNo: blokNo,
    );
    if (result is Success<UserModel, AppError>) {
      await load();
      return true;
    } else if (result is Failure<UserModel, AppError>) {
      state = state.copyWith(errorMessage: result.error.message);
      return false;
    }
    return false;
  }

  Future<String?> update({
    required int id,
    required String ad,
    required String soyad,
    String? daireNo,
    String? blokNo,
  }) async {
    final result = await _repo.update(id: id, ad: ad, soyad: soyad, daireNo: daireNo, blokNo: blokNo);
    if (result is Success<UserModel, AppError>) {
      state = state.copyWith(
        kullanicilar: state.kullanicilar
            .map((k) => k.id == id ? result.data : k)
            .toList(),
      );
      return null;
    } else if (result is Failure<UserModel, AppError>) {
      return result.error.message;
    }
    return null;
  }

  Future<String?> resetSifre({
    required int id,
    required String yeniSifre,
  }) async {
    final result = await _repo.resetSifre(id: id, yeniSifre: yeniSifre);
    if (result is Failure<void, AppError>) {
      return result.error.message;
    }
    return null;
  }

  Future<bool> delete(int id) async {
    final result = await _repo.delete(id);
    if (result is Success<void, AppError>) {
      state = state.copyWith(
        kullanicilar: state.kullanicilar.where((k) => k.id != id).toList(),
      );
      return true;
    } else if (result is Failure<void, AppError>) {
      state = state.copyWith(errorMessage: result.error.message);
      return false;
    }
    return false;
  }
}

final kullaniciListProvider =
    StateNotifierProvider<KullaniciListNotifier, KullaniciListState>((ref) {
  return KullaniciListNotifier(ref.read(kullaniciRepositoryProvider));
});
