import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/shared/widgets/responsive_layout.dart';
import 'desktop_dashboard.dart';
import 'mobile_dashboard.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: MobileDashboard(),
        tablet: DesktopDashboard(), // Tab A8 (800dp+) → Desktop layout
        desktop: DesktopDashboard(),
      ),
    );
  }
}
