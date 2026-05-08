import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/aidat_repository.dart';
import '../../data/aidat_repository_impl.dart';
import '../../domain/aidat_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final aidatRepositoryProvider = Provider<AidatRepository>((ref) {
  return AidatRepositoryImpl(ref.read(apiServiceProvider));
});

class AidatState {
  final List<AidatModel> aidatlar;
  final bool isLoading;
  final String? error;

  const AidatState({
    this.aidatlar = const [],
    this.isLoading = false,
    this.error,
  });

  AidatState copyWith({
    List<AidatModel>? aidatlar,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AidatState(
      aidatlar: aidatlar ?? this.aidatlar,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AidatNotifier extends StateNotifier<AidatState> {
  final AidatRepository _repo;

  AidatNotifier(this._repo) : super(const AidatState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getAll();
    if (result is Success<List<AidatModel>, AppError>) {
      state = state.copyWith(isLoading: false, aidatlar: result.data);
    } else if (result is Failure<List<AidatModel>, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> loadByKullanici(int kullaniciId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getByKullanici(kullaniciId);
    if (result is Success<List<AidatModel>, AppError>) {
      state = state.copyWith(isLoading: false, aidatlar: result.data);
    } else if (result is Failure<List<AidatModel>, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<Result<AidatModel, AppError>> create({
    required int kullaniciId,
    required double tutar,
    required int ay,
    required int yil,
  }) async {
    final result = await _repo.create(
        kullaniciId: kullaniciId, tutar: tutar, ay: ay, yil: yil);
    if (result is Success<AidatModel, AppError>) {
      state = state.copyWith(aidatlar: [result.data, ...state.aidatlar]);
    }
    return result;
  }

  Future<Result<AidatModel, AppError>> updateOdemeDurum(
      int id, OdemeDurumu durum) async {
    final result = await _repo.updateOdemeDurum(id, durum);
    if (result is Success<AidatModel, AppError>) {
      state = state.copyWith(
        aidatlar: state.aidatlar
            .map((a) => a.id == id ? result.data : a)
            .toList(),
      );
    } else if (result is Failure<AidatModel, AppError>) {
      state = state.copyWith(error: result.error.message);
    }
    return result;
  }
}

final aidatProvider =
    StateNotifierProvider<AidatNotifier, AidatState>((ref) {
  return AidatNotifier(ref.read(aidatRepositoryProvider));
});
