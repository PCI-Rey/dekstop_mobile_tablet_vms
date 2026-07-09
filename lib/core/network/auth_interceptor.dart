import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../services/storage_service.dart';
import '../shared/routes/app_pages.dart';

class AuthInterceptor extends QueuedInterceptor {
  final StorageService _storageService;
  
  AuthInterceptor(this._storageService);

  // Locked completer to prevent concurrent 401s from launching multiple refresh requests
  static Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;
      
      // If refresh is already in progress, wait for it
      final isRefreshing = _refreshCompleter != null;
      
      if (!isRefreshing) {
        _refreshCompleter = Completer<String?>();
        _performRefresh().then((newToken) {
          _refreshCompleter?.complete(newToken);
          _refreshCompleter = null;
        }).catchError((error) {
          _refreshCompleter?.complete(null);
          _refreshCompleter = null;
        });
      }

      // Wait for the single active refresh process to complete
      final newToken = await _refreshCompleter!.future;

      if (newToken != null && newToken.isNotEmpty) {
        // Update request header and retry
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        
        try {
          // Re-send the request with a clean, standalone Dio instance to avoid cycles
          final retryDio = Dio(BaseOptions(
            baseUrl: requestOptions.baseUrl,
            connectTimeout: requestOptions.connectTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
          ));
          
          final response = await retryDio.request(
            requestOptions.path,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
              responseType: requestOptions.responseType,
              contentType: requestOptions.contentType,
            ),
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
          );
          
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else {
        // Refresh token failed -> Force Logout
        await _storageService.clearTokens();
        Get.offAllNamed(AppRoutes.login);
        return handler.next(err);
      }
    }
    
    handler.next(err);
  }

  Future<String?> _performRefresh() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final serverUrl = await _storageService.getServerUrl();
      
      // Special logic for local demo server testing:
      if (serverUrl.contains('example.com') || serverUrl.contains('localhost') || serverUrl.isEmpty) {
        // Simulate a successful refresh token response for demo/preview purposes
        await Future.delayed(const Duration(milliseconds: 1500));
        final newAccess = 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
        final newRefresh = 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
        await _storageService.saveAccessToken(newAccess);
        await _storageService.saveRefreshToken(newRefresh);
        return newAccess;
      }

      // Standalone dio to execute refresh call
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.post('/refresh-token', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String?;
        
        await _storageService.saveAccessToken(newAccess);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _storageService.saveRefreshToken(newRefresh);
        }
        return newAccess;
      }
    } catch (_) {
      // Any error during refresh fails the auth flow
    }
    return null;
  }
}
