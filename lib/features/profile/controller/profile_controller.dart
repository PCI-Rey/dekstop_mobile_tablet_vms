import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../repository/profile_repository.dart';

class ProfileController extends GetxController {
  final ProfileRepository _profileRepository;
  final StorageService _storageService;

  ProfileController(this._profileRepository, this._storageService);

  final rxIsLoading = false.obs;
  final rxProfileData = Rxn<Map<String, dynamic>>();

  // Computed getters from /api/profile/me payload
  String get fullname {
    final coll = rxProfileData.value;
    if (coll != null && coll['fullname'] != null && coll['fullname'].toString().trim().isNotEmpty) {
      return coll['fullname'].toString().trim();
    }
    return 'Operator';
  }

  String get email {
    final coll = rxProfileData.value;
    if (coll != null && coll['email'] != null && coll['email'].toString().trim().isNotEmpty) {
      return coll['email'].toString().trim();
    }
    return 'operator@gmail.com';
  }

  String get role {
    final coll = rxProfileData.value;
    if (coll != null && coll['group_name'] != null && coll['group_name'].toString().trim().isNotEmpty) {
      return coll['group_name'].toString().trim();
    }
    return 'OperatorVMS';
  }

  String get organization {
    final coll = rxProfileData.value;
    if (coll != null && coll['organization_name'] != null && coll['organization_name'].toString().trim().isNotEmpty) {
      return coll['organization_name'].toString().trim();
    }
    return '-';
  }

  String get department {
    final coll = rxProfileData.value;
    if (coll != null && coll['department_name'] != null && coll['department_name'].toString().trim().isNotEmpty) {
      return coll['department_name'].toString().trim();
    }
    return '-';
  }

  String get address {
    final coll = rxProfileData.value;
    if (coll != null && coll['address'] != null && coll['address'].toString().trim().isNotEmpty) {
      return coll['address'].toString().trim();
    }
    return '-';
  }

  String get gender {
    final coll = rxProfileData.value;
    if (coll != null && coll['gender'] != null && coll['gender'].toString().trim().isNotEmpty) {
      return coll['gender'].toString().trim();
    }
    return '-';
  }

  String get phone {
    final coll = rxProfileData.value;
    if (coll != null && coll['phone'] != null && coll['phone'].toString().trim().isNotEmpty) {
      return coll['phone'].toString().trim();
    }
    return '-';
  }

  bool get isEmailVerified {
    final coll = rxProfileData.value;
    return coll?['is_email_verified'] == true;
  }

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    rxIsLoading.value = true;
    final result = await _profileRepository.getProfile();
    rxIsLoading.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final resData = result.data;
      final coll = (resData['collection'] is Map)
          ? Map<String, dynamic>.from(resData['collection'] as Map)
          : (resData['data'] is Map ? Map<String, dynamic>.from(resData['data'] as Map) : resData);
      rxProfileData.value = coll;
    }
  }

  Future<void> logout() async {
    await _storageService.clearTokens();
    Get.offAllNamed(AppRoutes.login);
  }
}
