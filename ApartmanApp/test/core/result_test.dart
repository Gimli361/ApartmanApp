import 'package:flutter_test/flutter_test.dart';
import 'package:apartman_app/core/result.dart';

void main() {
  group('Result pattern', () {
    test('Success data içerir ve pattern matching ile yakalanır', () {
      const Result<int, AppError> result = Success(42);

      expect(result, isA<Success<int, AppError>>());
      if (result is Success<int, AppError>) {
        expect(result.data, 42);
      }
    });

    test('Failure error içerir ve pattern matching ile yakalanır', () {
      const Result<int, AppError> result =
          Failure(AppError('Bağlantı hatası', statusCode: 503));

      expect(result, isA<Failure<int, AppError>>());
      if (result is Failure<int, AppError>) {
        expect(result.error.message, 'Bağlantı hatası');
        expect(result.error.statusCode, 503);
      }
    });

    test('AppError.toString message döner', () {
      const err = AppError('Test mesajı');
      expect(err.toString(), 'Test mesajı');
    });
  });
}
