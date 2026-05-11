import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:apartman_app/core/paged_result.dart';
import 'package:apartman_app/core/result.dart';
import 'package:apartman_app/features/ariza/data/ariza_repository.dart';
import 'package:apartman_app/features/ariza/domain/ariza_model.dart';
import 'package:apartman_app/features/ariza/presentation/providers/ariza_provider.dart';

class MockArizaRepository extends Mock implements ArizaRepository {}

ArizaModel _ariza(int id) => ArizaModel(
      id: id,
      baslik: 'Arıza $id',
      aciklama: '',
      oncelik: ArizaOncelik.orta,
      durum: ArizaDurum.beklemede,
      tarih: DateTime.utc(2026, 4, 1),
      bildirenId: 1,
      bildirenAdSoyad: 'Test',
      bildirenDaireNo: '5',
    );

PagedResult<ArizaModel> _paged({
  required int page,
  required int totalCount,
  required List<ArizaModel> items,
}) =>
    PagedResult(
      items: items,
      page: page,
      pageSize: 20,
      totalCount: totalCount,
    );

void main() {
  late MockArizaRepository repo;

  setUp(() {
    repo = MockArizaRepository();
  });

  test('ctor ilk yüklemede page 1 çağırır ve state\'i doldurur', () async {
    when(() => repo.getArizalarPaged(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => Success(_paged(
          page: 1,
          totalCount: 25,
          items: [_ariza(1), _ariza(2)],
        )));

    final notifier = ArizaListNotifier(repo);
    // ctor içindeki async load() microtask'ları drain edilsin
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.arizalar, hasLength(2));
    expect(notifier.state.currentPage, 1);
    expect(notifier.state.totalCount, 25);
    expect(notifier.state.hasMore, isTrue);
  });

  test('loadMore sıradaki sayfayı listeye ekler', () async {
    int callCount = 0;
    when(() => repo.getArizalarPaged(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((invocation) async {
      callCount++;
      final page = invocation.namedArguments[#page] as int;
      return Success(_paged(
        page: page,
        totalCount: 25,
        items: [_ariza(page * 100), _ariza(page * 100 + 1)],
      ));
    });

    final notifier = ArizaListNotifier(repo);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await notifier.loadMore();

    expect(callCount, 2);
    expect(notifier.state.arizalar, hasLength(4));
    expect(notifier.state.currentPage, 2);
    expect(notifier.state.isLoadingMore, isFalse);
  });

  test('hasMore=false iken loadMore tekrar istek yapmaz', () async {
    when(() => repo.getArizalarPaged(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => Success(_paged(
          page: 1,
          totalCount: 1,
          items: [_ariza(1)],
        )));

    final notifier = ArizaListNotifier(repo);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.hasMore, isFalse);

    await notifier.loadMore();

    verify(() => repo.getArizalarPaged(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).called(1); // sadece ctor'daki ilk çağrı
  });
}
