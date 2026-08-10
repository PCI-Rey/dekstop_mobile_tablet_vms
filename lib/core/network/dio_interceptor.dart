import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class DioLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method.toUpperCase()} ${options.baseUrl}${options.path}');
      debugPrint('Headers:');
      options.headers.forEach((k, v) => debugPrint('  $k: $v'));
      if (options.queryParameters.isNotEmpty) {
        debugPrint('QueryParameters:');
        options.queryParameters.forEach((k, v) => debugPrint('  $k: $v'));
      }
      if (options.data != null) {
        debugPrint('Body: ${options.data}');
      }
      debugPrint('--> END ${options.method.toUpperCase()}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.baseUrl}${response.requestOptions.path}');
      debugPrint('Headers:');
      response.headers.forEach((k, v) => debugPrint('  $k: ${v.join(',')}'));
      debugPrint('Response: ${response.data}');
      debugPrint('<-- END HTTP');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ERROR: ${err.message}');
      if (err.response != null) {
        debugPrint('Status code: ${err.response?.statusCode}');
        debugPrint('Data: ${err.response?.data}');
      }
      debugPrint('<-- END ERROR');
    }
    handler.next(err);
  }
}
