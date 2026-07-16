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
      receiveTimeout: const Duration(seconds: 15),
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
    // Add artificial delay to show shimmer skeleton loadings
    await Future.delayed(const Duration(milliseconds: 1200));

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
      await Future.delayed(const Duration(milliseconds: 150));
      final mockSearch = _getMockSearchResult();
      if (fromJson != null) {
        return ApiResult.success(fromJson(mockSearch));
      }
      return ApiResult.success(mockSearch as T);
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (path.contains('/login')) {
      final username = data['username'] ?? '';
      final password = data['password'] ?? '';
      
      if (username.isEmpty || password.isEmpty) {
        return ApiResult.failure(const ServerException(statusCode: 400, message: 'Nama Pengguna dan Kata Sandi wajib diisi.'));
      }

      final mockLoginResult = {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'username': username,
          'name': 'Operator Utama VMS',
          'email': 'operator@vms.com',
          'department': 'Security & Facility Control',
          'role': 'Super Admin Operator',
          'avatar': 'https://i.pravatar.cc/300?img=11',
          'device_info': 'Windows 11 Tablet Terminal',
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
            "transaction_visitor_id": "9bddf1c6-d00d-431b-9e32-9aa4df7586e2",
            "agenda": "Meeting",
            "initial_trx_code": "HIPUX9OB7MREJQPT7DE2GXK9A6671KCPY3HU2R7IT6OE6IMOX9HIT18ZI9PN3JM6XJV21E3PK5E1IES4ZSD8448RJDVVICJT5FCYONDV88MH3BBHREAO7P4VJSO5I585",
            "host": "f2b0c94e-312d-418b-bb6e-05709784e9c3",
            "host_name": "Endru",
            "host_organization_name": "SPU",
            "visitor_period_start": "2026-07-09T03:00:00",
            "visitor_period_end": "2026-07-09T13:00:00",
            "group_name": "PCI",
            "visitor_number": "2651825375",
            "visitor_code": "2651825375",
            "invitation_code": "IURKVH-OJAPWV",
            "self_only": false,
            "checkin_at": "2026-07-09T06:27:06.2192235",
            "checkin_by": "Admins",
            "visitor_status": "Checkin",
            "invitation_created_at": "2026-07-09T03:38:52.0996476",
            "vehicle_plate_number": "",
            "remarks": "Invitation",
            "parking_slot": "",
            "parking_area": "",
            "visitor_id": "76efef06-c8fa-4ab2-9e9f-4d6e8a612e84",
            "visitor_name": "Kora",
            "visitor_organization_name": "asdasdas",
            "visitor_identity_id": "151241231231232",
            "visitor_phone": "151234123123",
            "visitor_email": "cennandaa@gmail.com",
            "can_track_ble": true,
            "can_parking": true,
            "can_access": true,
            "tz": "Asia/Jakarta",
            "is_group": true,
            "visitor_type": "1e7ab7a0-1fdd-4546-b65f-6a8dcc345148",
            "visitor_type_name": "General Visitor (DKUT)",
            "is_praregister_done": true,
            "application_id": "074ddc10-9b66-4466-8195-7bf972914603",
            "site_place_name": "Gedung Visitor",
            "visitor": {
              "visitor_type": "00000000-0000-0000-0000-000000000000",
              "name": "Kora",
              "email": "cennandaa@gmail.com",
              "id": "76efef06-c8fa-4ab2-9e9f-4d6e8a612e84"
            },
            "card": [],
            "access": [],
            "tracking_ble": [],
            "visitor_role": "Visitor",
            "trx_visitor_sites": [
              {
                "site_name": "Gedung Visitor",
                "id": "a05b4207-8f44-4191-add6-e149de852d96"
              }
            ],
            "approval_status": "Approved",
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
                "faceimage": "",
                "head_employee_1": "",
                "head_employee_2": "",
                "id": "f2b0c94e-312d-418b-bb6e-05709784e9c3"
              },
              {
                "person_id": "12324",
                "identity_id": "1232",
                "type": "Permanent",
                "name": "Tommy",
                "phone": "62819267281",
                "email": "user2@example.com",
                "gender": "Female",
                "upload_fr": 0,
                "faceimage": "/faces/f065aa93-7dc6-4636-a0a6-edea6a97e256.jpg",
                "head_employee_1": "",
                "head_employee_2": "",
                "id": "41e4ee80-a921-43ab-af9f-517d96ec7db0"
              }
            ],
            "visitor_access_system_status": "NotUsed",
            "visitor_parking_system_status": "NotUsed",
            "visitor_trackingble_system_status": "NotUsed",
            "visitor_trackingcctv_system_status": "NotUsed",
            "invited_by": "416befe2-b840-4f35-b310-a079bf1b6a3b",
            "invited_by_name": "Admins",
            "id": "1b10ef66-1c93-44b7-bca2-33c395e778b2"
          }
        ],
        "search-match": "InvitationCode"
      }
    };
  }
}
