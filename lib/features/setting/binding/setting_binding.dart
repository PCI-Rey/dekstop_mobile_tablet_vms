import 'package:get/get.dart';
import '../controller/setting_controller.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingController>(() => SettingController(Get.find()));
  }
}
