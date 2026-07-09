import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../controller/auth_controller.dart';
import '../repository/auth_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<DioClient>()));
    Get.lazyPut<AuthController>(() => AuthController(Get.find<AuthRepository>(), Get.find()));
  }
}
