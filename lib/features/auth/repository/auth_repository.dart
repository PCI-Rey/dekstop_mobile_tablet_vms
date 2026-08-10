import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  // Login via official endpoint /api/_Auth/RequestToken
  Future<ApiResult<Map<String, dynamic>>> login(String username, String password) async {
    return await _dioClient.post<Map<String, dynamic>>(
      '/api/_Auth/RequestToken',
      data: {
        'username': username,
        'password': password,
      },
    );
  }
}
