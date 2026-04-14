/// API sonuçları için Result pattern
sealed class Result<T, E> {
  const Result();
}

class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

/// Uygulama hata sınıfı
class AppError {
  final String message;
  final int? statusCode;

  const AppError(this.message, {this.statusCode});

  @override
  String toString() => message;
}
