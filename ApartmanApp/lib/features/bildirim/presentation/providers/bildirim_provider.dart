import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bildirim_repository.dart';
import '../../data/bildirim_repository_impl.dart';
import '../../domain/bildirim_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final bildirimRepositoryProvider = Provider<BildirimRepository>((ref) {
  return BildirimRepositoryImpl(ref.read(apiServiceProvider));
});

class BildirimState {
  final List<BildirimModel> bildirimler;
  final bool isLoading;
  final String? error;

  const BildirimState({
    this.bildirimler = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => bildirimler.where((b) => !b.okundu).length;

  BildirimState copyWith({
    List<BildirimModel>? bildirimler,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BildirimState(
      bildirimler: bildirimler ?? this.bildirimler,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class BildirimNotifier extends StateNotifier<BildirimState> {
  final BildirimRepository _repo;

  BildirimNotifier(this._repo) : super(const BildirimState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getBildirimler();
    if (result is Success<List<BildirimModel>, AppError>) {
      state = state.copyWith(isLoading: false, bildirimler: result.data);
    } else if (result is Failure<List<BildirimModel>, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> markAsRead(int bildirimId) async {
    final result = await _repo.markAsRead(bildirimId);
    if (result is Success) {
      state = state.copyWith(
        bildirimler: state.bildirimler
            .map((b) => b.id == bildirimId ? b.copyWith(okundu: true) : b)
            .toList(),
      );
    }
  }
}

final bildirimProvider =
    StateNotifierProvider<BildirimNotifier, BildirimState>((ref) {
  return BildirimNotifier(ref.read(bildirimRepositoryProvider));
});
