import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  Future<ApiResult<Map<String, dynamic>>> getDashboardSummary() async {
    return await _dioClient.get<Map<String, dynamic>>('/dashboard-summary');
  }

  Future<ApiResult<Map<String, dynamic>>> getVisitorsData() async {
    return await _dioClient.get<Map<String, dynamic>>('/visitors');
  }

  Future<ApiResult<Map<String, dynamic>>> performVisitorAction(String id, String action) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/visitor/action',
      data: {
        'id': id,
        'action': action,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> searchInvitation(String code) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/search',
      data: {
        'search': code,
        'invitation_code': code,
        'code': code,
      },
      queryParameters: {
        'search': code,
        'invitation_code': code,
        'code': code,
      },
    );
  }
}
