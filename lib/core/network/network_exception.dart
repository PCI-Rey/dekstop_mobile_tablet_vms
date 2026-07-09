import 'package:dio/dio.dart';

sealed class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  static NetworkException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Koneksi terputus. Silakan coba lagi.');
      case DioExceptionType.connectionError:
        return const NoInternetException('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final statusMessage = error.response?.data?['message'] ?? error.response?.statusMessage;
        
        if (statusCode == 401) {
          return UnauthorizedException(statusMessage ?? 'Sesi telah berakhir. Silakan masuk kembali.');
        } else if (statusCode == 403) {
          return const ServerException(statusCode: 403, message: 'Akses ditolak.');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(statusCode: statusCode, message: 'Terjadi kesalahan internal server.');
        }
        return ServerException(statusCode: statusCode, message: statusMessage ?? 'Terjadi kesalahan pada server.');
      case DioExceptionType.cancel:
        return const UnknownException('Permintaan dibatalkan.');
      default:
        return const UnknownException('Terjadi kesalahan yang tidak diketahui.');
    }
  }
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException([super.message = 'Sesi telah berakhir. Silakan masuk kembali.']);
}

class NoInternetException extends NetworkException {
  const NoInternetException([super.message = 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.']);
}

class TimeoutException extends NetworkException {
  const TimeoutException([super.message = 'Waktu permintaan habis.']);
}

class ServerException extends NetworkException {
  final int? statusCode;
  const ServerException({this.statusCode, String message = 'Terjadi kesalahan server.'}) : super(message);
}

class UnknownException extends NetworkException {
  const UnknownException([super.message = 'Terjadi kesalahan sistem.']);
}
