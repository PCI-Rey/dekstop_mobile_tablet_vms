import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';
import '../repository/dashboard_repository.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardRepository>(() => DashboardRepository(Get.find()));
    Get.lazyPut<DashboardController>(() => DashboardController(Get.find<DashboardRepository>()));
  }
}
