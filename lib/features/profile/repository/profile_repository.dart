import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class ProfileRepository {
  final DioClient _dioClient;

  ProfileRepository(this._dioClient);

  Future<ApiResult<Map<String, dynamic>>> getProfile() async {
    return await _dioClient.get<Map<String, dynamic>>('/api/profile/me');
  }
}
