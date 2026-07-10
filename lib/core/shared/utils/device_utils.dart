import 'package:flutter/material.dart';

/// Centralized device & layout detection utility.
///
/// Gold standard devices:
/// - HP Android  : Samsung Galaxy A55 (A556E) — shortestSide ≈ 360dp
/// - Tablet Android: Galaxy Tab A8 (SM-X200)  — shortestSide ≈ 800dp
///
/// Rule:
///   shortestSide >= 600  →  Tablet  → Landscape orientation + Desktop/Tablet layout
///   shortestSide < 600   →  Phone   → Portrait orientation + Mobile layout
class AppDeviceUtil {
  AppDeviceUtil._();

  // ──────────────────────────────────────────────
  // Device type detection (based on shortestSide)
  // shortestSide is stable regardless of rotation.
  // ──────────────────────────────────────────────

  /// Returns true if the device is a tablet (shortestSide >= 600dp).
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Returns true if the device is a phone (shortestSide < 600dp).
  static bool isPhone(BuildContext context) => !isTablet(context);

  // ──────────────────────────────────────────────
  // Layout switching (based on current width)
  // width changes when device rotates — used for layout decisions.
  // ──────────────────────────────────────────────

  /// Returns true if the current width warrants a Mobile layout (< 768dp).
  static bool useMobileLayout(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Returns true if the current width warrants a Desktop/Tablet layout (>= 768dp).
  static bool useDesktopLayout(BuildContext context) => !useMobileLayout(context);

  // ──────────────────────────────────────────────
  // Convenience breakpoint helpers
  // ──────────────────────────────────────────────

  /// Breakpoint value for layout switching (mobile vs desktop).
  static const double kLayoutBreakpoint = 768.0;

  /// Breakpoint value for device-type detection (phone vs tablet).
  static const double kTabletBreakpoint = 600.0;

  // ──────────────────────────────────────────────
  // Used in main() before widget tree — reads physical screen
  // ──────────────────────────────────────────────

  /// Detect tablet before widget tree is initialized.
  /// Used in `main()` to decide orientation lock.
  /// Reads from the first Flutter view's physical size.
  static bool isTabletFromPhysicalSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final physicalShortestSide = view.physicalSize.shortestSide;
    final dpr = view.devicePixelRatio;
    final shortestSide = physicalShortestSide / dpr;
    return shortestSide >= kTabletBreakpoint;
  }
}
