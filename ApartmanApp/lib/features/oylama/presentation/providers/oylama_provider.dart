import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/oylama_repository.dart';
import '../../data/oylama_repository_impl.dart';
import '../../domain/oylama_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final oylamaRepositoryProvider = Provider<OylamaRepository>((ref) {
  return OylamaRepositoryImpl(ref.read(apiServiceProvider));
});

// ─── Liste State ─────────────────────────────────────────────────────────────

class OylamaListState {
  final List<OylamaModel> oylamalar;
  final bool isLoading;
  final String? error;

  const OylamaListState({
    this.oylamalar = const [],
    this.isLoading = false,
    this.error,
  });

  OylamaListState copyWith({
    List<OylamaModel>? oylamalar,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OylamaListState(
      oylamalar: oylamalar ?? this.oylamalar,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class OylamaListNotifier extends StateNotifier<OylamaListState> {
  final OylamaRepository _repo;

  OylamaListNotifier(this._repo) : super(const OylamaListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getAll();
    if (result is Success<List<OylamaModel>, AppError>) {
      state = state.copyWith(isLoading: false, oylamalar: result.data);
    } else if (result is Failure<List<OylamaModel>, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  void removeById(int id) {
    state = state.copyWith(
      oylamalar: state.oylamalar.where((o) => o.id != id).toList(),
    );
  }
}

final oylamaListProvider =
    StateNotifierProvider<OylamaListNotifier, OylamaListState>((ref) {
  return OylamaListNotifier(ref.read(oylamaRepositoryProvider));
});

// ─── Detay State ─────────────────────────────────────────────────────────────

class OylamaDetailState {
  final OylamaDetailModel? oylama;
  final bool isLoading;
  final String? error;

  const OylamaDetailState({
    this.oylama,
    this.isLoading = false,
    this.error,
  });

  OylamaDetailState copyWith({
    OylamaDetailModel? oylama,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OylamaDetailState(
      oylama: oylama ?? this.oylama,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class OylamaDetailNotifier extends StateNotifier<OylamaDetailState> {
  final OylamaRepository _repo;
  final int _oylamaId;

  OylamaDetailNotifier(this._repo, this._oylamaId)
      : super(const OylamaDetailState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getById(_oylamaId);
    if (result is Success<OylamaDetailModel, AppError>) {
      state = state.copyWith(isLoading: false, oylama: result.data);
    } else if (result is Failure<OylamaDetailModel, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<String?> oyVer(int secenekId) async {
    final result = await _repo.oyVer(_oylamaId, secenekId);
    if (result is Failure) {
      return (result as Failure).error.message;
    }
    await load();
    return null;
  }

  Future<String?> oyGeriAl() async {
    final result = await _repo.oyGeriAl(_oylamaId);
    if (result is Failure) {
      return (result as Failure).error.message;
    }
    await load();
    return null;
  }
}

final oylamaDetailProvider = StateNotifierProvider.family<OylamaDetailNotifier,
    OylamaDetailState, int>((ref, id) {
  return OylamaDetailNotifier(ref.read(oylamaRepositoryProvider), id);
});
