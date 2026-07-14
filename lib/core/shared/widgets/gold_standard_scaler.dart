import 'package:flutter/material.dart';
import '../utils/device_utils.dart';

/// A wrapper widget that dynamically scales the layout of the application
/// based on the Samsung Gold Standard devices:
/// - HP Android  : Samsung Galaxy A55 (width ≈ 360dp)
/// - Tablet Android: Galaxy Tab A8 (width ≈ 800dp in landscape)
///
/// This scales everything (text, layout, widgets, paddings) proportionally
/// without causing text to wrap to multiple lines or causing overflows.
class GoldStandardScaler extends StatelessWidget {
  final Widget child;

  const GoldStandardScaler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final actualWidth = mediaQuery.size.width;
    final actualHeight = mediaQuery.size.height;

    // Return child untouched if screen dimensions are not resolved yet or are too small (e.g., during initialization or tests)
    if (actualWidth < 100.0 || actualHeight < 100.0) {
      return child;
    }

    // Determine target width from device type
    final isTablet = AppDeviceUtil.isTablet(context);
    final double targetWidth = isTablet ? 800.0 : 360.0;

    // Calculate scale factor relative to width
    final double scale = actualWidth / targetWidth;

    // Scaled height ensures the layout stretches to the full height of the device screen
    final double targetHeight = actualHeight / scale;

    // Scale back paddings, safe areas, and keyboard offsets to match target design space
    final scaledPadding = EdgeInsets.only(
      left: mediaQuery.padding.left / scale,
      top: mediaQuery.padding.top / scale,
      right: mediaQuery.padding.right / scale,
      bottom: mediaQuery.padding.bottom / scale,
    );

    final scaledViewInsets = EdgeInsets.only(
      left: mediaQuery.viewInsets.left / scale,
      top: mediaQuery.viewInsets.top / scale,
      right: mediaQuery.viewInsets.right / scale,
      bottom: mediaQuery.viewInsets.bottom / scale,
    );

    final scaledViewPadding = EdgeInsets.only(
      left: mediaQuery.viewPadding.left / scale,
      top: mediaQuery.viewPadding.top / scale,
      right: mediaQuery.viewPadding.right / scale,
      bottom: mediaQuery.viewPadding.bottom / scale,
    );

    // Apply the scaling and inject the scaled MediaQuery data into the subtree
    return MediaQuery(
      data: mediaQuery.copyWith(
        size: Size(targetWidth, targetHeight),
        devicePixelRatio: mediaQuery.devicePixelRatio * scale,
        padding: scaledPadding,
        viewPadding: scaledViewPadding,
        viewInsets: scaledViewInsets,
      ),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: targetWidth,
          height: targetHeight,
          child: child,
        ),
      ),
    );
  }
}
