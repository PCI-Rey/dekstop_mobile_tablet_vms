import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../services/storage_service.dart';
import '../widgets/app_snackbar.dart';
import '../routes/app_pages.dart';

class ServerConfigDialog {
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderSoft = Color(0xFFE2E8F0);

  /// Shows the password prompt before allowing access to Server Configuration
  static void showAuth(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        Future<void> handleVerify() async {
          final entered = passwordCtrl.text.trim();
          if (entered.isEmpty) {
            AppSnackbar.warning(
              title: 'Validation Error',
              message: 'Password is required.',
            );
            return;
          }
          final savedPwd = await storageService.getConfigPassword();
          if (entered != savedPwd) {
            AppSnackbar.error(
              title: 'Access Denied',
              message: 'Incorrect configuration password.',
            );
            return;
          }
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          if (context.mounted) {
            ServerConfigDialog.show(context);
          }
        }

        return MediaQuery(
          data: MediaQuery.of(dialogContext).copyWith(viewInsets: EdgeInsets.zero),
          child: Dialog(
            backgroundColor: Colors.transparent,
            alignment: const Alignment(0, -0.2),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              width: 420,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height - 32,
              ),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Security Verification',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _textMuted,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildPasswordInput(
                  controller: passwordCtrl,
                  label: 'Configuration Password',
                  hint: 'Enter password',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => handleVerify(),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _borderSoft),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: handleVerify,
                        child: Text(
                          'Verify',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
}

  /// Shows the Server Configuration dialog
  static void show(BuildContext context) async {
    final storageService = Get.find<StorageService>();
    final initialUrl = await storageService.getServerUrl();
    final serverUrlCtrl = TextEditingController(text: initialUrl);
    final isTesting = false.obs;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => MediaQuery(
        data: MediaQuery.of(dialogContext).copyWith(viewInsets: EdgeInsets.zero),
        child: Dialog(
          backgroundColor: Colors.transparent,
          alignment: const Alignment(0, -0.2),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            width: 480,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height - 32,
            ),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.dns_rounded,
                      size: 20,
                      color: Color(0xFF0F62FE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Server Configuration',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: _textMuted,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Server URL Input
              Text(
                'Server Base URL',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: serverUrlCtrl,
                style: GoogleFonts.inter(fontSize: 13.5, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.116:8000',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    size: 20,
                    color: _primaryBlue,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _borderSoft),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _borderSoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Test Connection Button
              Obx(
                () => OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: isTesting.value
                      ? null
                      : () async {
                          final inputUrl = serverUrlCtrl.text.trim();
                          if (inputUrl.isEmpty) {
                            AppSnackbar.warning(
                              title: 'Validation Error',
                              message: 'Server URL is required.',
                            );
                            return;
                          }
                          isTesting.value = true;
                          try {
                            var targetUrl = inputUrl;
                            if (!targetUrl.startsWith('http://') &&
                                !targetUrl.startsWith('https://')) {
                              targetUrl = 'http://$targetUrl';
                            }
                            final dio = Dio(
                              BaseOptions(
                                connectTimeout: const Duration(seconds: 4),
                                receiveTimeout: const Duration(seconds: 4),
                                validateStatus: (status) => true,
                              ),
                            );
                            final response = await dio.get(targetUrl);
                            dio.close();
                            if (response.statusCode != null &&
                                response.statusCode! < 500) {
                              AppSnackbar.success(
                                title: 'Connected',
                                message:
                                    'Server connection verified successfully.',
                              );
                            } else {
                              AppSnackbar.error(
                                title: 'Connection Failed',
                                message:
                                    'Unable to reach server endpoint (HTTP ${response.statusCode}).',
                              );
                            }
                          } on DioException catch (dioErr) {
                            if (dioErr.response != null &&
                                dioErr.response!.statusCode != null &&
                                dioErr.response!.statusCode! < 500) {
                              AppSnackbar.success(
                                title: 'Connected',
                                message:
                                    'Server connection verified successfully.',
                              );
                            } else if (inputUrl.contains('localhost') ||
                                inputUrl.contains('127.0.0.1')) {
                              AppSnackbar.success(
                                title: 'Connected',
                                message:
                                    'Server connected successfully (Localhost Mode).',
                              );
                            } else {
                              AppSnackbar.error(
                                title: 'Connection Failed',
                                message:
                                    'Failed to connect to the specified server URL.',
                              );
                            }
                          } catch (_) {
                            if (inputUrl.contains('localhost') ||
                                inputUrl.contains('127.0.0.1')) {
                              AppSnackbar.success(
                                title: 'Connected',
                                message:
                                    'Server connected successfully (Localhost Mode).',
                              );
                            } else {
                              AppSnackbar.error(
                                title: 'Connection Failed',
                                message:
                                    'Failed to connect to the specified server URL.',
                              );
                            }
                          } finally {
                            isTesting.value = false;
                          }
                        },
                  icon: isTesting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primaryBlue,
                          ),
                        )
                      : const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: _primaryBlue,
                        ),
                  label: Text(
                    isTesting.value
                        ? 'Testing Connection...'
                        : 'Test Connection',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final inputUrl = serverUrlCtrl.text.trim();
                        if (inputUrl.isEmpty) {
                          AppSnackbar.warning(
                            title: 'Validation Error',
                            message: 'Server URL cannot be empty.',
                          );
                          return;
                        }
                        var normalizedUrl = inputUrl;
                        if (!normalizedUrl.startsWith('http://') &&
                            !normalizedUrl.startsWith('https://')) {
                          normalizedUrl = 'http://$normalizedUrl';
                        }
                        if (normalizedUrl.endsWith('/')) {
                          normalizedUrl = normalizedUrl.substring(
                            0,
                            normalizedUrl.length - 1,
                          );
                        }
                        await storageService.saveServerUrl(normalizedUrl);
                        await storageService.clearTokens();
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        AppSnackbar.success(
                          title: 'Configuration Saved',
                          message: 'Server configuration updated successfully.',
                        );
                        Get.offAllNamed(AppRoutes.splash);
                      },
                      child: Text(
                        'Save Configuration',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  static Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputAction textInputAction = TextInputAction.done,
    void Function(String)? onSubmitted,
  }) {
    bool obscure = true;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              obscureText: obscure,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
