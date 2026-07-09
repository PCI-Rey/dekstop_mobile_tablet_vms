import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<ApiResult<Map<String, dynamic>>> login(String username, String password) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/login',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> checkServerConnection() async {
    // Simply fetch the server URL ping status
    return await _dioClient.get<Map<String, dynamic>>(
      '/dashboard-summary', // Use summary ping as server health check
    );
  }
}
