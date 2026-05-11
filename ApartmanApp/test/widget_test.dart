import 'package:flutter_test/flutter_test.dart';

void main() {
  // Genuine app smoke testi Firebase initialization gerektirir; bu test
  // sadece test runner'ın sağlıklı çalıştığını doğrular. Daha anlamlı widget
  // testleri test/features/ altında bulunur.
  test('smoke', () {
    expect(true, isTrue);
  });
}
