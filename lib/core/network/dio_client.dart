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
    return url.contains('example.com') || url.contains('localhost') || url.isEmpty;
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
    }

    return ApiResult.failure(const ServerException(statusCode: 404, message: 'Resource not found in Demo server.'));
  }

  Future<ApiResult<T>> _handleDemoPost<T>(String path, dynamic data, T Function(dynamic json)? fromJson) async {
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
}
