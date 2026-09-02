import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'api_result.dart';
import 'network_exception.dart';
import 'auth_interceptor.dart';
import 'dio_interceptor.dart';

class DioClient {
  final StorageService _storageService;
  late final Dio _dio;

  DioClient(this._storageService) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(_storageService),
      DioLoggingInterceptor(),
    ]);
  }

  Future<Dio> get dio async {
    final baseUrl = await _storageService.getServerUrl();
    _dio.options.baseUrl = baseUrl;
    return _dio;
  }

  // Wrapper for GET requests
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        final isDemo = await _isDemoServer();
        if (isDemo) {
          return await _handleDemoGet(path, queryParameters, fromJson);
        }

        final activeDio = await dio;
        final response = await activeDio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );

        if (fromJson != null) {
          return ApiResult.success(fromJson(response.data));
        } else {
          return ApiResult.success(response.data as T);
        }
      } on DioException catch (e) {
        final errStr = '${e.message ?? ''} ${e.error ?? ''}';
        final isTransient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            errStr.contains('semaphore') ||
            errStr.contains('SocketException') ||
            errStr.contains('Software caused connection abort');

        if (isTransient && attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(NetworkException.fromDioException(e));
      } catch (e) {
        final errStr = e.toString();
        if (attempts < maxAttempts &&
            (errStr.contains('semaphore') ||
                errStr.contains('SocketException') ||
                errStr.contains('TimeoutException'))) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(UnknownException(e.toString()));
      }
    }
  }

  // Wrapper for POST requests
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        final isDemo = await _isDemoServer();
        if (isDemo) {
          return await _handleDemoPost(path, data, fromJson);
        }

        final activeDio = await dio;
        Options reqOptions = options ?? Options();
        if (data is FormData) {
          activeDio.options.headers.remove('Content-Type');
          activeDio.options.headers.remove('content-type');
          final customHeaders = Map<String, dynamic>.from(reqOptions.headers ?? {});
          customHeaders.remove('Content-Type');
          customHeaders.remove('content-type');
          reqOptions = reqOptions.copyWith(
            headers: customHeaders,
            contentType: null,
          );
        } else {
          activeDio.options.contentType = 'application/json';
        }

        final response = await activeDio.post(
          path,
          data: data,
          queryParameters: queryParameters,
          options: reqOptions,
        );

        if (fromJson != null) {
          return ApiResult.success(fromJson(response.data));
        } else {
          return ApiResult.success(response.data as T);
        }
      } on DioException catch (e) {
        final errStr = '${e.message ?? ''} ${e.error ?? ''}';
        final isTransient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            errStr.contains('semaphore') ||
            errStr.contains('SocketException') ||
            errStr.contains('Software caused connection abort');

        if (isTransient && attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(NetworkException.fromDioException(e));
      } catch (e) {
        final errStr = e.toString();
        if (attempts < maxAttempts &&
            (errStr.contains('semaphore') ||
                errStr.contains('SocketException') ||
                errStr.contains('TimeoutException'))) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(UnknownException(e.toString()));
      }
    }
  }

  // Wrapper for PUT requests
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        final isDemo = await _isDemoServer();
        if (isDemo) {
          return await _handleDemoPost(path, data, fromJson);
        }

        final activeDio = await dio;
        Options reqOptions = options ?? Options();
        if (data is FormData) {
          activeDio.options.headers.remove('Content-Type');
          activeDio.options.headers.remove('content-type');
          final customHeaders = Map<String, dynamic>.from(reqOptions.headers ?? {});
          customHeaders.remove('Content-Type');
          customHeaders.remove('content-type');
          reqOptions = reqOptions.copyWith(
            headers: customHeaders,
            contentType: null,
          );
        } else {
          activeDio.options.contentType = 'application/json';
        }

        final response = await activeDio.put(
          path,
          data: data,
          queryParameters: queryParameters,
          options: reqOptions,
        );

        if (fromJson != null) {
          return ApiResult.success(fromJson(response.data));
        } else {
          return ApiResult.success(response.data as T);
        }
      } on DioException catch (e) {
        final errStr = '${e.message ?? ''} ${e.error ?? ''}';
        final isTransient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            errStr.contains('semaphore') ||
            errStr.contains('SocketException') ||
            errStr.contains('Software caused connection abort');

        if (isTransient && attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(NetworkException.fromDioException(e));
      } catch (e) {
        final errStr = e.toString();
        if (attempts < maxAttempts &&
            (errStr.contains('semaphore') ||
                errStr.contains('SocketException') ||
                errStr.contains('TimeoutException'))) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(UnknownException(e.toString()));
      }
    }
  }

  // Wrapper for PATCH requests
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJson,
  }) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        final isDemo = await _isDemoServer();
        if (isDemo) {
          return await _handleDemoPost(path, data, fromJson);
        }

        final activeDio = await dio;
        final response = await activeDio.patch(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );

        if (fromJson != null) {
          return ApiResult.success(fromJson(response.data));
        } else {
          return ApiResult.success(response.data as T);
        }
      } on DioException catch (e) {
        final errStr = '${e.message ?? ''} ${e.error ?? ''}';
        final isTransient = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            errStr.contains('semaphore') ||
            errStr.contains('SocketException') ||
            errStr.contains('Software caused connection abort');

        if (isTransient && attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(NetworkException.fromDioException(e));
      } catch (e) {
        final errStr = e.toString();
        if (attempts < maxAttempts &&
            (errStr.contains('semaphore') ||
                errStr.contains('SocketException') ||
                errStr.contains('TimeoutException'))) {
          await Future.delayed(Duration(milliseconds: 350 * attempts));
          continue;
        }
        return ApiResult.failure(UnknownException(e.toString()));
      }
    }
  }

  Future<bool> _isDemoServer() async {
    final url = await _storageService.getServerUrl();
    return url.contains('example.com') || url.isEmpty;
  }

  // Simulating backend endpoints when no real backend server is plugged in
  Future<ApiResult<T>> _handleDemoGet<T>(
    String path,
    Map<String, dynamic>? queryParams,
    T Function(dynamic json)? fromJson,
  ) async {
    if (path.contains('/visitor/transaction/dt')) {
      final mockDt = _getMockTransactionDataTable();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockDt));
      }
      return ApiResult.success(mockDt as T);
    } else if (path.contains('/visitor/transaction/') && path.contains('/visitors')) {
      final mockTrxVisitors = _getMockTransactionVisitors();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockTrxVisitors));
      }
      return ApiResult.success(mockTrxVisitors as T);
    } else if (path.contains('/visitors')) {
      final mockData = _getMockVisitors();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockData));
      }
      return ApiResult.success(mockData as T);
    } else if (path.contains('/dashboard-summary')) {
      final mockSummary = _getMockDashboardSummary();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockSummary));
      }
      return ApiResult.success(mockSummary as T);
    } else if (path.contains('/operator-invitation/invitation-related-visitor')) {
      final mockRelated = _getMockInvitationRelatedVisitors();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockRelated));
      }
      return ApiResult.success(mockRelated as T);
    } else if (path.contains('/operator-invitation/search')) {
      final mockSearch = _getMockSearchResult();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockSearch));
      }
      return ApiResult.success(mockSearch as T);
    } else if (path.contains('/profile/me')) {
      final mockProfile = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": {
          "user_id": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "organization_name": "Organization SA",
          "department_name": "",
          "district_name": "",
          "group_name": "OperatorVMS",
          "email": "operator@gmail.com",
          "username": "",
          "fullname": "Operator 1",
          "gender": "Other",
          "address": "Operator 1",
          "phone": "",
          "is_vip": false,
          "is_email_verified": true
        }
      };
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockProfile));
      }
      return ApiResult.success(mockProfile as T);
    } else if (path.contains('user-permission')) {
      final mockPermissions = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": {
          "permissions": [
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "AllowSSOActiveDirectory",
              "id": "2fb627c3-f418-4953-bf89-21efb21b116a"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "OperatorRegisterSite",
              "id": "b1cc4bea-f861-48cf-b7b5-25230013f7e1"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageBlacklist",
              "id": "cdf0967f-ca0a-465c-8574-386d93816f6c"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageVisitor",
              "id": "cb81871e-512a-4c7f-b445-42441684568d"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageAccessScope",
              "id": "6f3be5f6-282f-4223-b627-4a95e9df1418"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "AllowMobileLogin",
              "id": "589d6c81-4330-4f8e-bf4c-61830810f4cf"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageSiteScope",
              "id": "ed251d90-b55c-4f4b-a96d-64181e4335fa"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "OrganizationAssignment",
              "id": "683b2c5e-296d-43c0-8c94-7798b1332fa7"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "OperatorAsWatcher",
              "id": "9403e44c-762e-4479-b4cc-7cd1428e82d6"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageVisitorTypeScope",
              "id": "c61710b0-9868-475a-9e04-bbf5d19f8657"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "ManageInvite",
              "id": "e9bd6e6a-88c2-4df3-82e5-d6fc23b00090"
            },
            {
              "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
              "permission": "AsHead",
              "id": "e775e332-4724-4c88-bfaf-e2339e722ccd"
            }
          ],
          "scopes": {
            "manage_visitors": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorSendNotificationArrival",
                "id": "a512268a-9bc8-49d1-8483-0c8b86e577f2"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorCardIssuance",
                "id": "9d78238c-84f5-45fe-bc02-1027addb5d4c"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorExtend",
                "id": "ee6854dc-b0b2-472a-8e01-2d6c8c43c63c"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorBlock",
                "id": "501c62e7-0ead-48ed-a48b-37361dacfe79"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorTriggerOpen",
                "id": "3574032e-3338-4d5b-8b03-4a69ba220cbc"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorPreregister",
                "id": "786461c7-4e6c-482d-9bdb-5bd8876871ef"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorParkingIssuance",
                "id": "d307e812-53b7-4a63-a58a-a2b139a497fd"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorCheckIn",
                "id": "57462968-ba2f-4cfe-b636-a6d11c9edc6c"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorWalkIn",
                "id": "0c440560-9298-499e-9a4d-e45929e75c6e"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "OperatorVisitorCheckout",
                "id": "cbc7aec5-8f2a-433a-9bea-e73548356aed"
              }
            ],
            "organization_assignments": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "organization_id": "01c94b9c-fac5-4155-8859-72d07db3656c",
                "organization_type": "Organization",
                "id": "ed89635c-f448-4eca-8a54-12efd28493e2"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "organization_id": "039e6d9c-e4f2-48d1-aef7-7cf59dd87f4e",
                "organization_type": "Organization",
                "id": "589c5eed-4cac-4f73-b7ef-cac865fd6a03"
              }
            ],
            "site_assignments": [],
            "manage_sites": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "e3facb54-eae1-48d5-9457-3ef7d3f7ba3b",
                "can_grant": false,
                "can_revoke": false,
                "can_block": false,
                "permission": "ManageSiteScope",
                "id": "6682fb07-622b-4226-bd71-f051ca63d937"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "f1157454-cce7-42d5-bccb-c23136c6319b",
                "can_grant": false,
                "can_revoke": false,
                "can_block": false,
                "permission": "ManageSiteScope",
                "id": "831257b9-fe09-4b86-ba05-831bb7c8ac40"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "9bcb7f68-11c9-446b-89e7-ea6ba28d3914",
                "can_grant": false,
                "can_revoke": false,
                "can_block": false,
                "permission": "ManageSiteScope",
                "id": "756c1b45-bf15-4021-94a3-370aec7ffd98"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "8a87a302-5812-4b45-b5ce-0ce2a54f45b5",
                "can_grant": false,
                "can_revoke": false,
                "can_block": false,
                "permission": "ManageSiteScope",
                "id": "a73a38d1-f512-4ef0-8a5b-a67b5e926972"
              }
            ],
            "visitor_type_assignments": [],
            "manage_visitor_types": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "3e903b97-bb4a-42bb-a840-b2316202ea7d",
                "permission": "ManageVisitorTypeScope",
                "id": "8ea66333-22bd-4d1c-954a-47bb93fb1409"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "e0533de1-52a7-4b47-8e80-79239d8f723d",
                "permission": "ManageVisitorTypeScope",
                "id": "e9cbdc1b-c764-4e63-9709-54be0e6522e3"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "4bd22555-12fc-4aea-84a3-2163fe7dadc7",
                "permission": "ManageVisitorTypeScope",
                "id": "1cf5890a-895a-4cbb-8600-e5fed8759879"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "b3618bd5-b6f0-4329-9cf5-6c853970217d",
                "permission": "ManageVisitorTypeScope",
                "id": "c2d66c8d-54bb-4af3-af64-f421ed0862e5"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "2e8a7639-84f9-42ab-8096-304c259245db",
                "permission": "ManageVisitorTypeScope",
                "id": "48ab8e6e-bb95-4319-ab26-b6ccd948db69"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
                "permission": "ManageVisitorTypeScope",
                "id": "e529a89c-9533-4f2e-960a-c04eb2473aea"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "29b12a27-cff3-44dc-be0f-4a743510b836",
                "permission": "ManageVisitorTypeScope",
                "id": "a06a110d-a289-41ad-8861-ad648725e447"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "f0bd33a4-427a-4110-ab19-6e423dafa3e5",
                "permission": "ManageVisitorTypeScope",
                "id": "165372ef-ebb7-44e3-afd6-b06ec188a295"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "visitor_type_id": "0eac503e-d0c9-4ba5-afac-99a0b94e44f3",
                "permission": "ManageVisitorTypeScope",
                "id": "b4f83d74-1f2d-4c6c-bcf6-b801d6da493f"
              }
            ],
            "manage_accesss": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "84140f2d-df77-4514-806f-6aa821523f9e",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "2c616f7b-ce82-4601-a3ac-732b4e4f6c8b"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "60f53801-59ed-44b5-87b7-619c88c96407",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "8cdc06ca-24cd-4ecf-8b47-80b21e3f53c9"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "6f647a1a-96bd-4e36-805c-c9ff23160966",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "26633531-5b71-4c60-896e-8f53fd380cd7"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "b70849f0-1579-4030-bf04-e95db722b833",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "1b18c66d-2c56-4902-9143-bee34a95c40e"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "acf244a4-d48f-4e8c-8a4a-69219305971c",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "4797c7d8-3439-40d3-b8fd-e5511bbbbd72"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "permission": "ManageAccessScope",
                "access_control_id": "f6228599-adb4-4216-8a3c-c0e786c32557",
                "can_revoke": true,
                "can_grant": true,
                "can_block": true,
                "id": "a65296f1-2771-4578-bf70-ee2e8babbe73"
              }
            ],
            "manage_registersites": [
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "1d6c9704-f6ab-47bd-a6b0-3e1fb3d6faea",
                "permission": "OperatorRegisterSite",
                "id": "6a923ced-df6b-40f6-aa25-5fb18b070aaa"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "86f01873-ea70-4ccf-a014-6438f14dbe93",
                "permission": "OperatorRegisterSite",
                "id": "968e7f76-e028-4b35-a2a9-8fe33436df7d"
              },
              {
                "user_group_id": "cbff225d-7514-40ad-90b5-2a257e1f5056",
                "site_id": "e3facb54-eae1-48d5-9457-3ef7d3f7ba3b",
                "permission": "OperatorRegisterSite",
                "id": "197f9dd6-9951-47f3-ba3d-e1f3cb1fb78c"
              }
            ]
          }
        }
      };
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockPermissions));
      }
      return ApiResult.success(mockPermissions as T);
    }

    return ApiResult.failure(const ServerException(statusCode: 404, message: 'Resource not found in Demo server.'));
  }

  Future<ApiResult<T>> _handleDemoPost<T>(String path, dynamic data, T Function(dynamic json)? fromJson) async {
    if (path.contains('/visitor/transaction/dt')) {
      final mockDt = _getMockTransactionDataTable();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockDt));
      }
      return ApiResult.success(mockDt as T);
    }

    if (path.contains('/operator-invitation/action')) {
      final mockActionRes = {
        'status': 'success',
        'status_code': 200,
        'title': 'success',
        'msg': 'Action executed successfully',
      };
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockActionRes));
      }
      return ApiResult.success(mockActionRes as T);
    }

    if (path.contains('/operator-invitation/extend-period')) {
      final mockExtendRes = {
        'status': 'success',
        'status_code': 200,
        'title': 'success',
        'msg': 'Period extended successfully',
      };
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockExtendRes));
      }
      return ApiResult.success(mockExtendRes as T);
    }

    if (path.contains('/operator-invitation/search')) {
      final mockSearch = _getMockSearchResult();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockSearch));
      }
      return ApiResult.success(mockSearch as T);
    }

    if (path.contains('/_Auth/RequestToken') || path.contains('/login')) {
      final username = (data['username'] ?? '').toString().trim();
      final password = (data['password'] ?? '').toString().trim();
      
      if (username.isEmpty || password.isEmpty) {
        return ApiResult.failure(const ServerException(statusCode: 400, message: 'Username and password are required.'));
      }

      // Strictly validate operator credentials: username == 'operator' && password == 'admin'
      if (username != 'operator' || password != 'admin') {
        return ApiResult.failure(const ServerException(statusCode: 401, message: 'Invalid username or password.'));
      }

      final mockLoginResult = {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'username': username,
          'name': 'Operator Bank Indonesia',
          'email': 'operator@bi.go.id',
          'department': 'Security & Facility Control',
          'role': 'Operator',
          'avatar': 'assets/images/ava_person1.png',
          'device_info': 'Samsung Galaxy Tab SM-X200',
          'app_version': '1.0.0',
        }
      };

      if (fromJson != null) {
        return ApiResult.success(fromJson(mockLoginResult));
      }
      return ApiResult.success(mockLoginResult as T);
    } else if (path.contains('/visitor/checkin') || path.contains('/visitor/checkout') || path.contains('/visitor/action')) {
      return ApiResult.success({'status': 'success', 'message': 'Aksi berhasil diproses'} as T);
    }

    return ApiResult.failure(const ServerException(statusCode: 404, message: 'Resource not found in Demo server.'));
  }

  Map<String, dynamic> _getMockVisitors() {
    return {
      'selected': {
        'id': '8057210110',
        'name': 'Maza Instansi',
        'company': 'Instansi Maza',
        'phone': '085123123412',
        'email': 'maza24@gmail.com',
        'id_card_no': '8057210110',
        'gender': 'Laki-laki',
        'nationality': 'Indonesia',
        'status': 'Checked In',
        'vip': true,
        'frequent': true,
        'verified': true,
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&h=300',
        'address': 'Jl. Kemang Raya No. 42, Jakarta Selatan',
        'organization': 'PT. Maju Jaya Bersama',
        'occupation': 'Marketing Manager',
        'id_type': 'KTP',
        'id_number': '3175050101990001',
        'visit_purpose': 'Pertemuan Bisnis & Pembahasan Kontrak Kerjasama',
        'host': 'John Doe',
        'host_title': 'IT Manager',
        'host_phone': 'Ext. 2234',
        'host_email': 'john.doe@company.com',
        'host_avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fit=crop&w=150&h=150',
        'host_status': 'Available',
        'department': 'IT Department',
        'visit_period': '14 Jan 2026, 09:00 - 14 Jan 2026, 18:00',
        'created_by': 'Admin Lobby A',
        'qr_code_data': 'QRXMFQ-HGNLFT',
        'check_in_time': '14 Jan 2026, 09:47',
        'check_out_time': '-',
        'ticket_no': '8057210110',
        'invitation_code': 'QRXMFQ-HGNLFT',
        'visit_type': 'Meeting',
        'identity_doc_url': 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?fit=crop&w=600&h=400',
      },
      'related': [
        {
          'initials': 'AW',
          'name': 'Andi Wijaya',
          'company': 'PT. Maju Jaya',
          'date': '10 Jan 2026',
          'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?fit=crop&w=150&h=150',
          'vip': false,
        },
        {
          'initials': 'BS',
          'name': 'Budi Santoso',
          'company': 'PT. Maju Jaya',
          'date': '09 Jan 2026',
          'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=150&h=150',
          'vip': false,
        },
        {
          'initials': 'DK',
          'name': 'Dewi Kartika',
          'company': 'PT. Maju Jaya',
          'date': '03 Jan 2026',
          'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?fit=crop&w=150&h=150',
          'vip': true,
        },
        {
          'initials': 'CL',
          'name': 'Citra Lestari',
          'company': 'PT. Maju Jaya',
          'date': '02 Jan 2026',
          'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=150&h=150',
          'vip': false,
        }
      ],
      'timeline': [
        {
          'time': '09:30',
          'title': 'Invitation Created',
          'desc': 'By John Doe',
          'status': 'invitation',
        },
        {
          'time': '09:45',
          'title': 'Arrived at Lobby',
          'desc': 'Face recognition matched',
          'status': 'arrived',
        },
        {
          'time': '09:47',
          'title': 'Checked In',
          'desc': 'By Operator 1',
          'status': 'checked_in',
        },
        {
          'time': '09:48',
          'title': 'Card Issued',
          'desc': 'Card No. 8057210110',
          'status': 'card_issued',
        }
      ]
    };
  }

  Map<String, dynamic> _getMockDashboardSummary() {
    return {
      'occupancy': {
        'employees': 382,
        'visitors': 27,
        'contractors': 15,
        'vehicles': 41,
      },
      'alerts': [
        {
          'id': 'a1',
          'message': 'Visitor card not returned',
          'subText': 'Maza Instansi (8057210110)',
          'time': '11:30',
          'critical': true,
        },
        {
          'id': 'a2',
          'message': 'NDA not signed',
          'subText': 'PT. ABC Vendor - 2 persons',
          'time': '11:15',
          'critical': false,
        }
      ]
    };
  }

  Map<String, dynamic> _getMockSearchResult() {
    return {
      "status": "success",
      "status_code": 200,
      "title": "success",
      "msg": "Data retrieved successfully",
      "collection": {
        "data": [
          {
            "transaction_visitor_id": "9ea167d3-99f3-4f43-9391-0a3080ce078f",
            "agenda": "Meeting",
            "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
            "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
            "host_name": "Endru",
            "host_organization_name": "Organization SPU",
            "visitor_period_start": "2026-08-14T02:00:00",
            "visitor_period_end": "2026-08-14T12:00:00",
            "group_name": "Dion's visitor group",
            "visitor_number": "1906100658",
            "visitor_pin": "263388",
            "visitor_pin4": "2633",
            "visitor_code": "1906100658",
            "invitation_code": "EOOPVS-DGC6SO",
            "self_only": false,
            "visitor_status": "Preregis",
            "invitation_created_at": "2026-08-14T10:46:27.72007",
            "remarks": "PraRegister",
            "parking_slot": "",
            "parking_area": "",
            "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
            "visitor_name": "Dion",
            "visitor_organization_name": "Organization PI",
            "visitor_identity_id": "12312312",
            "visitor_phone": "084123123123",
            "visitor_email": "dion1215@gmail.com",
            "can_track_ble": true,
            "can_parking": true,
            "can_access": true,
            "tz": "Asia/Jakarta",
            "is_group": true,
            "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
            "visitor_type_name": "General Visitor",
            "is_praregister_done": false,
            "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
            "site_place_name": "Gedung SINERGI",
            "visitor": {
              "visitor_type": "00000000-0000-0000-0000-000000000000",
              "name": "Dion",
              "email": "dion1215@gmail.com",
              "employee": {
                "person_id": "",
                "identity_id": "",
                "type": "Permanent",
                "name": "Dion",
                "gender": "Male",
                "other_id": "",
                "id": "eb133466-990d-414b-8311-a0faa899cfe8"
              },
              "id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43"
            },
            "card": [
              {
                "card_number": "1906100658",
                "card_barcode": "1906100658",
                "card_mac": "",
                "is_ble": false,
                "trx_visitor_id": "014efaa0-76b0-454c-b585-0ebce7d77bd7",
                "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
                "last_position_track": "",
                "is_swapcard": false,
                "current_used": true,
                "card_type": "Barcode",
                "card_status": "Available",
                "id": "d57d0c94-1b23-4285-937e-0ed3a1fa9233"
              }
            ],
            "access": [],
            "tracking_ble": [],
            "visitor_role": "Visitor",
            "trx_visitor_sites": [],
            "approval_status": "Pending",
            "is_host": false,
            "hosts": [
              {
                "person_id": "77182",
                "identity_id": "77182",
                "type": "Permanent",
                "name": "Endru",
                "phone": "08898765678",
                "email": "reyjanumbs@gmail.com",
                "gender": "Male",
                "upload_fr": 0,
                "faceimage": "/faces/9a4ab2d1-76b5-43de-8c47-c62bee91209c.jpeg",
                "head_employee_1": "",
                "head_employee_2": "",
                "id": "f2b0c94e-312d-418b-bb6e-05709784e9c3"
              }
            ],
            "visitor_access_system_status": "NotUsed",
            "visitor_parking_system_status": "NotUsed",
            "visitor_trackingble_system_status": "NotUsed",
            "visitor_trackingcctv_system_status": "NotUsed",
            "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
            "invited_by_name": "Operator 1",
            "id": "014efaa0-76b0-454c-b585-0ebce7d77bd7"
          }
        ],
        "search-match": "InvitationCode"
      }
    };
  }

  Map<String, dynamic> _getMockInvitationRelatedVisitors() {
    return {
      "status": "success",
      "status_code": 200,
      "title": "success",
      "msg": "Data retrieved successfully",
      "collection": [
        {
          "transaction_visitor_id": "9ea167d3-99f3-4f43-9391-0a3080ce078f",
          "agenda": "Meeting",
          "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
          "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "visitor_period_start": "2026-08-14T02:00:00",
          "visitor_period_end": "2026-08-14T12:00:00",
          "group_name": "Dion's visitor group",
          "visitor_number": "1906100658",
          "visitor_pin": "263388",
          "visitor_pin4": "2633",
          "visitor_code": "1906100658",
          "invitation_code": "EOOPVS-DGC6SO",
          "self_only": false,
          "visitor_status": "Preregis",
          "invitation_created_at": "2026-08-14T10:46:27.72007",
          "remarks": "PraRegister",
          "parking_slot": "",
          "parking_area": "",
          "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
          "visitor_name": "Dion",
          "visitor_organization_name": "Organization PI",
          "visitor_identity_id": "12312312",
          "visitor_phone": "084123123123",
          "visitor_email": "dion1215@gmail.com",
          "can_track_ble": true,
          "can_parking": true,
          "can_access": true,
          "tz": "Asia/Jakarta",
          "is_group": true,
          "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "is_praregister_done": false,
          "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
          "site_place_name": "Gedung SINERGI",
          "visitor": {
            "visitor_type": "00000000-0000-0000-0000-000000000000",
            "name": "Dion",
            "email": "dion1215@gmail.com",
            "employee": {
              "person_id": "",
              "identity_id": "",
              "type": "Permanent",
              "name": "Dion",
              "gender": "Male",
              "other_id": "",
              "id": "eb133466-990d-414b-8311-a0faa899cfe8"
            },
            "id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43"
          },
          "card": [
            {
              "card_number": "1906100658",
              "card_barcode": "1906100658",
              "card_mac": "",
              "is_ble": false,
              "trx_visitor_id": "014efaa0-76b0-454c-b585-0ebce7d77bd7",
              "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
              "last_position_track": "",
              "is_swapcard": false,
              "current_used": true,
              "card_type": "Barcode",
              "card_status": "Available",
              "id": "d57d0c94-1b23-4285-937e-0ed3a1fa9233"
            }
          ],
          "access": [],
          "tracking_ble": [],
          "visitor_role": "Visitor",
          "trx_visitor_sites": [],
          "approval_status": "Pending",
          "is_host": false,
          "visitor_access_system_status": "NotUsed",
          "visitor_parking_system_status": "NotUsed",
          "visitor_trackingble_system_status": "NotUsed",
          "visitor_trackingcctv_system_status": "NotUsed",
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "014efaa0-76b0-454c-b585-0ebce7d77bd7"
        },
        {
          "transaction_visitor_id": "9ea167d3-99f3-4f43-9391-0a3080ce078f",
          "agenda": "Meeting",
          "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
          "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "visitor_period_start": "2026-08-14T02:00:00",
          "visitor_period_end": "2026-08-14T12:00:00",
          "group_name": "Dion's visitor group",
          "visitor_number": "1331928888",
          "visitor_pin": "443552",
          "visitor_pin4": "4435",
          "visitor_code": "1331928888",
          "visitor_card": "0019277182",
          "visitor_face": "/faces/9a4ab2d1-76b5-43de-8c47-c62bee91209c.jpeg",
          "visitor_ble_card": "0019277182",
          "invitation_code": "EOOPVS-368GV8",
          "self_only": false,
          "visitor_status": "Preregis",
          "invitation_created_at": "2026-08-14T10:46:27.7084453",
          "vehicle_plate_number": "B 1231 AA",
          "remarks": "PraRegister",
          "parking_slot": "",
          "parking_area": "",
          "visitor_id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2",
          "visitor_name": "Endru",
          "visitor_organization_name": "Organization SPU",
          "visitor_identity_id": "77182",
          "visitor_phone": "08898765678",
          "visitor_email": "reyjanumbs@gmail.com",
          "visitor_gender": "Male",
          "selfie_image": "/faces/9a4ab2d1-76b5-43de-8c47-c62bee91209c.jpeg",
          "can_track_ble": true,
          "can_parking": true,
          "can_access": true,
          "tz": "Asia/Jakarta",
          "is_group": true,
          "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "is_praregister_done": false,
          "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
          "site_place_name": "Gedung SINERGI",
          "visitor": {
            "visitor_type": "00000000-0000-0000-0000-000000000000",
            "name": "Endru",
            "email": "reyjanumbs@gmail.com",
            "employee": {
              "person_id": "",
              "identity_id": "",
              "type": "Permanent",
              "name": "Endru",
              "gender": "Male",
              "other_id": "",
              "id": "f2b0c94e-312d-418b-bb6e-05709784e9c3"
            },
            "id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2"
          },
          "card": [
            {
              "card_number": "0019277182",
              "card_barcode": "1331928888",
              "card_mac": "",
              "is_ble": false,
              "is_employee_used": true,
              "trx_visitor_id": "93b68910-74a3-4a21-bc9f-3359e80332fc",
              "visitor_id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2",
              "last_position_track": "",
              "is_swapcard": false,
              "current_used": true,
              "card_type": "RFID",
              "card_status": "Available",
              "id": "0c44c57b-9f1e-434d-8a95-e852fef845a4"
            }
          ],
          "access": [],
          "tracking_ble": [],
          "visitor_role": "Visitor",
          "trx_visitor_sites": [],
          "approval_status": "Pending",
          "is_host": true,
          "visitor_access_system_status": "NotUsed",
          "visitor_parking_system_status": "NotUsed",
          "visitor_trackingble_system_status": "NotUsed",
          "visitor_trackingcctv_system_status": "NotUsed",
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "93b68910-74a3-4a21-bc9f-3359e80332fc"
        }
      ]
    };
  }

  Map<String, dynamic> _getMockTransactionDataTable() {
    return {
      "RecordsTotal": 475,
      "RecordsFiltered": 475,
      "Draw": 1,
      "status": "success",
      "status_code": 200,
      "title": "success",
      "msg": "Data retrieved successfully",
      "collection": [
        {
          "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
          "agenda": "Meeting",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "invitation_created_at": "2026-08-14T10:46:27.72007",
          "can_track_ble": true,
          "can_track_cctv": true,
          "can_parking": true,
          "can_access": true,
          "remarks": "PraRegister",
          "site_id": "e3facb54-eae1-48d5-9457-3ef7d3f7ba3b",
          "visitor_type_id": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "visitor_period_start": "2026-08-14T02:00:00",
          "visitor_period_end": "2026-08-14T12:00:00",
          "tz": "Asia/Jakarta",
          "visitor_role": "Visitor",
          "transaction_status": "UnderCreated",
          "flow": "Praregister",
          "list_visitor": [],
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "9ea167d3-99f3-4f43-9391-0a3080ce078f"
        },
        {
          "initial_trx_code": "39RVODFK2B69RT1CY6YNUNKGYK7H28RDTIZOFDRVITPY11T2BRGXAS88HEUSHQ2ZJP7DYNE3SAEX43QYVVWN43OGLZS6D98RJX82OFC84FENPLTCOOWPUKFBKVBWAXNW",
          "agenda": "Meeting",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "invitation_created_at": "2026-08-14T10:06:37.0789787",
          "can_track_ble": true,
          "can_track_cctv": true,
          "can_parking": true,
          "can_access": true,
          "remarks": "Invitation",
          "site_id": "e3facb54-eae1-48d5-9457-3ef7d3f7ba3b",
          "visitor_type_id": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "visitor_period_start": "2026-08-14T09:00:00",
          "visitor_period_end": "2026-08-14T13:00:00",
          "tz": "Asia/Bangkok",
          "visitor_role": "Visitor",
          "transaction_status": "Available",
          "flow": "Invitation",
          "list_visitor": [],
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "d22b8122-f3c2-4268-ab38-d5df13cd3f9f"
        }
      ]
    };
  }

  Map<String, dynamic> _getMockTransactionVisitors() {
    return {
      "status": "success",
      "status_code": 200,
      "title": "success",
      "msg": "Data retrieved successfully",
      "collection": [
        {
          "transaction_visitor_id": "9ea167d3-99f3-4f43-9391-0a3080ce078f",
          "agenda": "Meeting",
          "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
          "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "visitor_period_start": "2026-08-14T02:00:00",
          "visitor_period_end": "2026-08-14T12:00:00",
          "group_name": "Dion's visitor group",
          "visitor_number": "1906100658",
          "visitor_pin": "263388",
          "visitor_pin4": "2633",
          "visitor_code": "1906100658",
          "invitation_code": "EOOPVS-DGC6SO",
          "self_only": false,
          "visitor_status": "Preregis",
          "invitation_created_at": "2026-08-14T10:46:27.72007",
          "remarks": "PraRegister",
          "parking_slot": "",
          "parking_area": "",
          "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
          "visitor_name": "Dion",
          "visitor_organization_name": "Organization PI",
          "visitor_identity_id": "12312312",
          "visitor_phone": "084123123123",
          "visitor_email": "dion1215@gmail.com",
          "can_track_ble": true,
          "can_parking": true,
          "can_access": true,
          "tz": "Asia/Jakarta",
          "is_group": true,
          "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "is_praregister_done": false,
          "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
          "site_place_name": "Gedung SINERGI",
          "visitor": {
            "visitor_type": "00000000-0000-0000-0000-000000000000",
            "name": "Dion",
            "email": "dion1215@gmail.com",
            "employee": {
              "person_id": "",
              "identity_id": "",
              "type": "Permanent",
              "name": "Dion",
              "gender": "Male",
              "other_id": "",
              "id": "eb133466-990d-414b-8311-a0faa899cfe8"
            },
            "id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43"
          },
          "card": [
            {
              "card_number": "1906100658",
              "card_barcode": "1906100658",
              "card_mac": "",
              "is_ble": false,
              "trx_visitor_id": "014efaa0-76b0-454c-b585-0ebce7d77bd7",
              "visitor_id": "b9b87c14-043a-4c16-9f92-295bd0bf0f43",
              "last_position_track": "",
              "is_swapcard": false,
              "current_used": true,
              "card_type": "Barcode",
              "card_status": "Available",
              "id": "d57d0c94-1b23-4285-937e-0ed3a1fa9233"
            }
          ],
          "access": [],
          "tracking_ble": [],
          "visitor_role": "Visitor",
          "trx_visitor_sites": [],
          "approval_status": "Pending",
          "is_host": false,
          "visitor_access_system_status": "NotUsed",
          "visitor_parking_system_status": "NotUsed",
          "visitor_trackingble_system_status": "NotUsed",
          "visitor_trackingcctv_system_status": "NotUsed",
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "014efaa0-76b0-454c-b585-0ebce7d77bd7"
        },
        {
          "transaction_visitor_id": "9ea167d3-99f3-4f43-9391-0a3080ce078f",
          "agenda": "Meeting",
          "initial_trx_code": "NXUI3ZX6OCM7FPBYC36LEE82H18BT9ZB4ZYS9V712B2ZAXLYHC4T3ZJ4GWHTD32CGYOREQUFJUZ2JVEEDD1EDL768P98UMVHDMK62ZC5RACS9XX7Y3DBZW61FSFCMAL9",
          "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
          "host_name": "Endru",
          "host_organization_name": "Organization SPU",
          "visitor_period_start": "2026-08-14T02:00:00",
          "visitor_period_end": "2026-08-14T12:00:00",
          "group_name": "Dion's visitor group",
          "visitor_number": "1331928888",
          "visitor_pin": "443552",
          "visitor_pin4": "4435",
          "visitor_code": "1331928888",
          "visitor_card": "0019277182",
          "visitor_face": "/faces/9a4ab2d1-76b5-43de-8c47-c62bee91209c.jpeg",
          "visitor_ble_card": "0019277182",
          "invitation_code": "EOOPVS-368GV8",
          "self_only": false,
          "visitor_status": "Preregis",
          "invitation_created_at": "2026-08-14T10:46:27.7084453",
          "vehicle_plate_number": "B 1231 AA",
          "remarks": "PraRegister",
          "parking_slot": "",
          "parking_area": "",
          "visitor_id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2",
          "visitor_name": "Endru",
          "visitor_organization_name": "Organization SPU",
          "visitor_identity_id": "77182",
          "visitor_phone": "08898765678",
          "visitor_email": "reyjanumbs@gmail.com",
          "visitor_gender": "Male",
          "selfie_image": "/faces/9a4ab2d1-76b5-43de-8c47-c62bee91209c.jpeg",
          "can_track_ble": true,
          "can_parking": true,
          "can_access": true,
          "tz": "Asia/Jakarta",
          "is_group": true,
          "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
          "visitor_type_name": "General Visitor",
          "is_praregister_done": false,
          "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
          "site_place_name": "Gedung SINERGI",
          "visitor": {
            "visitor_type": "00000000-0000-0000-0000-000000000000",
            "name": "Endru",
            "email": "reyjanumbs@gmail.com",
            "employee": {
              "person_id": "",
              "identity_id": "",
              "type": "Permanent",
              "name": "Endru",
              "gender": "Male",
              "other_id": "",
              "id": "f2b0c94e-312d-418b-bb6e-05709784e9c3"
            },
            "id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2"
          },
          "card": [
            {
              "card_number": "0019277182",
              "card_barcode": "1331928888",
              "card_mac": "",
              "is_ble": false,
              "is_employee_used": true,
              "trx_visitor_id": "93b68910-74a3-4a21-bc9f-3359e80332fc",
              "visitor_id": "c8a3ea3e-7ba4-4494-8314-c050e330a6a2",
              "last_position_track": "",
              "is_swapcard": false,
              "current_used": true,
              "card_type": "RFID",
              "card_status": "Available",
              "id": "0c44c57b-9f1e-434d-8a95-e852fef845a4"
            }
          ],
          "access": [],
          "tracking_ble": [],
          "visitor_role": "Visitor",
          "trx_visitor_sites": [],
          "approval_status": "Pending",
          "is_host": true,
          "visitor_access_system_status": "NotUsed",
          "visitor_parking_system_status": "NotUsed",
          "visitor_trackingble_system_status": "NotUsed",
          "visitor_trackingcctv_system_status": "NotUsed",
          "invited_by": "85721f6b-a8e5-4b41-af95-dd87fd950030",
          "invited_by_name": "Operator 1",
          "id": "93b68910-74a3-4a21-bc9f-3359e80332fc"
        }
      ]
    };
  }
}
