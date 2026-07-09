import 'network_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data) = Success<T>;
  factory ApiResult.failure(NetworkException exception) = Failure<T>;
  factory ApiResult.loading() = Loading<T>;
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final NetworkException exception;
  const Failure(this.exception);
}

class Loading<T> extends ApiResult<T> {
  const Loading();
}
