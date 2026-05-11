import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:apartman_app/core/result.dart';
import 'package:apartman_app/features/aidat/data/aidat_repository.dart';
import 'package:apartman_app/features/aidat/domain/aidat_model.dart';
import 'package:apartman_app/features/aidat/presentation/providers/aidat_provider.dart';

class MockAidatRepository extends Mock implements AidatRepository {}

AidatModel _aidat({
  int id = 1,
  OdemeDurumu durum = OdemeDurumu.beklemede,
}) =>
    AidatModel(
      id: id,
      kullaniciId: 10,
      kullaniciAdSoyad: 'Test Sakin',
      daireNo: '5',
      tutar: 250.0,
      ay: 4,
      yil: 2026,
      odemeDurumu: durum,
    );

void main() {
  late MockAidatRepository repo;

  setUp(() {
    repo = MockAidatRepository();
  });

  group('AidatNotifier.loadAll', () {
    test('başarı durumu state\'e aidatları yazar', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => Success([_aidat(id: 1), _aidat(id: 2)]),
      );

      final notifier = AidatNotifier(repo);
      await notifier.loadAll();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.aidatlar, hasLength(2));
      verify(() => repo.getAll()).called(1);
    });

    test('hata durumu error mesajını state\'e yazar', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => const Failure(AppError('Sunucuya ulaşılamıyor')),
      );

      final notifier = AidatNotifier(repo);
      await notifier.loadAll();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Sunucuya ulaşılamıyor');
      expect(notifier.state.aidatlar, isEmpty);
    });
  });

  group('AidatNotifier.updateOdemeDurum', () {
    test('başarıda listedeki kaydı günceller', () async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => Success([_aidat(id: 1, durum: OdemeDurumu.beklemede)]),
      );
      when(() => repo.updateOdemeDurum(1, OdemeDurumu.odendi)).thenAnswer(
        (_) async => Success(_aidat(id: 1, durum: OdemeDurumu.odendi)),
      );

      final notifier = AidatNotifier(repo);
      await notifier.loadAll();
      await notifier.updateOdemeDurum(1, OdemeDurumu.odendi);

      expect(notifier.state.aidatlar.single.odemeDurumu, OdemeDurumu.odendi);
    });
  });

  test('repository provider override ile container test edilebilir', () {
    when(() => repo.getAll()).thenAnswer((_) async => const Success([]));

    final container = ProviderContainer(overrides: [
      aidatRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    expect(container.read(aidatProvider).aidatlar, isEmpty);
  });
}
