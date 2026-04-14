import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/otomatik_aidat_model.dart';
import '../../../../core/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/services/api_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class OtomatikAidatState {
  final List<OtomatikAidatModel> liste;
  final bool isLoading;
  final String? error;

  const OtomatikAidatState({
    this.liste = const [],
    this.isLoading = false,
    this.error,
  });

  OtomatikAidatState copyWith({
    List<OtomatikAidatModel>? liste,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OtomatikAidatState(
      liste: liste ?? this.liste,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class OtomatikAidatNotifier extends StateNotifier<OtomatikAidatState> {
  final ApiService _api;

  OtomatikAidatNotifier(this._api) : super(const OtomatikAidatState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.dio.get('/api/otomatik-aidat');
      final list = (res.data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OtomatikAidatModel.fromJson)
          .toList();
      state = state.copyWith(isLoading: false, liste: list);
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false, error: ApiService.handleDioError(e).message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Kullanıcı için otomatik aidat oluştur ya da güncelle
  Future<Result<void, AppError>> upsert(int kullaniciId, double tutar) async {
    try {
      final res = await _api.dio.post('/api/otomatik-aidat',
          data: {'kullaniciId': kullaniciId, 'tutar': tutar});
      final model = OtomatikAidatModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
      final idx = state.liste.indexWhere((o) => o.id == model.id);
      if (idx >= 0) {
        final updated = [...state.liste];
        updated[idx] = model;
        state = state.copyWith(liste: updated);
      } else {
        state = state.copyWith(liste: [model, ...state.liste]);
      }
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  /// Aktif/pasif geçiş
  Future<void> toggle(int id) async {
    try {
      final res = await _api.dio.patch('/api/otomatik-aidat/$id/toggle');
      final model = OtomatikAidatModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
      state = state.copyWith(
        liste: state.liste.map((o) => o.id == id ? model : o).toList(),
      );
    } on DioException catch (_) {}
  }

  /// Tutar güncelle
  Future<Result<void, AppError>> updateTutar(int id, double tutar) async {
    try {
      final res = await _api.dio
          .patch('/api/otomatik-aidat/$id/tutar', data: {'tutar': tutar});
      final model = OtomatikAidatModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
      state = state.copyWith(
        liste: state.liste.map((o) => o.id == id ? model : o).toList(),
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }

  /// Sil
  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('/api/otomatik-aidat/$id');
      state =
          state.copyWith(liste: state.liste.where((o) => o.id != id).toList());
    } on DioException catch (_) {}
  }

  /// Manuel tetikleme — bu ay için üret
  Future<Result<String, AppError>> uretBuAy() async {
    final now = DateTime.now();
    try {
      final res = await _api.dio.post('/api/otomatik-aidat/uret',
          data: {'ay': now.month, 'yil': now.year});
      final uretilen = res.data['uretilen'] as int;
      // Üretildiyse liste yenile
      if (uretilen > 0) await load();
      return Success('$uretilen aidat kaydı oluşturuldu.');
    } on DioException catch (e) {
      return Failure(ApiService.handleDioError(e));
    } catch (e) {
      return Failure(AppError(e.toString()));
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final otomatikAidatProvider =
    StateNotifierProvider<OtomatikAidatNotifier, OtomatikAidatState>((ref) {
  return OtomatikAidatNotifier(ref.read(apiServiceProvider));
});
