import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bildirim_repository.dart';
import '../../data/bildirim_repository_impl.dart';
import '../../domain/bildirim_model.dart';
import '../../../../core/paged_result.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final bildirimRepositoryProvider = Provider<BildirimRepository>((ref) {
  return BildirimRepositoryImpl(ref.read(apiServiceProvider));
});

class BildirimState {
  final List<BildirimModel> bildirimler;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalCount;
  final bool hasMore;

  const BildirimState({
    this.bildirimler = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.totalCount = 0,
    this.hasMore = true,
  });

  int get unreadCount => bildirimler.where((b) => !b.okundu).length;

  BildirimState copyWith({
    List<BildirimModel>? bildirimler,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
  }) {
    return BildirimState(
      bildirimler: bildirimler ?? this.bildirimler,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class BildirimNotifier extends StateNotifier<BildirimState> {
  final BildirimRepository _repo;
  static const _pageSize = 20;

  BildirimNotifier(this._repo) : super(const BildirimState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getBildirimlerPaged(page: 1, pageSize: _pageSize);
    if (result is Success<PagedResult<BildirimModel>, AppError>) {
      final paged = result.data;
      state = state.copyWith(
        isLoading: false,
        bildirimler: paged.items,
        currentPage: paged.page,
        totalCount: paged.totalCount,
        hasMore: paged.hasNext,
      );
    } else if (result is Failure<PagedResult<BildirimModel>, AppError>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repo.getBildirimlerPaged(
      page: state.currentPage + 1,
      pageSize: _pageSize,
    );
    if (result is Success<PagedResult<BildirimModel>, AppError>) {
      final paged = result.data;
      state = state.copyWith(
        isLoadingMore: false,
        bildirimler: [...state.bildirimler, ...paged.items],
        currentPage: paged.page,
        totalCount: paged.totalCount,
        hasMore: paged.hasNext,
      );
    } else if (result is Failure<PagedResult<BildirimModel>, AppError>) {
      state = state.copyWith(isLoadingMore: false, error: result.error.message);
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

  Future<void> markAllAsRead() async {
    final result = await _repo.markAllAsRead();
    if (result is Success) {
      state = state.copyWith(
        bildirimler: state.bildirimler
            .map((b) => b.copyWith(okundu: true))
            .toList(),
      );
    }
  }

  Future<String?> sendDuyuru(String baslik, String icerik) async {
    final result = await _repo.sendDuyuru(baslik, icerik);
    if (result is Failure<void, AppError>) {
      return result.error.message;
    }
    return null;
  }

  Future<String?> sendBlokBildirim(
      String blokNo, String baslik, String icerik) async {
    final result = await _repo.sendBlokBildirim(blokNo, baslik, icerik);
    if (result is Failure<void, AppError>) return result.error.message;
    return null;
  }

  Future<String?> sendDaireBildirim(
      String daireNo, String baslik, String icerik, {String? blokNo}) async {
    final result =
        await _repo.sendDaireBildirim(daireNo, baslik, icerik, blokNo: blokNo);
    if (result is Failure<void, AppError>) return result.error.message;
    return null;
  }
}

final bildirimProvider =
    StateNotifierProvider<BildirimNotifier, BildirimState>((ref) {
  return BildirimNotifier(ref.read(bildirimRepositoryProvider));
});
