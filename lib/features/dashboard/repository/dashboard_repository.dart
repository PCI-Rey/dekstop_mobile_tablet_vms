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
    final cleanCode = code.trim();

    // 1. Try GET /api/operator-invitation/search?code=...
    final getApiSearch = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation/search',
      queryParameters: {
        'code': cleanCode,
        'search': cleanCode,
        'invitation_code': cleanCode,
      },
    );
    if (getApiSearch is Success) {
      return getApiSearch;
    }

    // 2. Try POST /api/operator-invitation/search
    final postApiSearch = await _dioClient.post<Map<String, dynamic>>(
      '/api/operator-invitation/search',
      data: {
        'search': cleanCode,
        'invitation_code': cleanCode,
        'code': cleanCode,
      },
      queryParameters: {
        'code': cleanCode,
      },
    );
    if (postApiSearch is Success) {
      return postApiSearch;
    }

    // 3. Try GET /operator-invitation/search?code=...
    final getSearch = await _dioClient.get<Map<String, dynamic>>(
      '/operator-invitation/search',
      queryParameters: {
        'code': cleanCode,
        'search': cleanCode,
        'invitation_code': cleanCode,
      },
    );
    if (getSearch is Success) {
      return getSearch;
    }

    // 4. Try POST /operator-invitation/search
    final postSearch = await _dioClient.post<Map<String, dynamic>>(
      '/operator-invitation/search',
      data: {
        'search': cleanCode,
        'invitation_code': cleanCode,
        'code': cleanCode,
      },
      queryParameters: {
        'code': cleanCode,
      },
    );
    if (postSearch is Success) {
      return postSearch;
    }

    // 5. Try GET /api/operator-invitation?code=...
    final getApiDirect = await _dioClient.get<Map<String, dynamic>>(
      '/api/operator-invitation',
      queryParameters: {
        'code': cleanCode,
        'search': cleanCode,
      },
    );
    if (getApiDirect is Success) {
      return getApiDirect;
    }

    return postApiSearch;
  }
}
