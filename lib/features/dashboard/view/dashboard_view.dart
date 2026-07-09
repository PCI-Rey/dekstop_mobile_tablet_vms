import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/shared/widgets/responsive_layout.dart';
import '../../../core/shared/widgets/skeletons.dart';
import 'desktop_dashboard.dart';
import 'mobile_dashboard.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.rxIsLoading.value) {
          return const Center(child: _DashboardLoadingScreen());
        }
        return const ResponsiveLayout(
          mobile: MobileDashboard(),
          desktop: DesktopDashboard(),
        );
      }),
    );
  }
}

// Full Dashboard Shimmer Loading State
class _DashboardLoadingScreen extends StatelessWidget {
  const _DashboardLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: SkeletonVisitorCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: const [
                  SkeletonWidget(width: double.infinity, height: 120),
                  SizedBox(height: 16),
                  Expanded(child: SkeletonRelatedVisitors()),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                children: const [
                  SkeletonWidget(width: double.infinity, height: 100),
                  SizedBox(height: 16),
                  SkeletonOccupancyGrid(),
                  SizedBox(height: 16),
                  Expanded(child: SkeletonTimeline()),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: const [
              SkeletonWidget(width: double.infinity, height: 48), // Search
              SizedBox(height: 16),
              SkeletonVisitorCard(),
              SizedBox(height: 16),
              SkeletonWidget(width: double.infinity, height: 160), // Quick actions
              SizedBox(height: 16),
              SkeletonTimeline(),
            ],
          ),
        ),
      );
    }
  }
}
