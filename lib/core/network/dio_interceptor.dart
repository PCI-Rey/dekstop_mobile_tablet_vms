import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class DioLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('--> ${options.method.toUpperCase()} ${options.baseUrl}${options.path}');
      print('Headers:');
      options.headers.forEach((k, v) => print('  $k: $v'));
      if (options.queryParameters.isNotEmpty) {
        print('QueryParameters:');
        options.queryParameters.forEach((k, v) => print('  $k: $v'));
      }
      if (options.data != null) {
        print('Body: ${options.data}');
      }
      print('--> END ${options.method.toUpperCase()}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('<-- ${response.statusCode} ${response.requestOptions.baseUrl}${response.requestOptions.path}');
      print('Headers:');
      response.headers.forEach((k, v) => print('  $k: ${v.join(',')}'));
      print('Response: ${response.data}');
      print('<-- END HTTP');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('<-- ERROR: ${err.message}');
      if (err.response != null) {
        print('Status code: ${err.response?.statusCode}');
        print('Data: ${err.response?.data}');
      }
      print('<-- END ERROR');
    }
    handler.next(err);
  }
}
