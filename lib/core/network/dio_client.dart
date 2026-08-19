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
      headers: {
        'Content-Type': 'application/json',
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
        final response = await activeDio.post(
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
        final response = await activeDio.put(
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
