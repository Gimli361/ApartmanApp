import 'package:flutter_test/flutter_test.dart';
import 'package:apartman_app/features/aidat/domain/aidat_model.dart';

void main() {
  group('AidatModel.fromJson', () {
    test('tam JSON\'u doğru parse eder', () {
      final json = {
        'id': 7,
        'kullaniciId': 3,
        'kullaniciAdSoyad': 'Ahmet Yılmaz',
        'daireNo': '12',
        'tutar': 350.5,
        'ay': 4,
        'yil': 2026,
        'odemeDurumu': 'Odendi',
        'odemeTarihi': '2026-04-15T10:00:00Z',
      };

      final aidat = AidatModel.fromJson(json);

      expect(aidat.id, 7);
      expect(aidat.tutar, 350.5);
      expect(aidat.odemeDurumu, OdemeDurumu.odendi);
      expect(aidat.odemeTarihi, DateTime.utc(2026, 4, 15, 10));
    });

    test('opsiyonel alanlar eksikken default değerler döner', () {
      final aidat = AidatModel.fromJson({
        'id': 1,
        'kullaniciId': 1,
        'tutar': 100,
        'ay': 1,
        'yil': 2026,
        'odemeDurumu': null,
      });

      expect(aidat.kullaniciAdSoyad, '');
      expect(aidat.daireNo, '');
      expect(aidat.odemeDurumu, OdemeDurumu.beklemede);
      expect(aidat.odemeTarihi, isNull);
    });

    test('Gecikti string\'i doğru enum\'a çevrilir', () {
      final aidat = AidatModel.fromJson({
        'id': 1,
        'kullaniciId': 1,
        'tutar': 100,
        'ay': 1,
        'yil': 2026,
        'odemeDurumu': 'Gecikti',
      });

      expect(aidat.odemeDurumu, OdemeDurumu.gecikti);
    });
  });
}
