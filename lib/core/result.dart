sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;
}
