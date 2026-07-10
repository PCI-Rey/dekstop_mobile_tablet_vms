import 'package:flutter/material.dart';
import '../utils/device_utils.dart';

/// Responsive layout switcher.
///
/// Renders:
/// - [mobile]          when width < 768dp  (e.g. Samsung Galaxy A55 in portrait)
/// - [tablet]/[desktop] when width >= 768dp (e.g. Galaxy Tab A8 in landscape)
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  /// True when screen width is below the mobile/desktop breakpoint.
  static bool isMobile(BuildContext context) =>
      AppDeviceUtil.useMobileLayout(context);

  /// True when screen width is in the tablet range (768–1023dp).
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDeviceUtil.kLayoutBreakpoint &&
      MediaQuery.of(context).size.width < 1024;

  /// True when screen width is >= 1024dp (full desktop).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDeviceUtil.kLayoutBreakpoint) {
          // Tablet & Desktop: prefer tablet widget if provided, fallback to desktop
          return tablet ?? desktop;
        } else {
          // Phone / narrow screen → Mobile layout
          return mobile;
        }
      },
    );
  }
}
