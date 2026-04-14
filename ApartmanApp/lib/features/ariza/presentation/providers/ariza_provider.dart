import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ariza_repository.dart';
import '../../data/ariza_repository_impl.dart';
import '../../domain/ariza_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final arizaRepositoryProvider = Provider<ArizaRepository>((ref) {
  return ArizaRepositoryImpl(ref.read(apiServiceProvider));
});

// --- Arıza listesi state ---

class ArizaListState {
  final List<ArizaModel> arizalar;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> loadingTakipIds;

  const ArizaListState({
    this.arizalar = const [],
    this.isLoading = false,
    this.errorMessage,
    this.loadingTakipIds = const {},
  });

  ArizaListState copyWith({
    List<ArizaModel>? arizalar,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Set<int>? loadingTakipIds,
  }) {
    return ArizaListState(
      arizalar: arizalar ?? this.arizalar,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      loadingTakipIds: loadingTakipIds ?? this.loadingTakipIds,
    );
  }
}

class ArizaListNotifier extends StateNotifier<ArizaListState> {
  final ArizaRepository _repo;

  ArizaListNotifier(this._repo) : super(const ArizaListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getArizalar();
    if (result is Success<List<ArizaModel>, AppError>) {
      state = state.copyWith(isLoading: false, arizalar: result.data);
    } else if (result is Failure<List<ArizaModel>, AppError>) {
      state = state.copyWith(isLoading: false, errorMessage: result.error.message);
    }
  }

  /// Arıza oluşturur. Dönen değer: (arizaOlustu, fotoYuklendi)
  Future<(bool, bool)> create({
    required String baslik,
    required String aciklama,
    required ArizaOncelik oncelik,
    required int bildirenId,
    File? foto,
  }) async {
    final result = await _repo.createAriza(
      baslik: baslik,
      aciklama: aciklama,
      oncelik: oncelik,
      bildirenId: bildirenId,
    );

    if (result is Success<ArizaModel, AppError>) {
      bool fotoYuklendi = true;
      if (foto != null) {
        final fotoResult = await _repo.uploadFoto(result.data.id, foto);
        fotoYuklendi = fotoResult is Success<void, AppError>;
      }
      await load();
      return (true, fotoYuklendi);
    } else if (result is Failure<ArizaModel, AppError>) {
      state = state.copyWith(errorMessage: result.error.message);
      return (false, false);
    }
    return (false, false);
  }

  Future<bool> updateDurum(
    int id,
    ArizaDurum durum, {
    String? redNedeni,
  }) async {
    final result = await _repo.updateDurum(id, durum, redNedeni: redNedeni);
    if (result is Success<ArizaModel, AppError>) {
      final updated = result.data;
      state = state.copyWith(
        arizalar: state.arizalar
            .map((a) => a.id == id ? updated : a)
            .toList(),
      );
      return true;
    } else if (result is Failure<ArizaModel, AppError>) {
      state = state.copyWith(errorMessage: result.error.message);
      return false;
    }
    return false;
  }

  Future<void> toggleTakip(int arizaId) async {
    final idx = state.arizalar.indexWhere((a) => a.id == arizaId);
    if (idx == -1) return;
    final ariza = state.arizalar[idx];

    state = state.copyWith(loadingTakipIds: {...state.loadingTakipIds, arizaId});

    final result = ariza.kullaniciTakipEdiyor
        ? await _repo.takiptenCik(arizaId)
        : await _repo.takipEt(arizaId);

    final newIds = {...state.loadingTakipIds}..remove(arizaId);

    if (result is Success) {
      final yeniTakip = !ariza.kullaniciTakipEdiyor;
      final yeniSayi = yeniTakip
          ? ariza.takipciSayisi + 1
          : (ariza.takipciSayisi - 1).clamp(0, 999999);
      final updated = ariza.copyWith(
        kullaniciTakipEdiyor: yeniTakip,
        takipciSayisi: yeniSayi,
      );
      final newList = [...state.arizalar]..[idx] = updated;
      state = state.copyWith(loadingTakipIds: newIds, arizalar: newList);
    } else {
      state = state.copyWith(loadingTakipIds: newIds);
    }
  }

  Future<bool> delete(int id) async {
    final result = await _repo.deleteAriza(id);
    if (result is Success<void, AppError>) {
      state = state.copyWith(
        arizalar: state.arizalar.where((a) => a.id != id).toList(),
      );
      return true;
    } else if (result is Failure<void, AppError>) {
      state = state.copyWith(errorMessage: result.error.message);
      return false;
    }
    return false;
  }
}

final arizaListProvider =
    StateNotifierProvider<ArizaListNotifier, ArizaListState>((ref) {
  return ArizaListNotifier(ref.read(arizaRepositoryProvider));
});

/// Takip durumu — arizaId'ye göre
final takipDurumuProvider =
    FutureProvider.family<TakipDurumuModel, int>((ref, arizaId) async {
  final repo = ref.read(arizaRepositoryProvider);
  final result = await repo.getTakipDurumu(arizaId);
  if (result is Success<TakipDurumuModel, AppError>) return result.data;
  return const TakipDurumuModel(takipEdiyor: false, takipciSayisi: 0);
});
