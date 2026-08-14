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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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
      return ApiResult.failure(NetworkException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(UnknownException(e.toString()));
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
      return ApiResult.failure(NetworkException.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(UnknownException(e.toString()));
    }
  }

  Future<bool> _isDemoServer() async {
    final url = await _storageService.getServerUrl();
    return url.contains('example.com') || url.isEmpty;
  }

  // Simulating backend endpoints when no real backend server is plugged in
  Future<ApiResult<T>> _handleDemoGet<T>(String path, Map<String, dynamic>? queryParams, T Function(dynamic json)? fromJson) async {
    if (path.contains('/visitors')) {
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
            "transaction_visitor_id": "8c60c085-70ae-446e-b888-ff813bedae14",
            "agenda": "Meeting",
            "initial_trx_code": "7OPNW3LJRYHYNU4ZED11ASZ8HP3ZIPYGDOLZCI9CA74Q7V2Q1GFMWS4LTFW15Y4ZAZTWO7EMVGRDRXFAQD7IS21N7AOOA5EWMYM5K4RHCWWNNTL4QET1FDP7PSRROMBE",
            "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
            "host_name": "Endru",
            "host_organization_name": "Organization SPU",
            "visitor_period_start": "2026-08-13T01:00:00",
            "visitor_period_end": "2026-08-13T12:00:00",
            "group_name": "Tera's visitor group",
            "visitor_number": "8258653021",
            "visitor_pin": "956248",
            "visitor_pin4": "9562",
            "visitor_code": "8258653021",
            "invitation_code": "15Y1H5-QR5FHL",
            "self_only": false,
            "visitor_status": "Preregis",
            "invitation_created_at": "2026-08-13T10:23:40.109055",
            "remarks": "PraRegister",
            "parking_slot": "",
            "parking_area": "",
            "visitor_id": "5b2b3bb4-b6fe-4410-95d0-bd52daa715b1",
            "visitor_name": "Tera",
            "visitor_organization_name": "Instansi Tera",
            "visitor_identity_id": "151696969",
            "visitor_phone": "0810412120841",
            "visitor_email": "cennandaa@gmail.com",
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
              "name": "Tera",
              "email": "cennandaa@gmail.com",
              "id": "5b2b3bb4-b6fe-4410-95d0-bd52daa715b1"
            },
            "card": [
              {
                "card_number": "8258653021",
                "card_barcode": "8258653021",
                "card_mac": "",
                "is_ble": false,
                "trx_visitor_id": "ccd1f915-111d-402d-afd8-9bd0f86aefa4",
                "visitor_id": "5b2b3bb4-b6fe-4410-95d0-bd52daa715b1",
                "last_position_track": "",
                "is_swapcard": false,
                "current_used": true,
                "card_type": "Barcode",
                "card_status": "Available",
                "id": "e7f88be8-54f3-4b0c-87e5-b6607514e846"
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
            "invited_by": "416befe2-b840-4f35-b310-a079bf1b6a3b",
            "invited_by_name": "Admins",
            "id": "ccd1f915-111d-402d-afd8-9bd0f86aefa4"
          }
        ],
        "search-match": "InvitationCode"
      }
    };
  }
}
