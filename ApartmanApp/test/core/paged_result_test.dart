import 'package:flutter_test/flutter_test.dart';
import 'package:apartman_app/core/paged_result.dart';

void main() {
  group('PagedResult.fromJson', () {
    test('items, page, pageSize ve totalCount alanlarını parse eder', () {
      final json = {
        'items': [
          {'id': 1, 'name': 'a'},
          {'id': 2, 'name': 'b'},
        ],
        'page': 2,
        'pageSize': 20,
        'totalCount': 45,
      };

      final paged = PagedResult.fromJson(
        json,
        (m) => m['name'] as String,
      );

      expect(paged.items, ['a', 'b']);
      expect(paged.page, 2);
      expect(paged.pageSize, 20);
      expect(paged.totalCount, 45);
      expect(paged.totalPages, 3);
      expect(paged.hasNext, isTrue);
      expect(paged.hasPrev, isTrue);
    });

    test('boş items dizisinde güvenle çalışır', () {
      final paged = PagedResult.fromJson(
        {'items': [], 'page': 1, 'pageSize': 20, 'totalCount': 0},
        (m) => m['name'] as String,
      );

      expect(paged.items, isEmpty);
      expect(paged.totalPages, 0);
      expect(paged.hasNext, isFalse);
      expect(paged.hasPrev, isFalse);
    });

    test('eksik alanlarda varsayılan değerleri kullanır', () {
      final paged = PagedResult.fromJson(
        const <String, dynamic>{},
        (m) => m['name'] as String,
      );

      expect(paged.items, isEmpty);
      expect(paged.page, 1);
      expect(paged.pageSize, 20);
      expect(paged.totalCount, 0);
    });
  });
}
