import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  /// Show Success Snackbar (Green)
  static void success({
    String title = 'Success',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Show Error Snackbar (Red)
  static void error({
    String title = 'Error',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.cancel_rounded,
      duration: duration,
    );
  }

  /// Show Warning Snackbar (Amber/Orange)
  static void warning({
    String title = 'Warning',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFF59E0B),
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Show Info Snackbar (Brand Blue)
  static void info({
    String title = 'Information',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF1976D2),
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  static void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
      shouldIconPulse: false,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      icon: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
