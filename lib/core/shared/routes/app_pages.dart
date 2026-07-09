import 'package:get/get.dart';

// Import Views & Bindings
import '../../../features/auth/binding/auth_binding.dart';
import '../../../features/auth/view/login_view.dart';
import '../../../features/auth/view/splash_view.dart';
import '../../../features/dashboard/binding/dashboard_binding.dart';
import '../../../features/dashboard/view/dashboard_view.dart';
import '../../../features/visitor/view/visitor_detail_view.dart';
import '../../../features/visitor/view/related_visitors_view.dart';
import '../../../features/profile/view/profile_view.dart';
import '../../../features/setting/binding/setting_binding.dart';
import '../../../features/setting/view/configure_view.dart';
import '../widgets/no_internet_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String visitorDetail = '/visitor/detail';
  static const String visitorList = '/visitor/list';
  static const String profile = '/profile';
  static const String configure = '/configure';
  static const String noInternet = '/no-internet';
}

class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.visitorDetail,
      page: () => const VisitorDetailView(),
      // Shares the dashboard binding
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.visitorList,
      page: () => const RelatedVisitorsView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.configure,
      page: () => const ConfigureView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: AppRoutes.noInternet,
      page: () => const NoInternetScreen(),
    ),
  ];
}
