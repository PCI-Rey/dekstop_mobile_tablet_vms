import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/storage_service.dart';
import '../controller/profile_controller.dart';
import '../repository/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRepository>(() => ProfileRepository(Get.find<DioClient>()));
    Get.lazyPut<ProfileController>(
      () => ProfileController(Get.find<ProfileRepository>(), Get.find<StorageService>()),
    );
  }
}
