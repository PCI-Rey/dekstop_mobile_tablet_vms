import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';
import '../../network/dio_client.dart';
import '../../services/storage_service.dart';
import '../../../features/auth/controller/auth_controller.dart';

class ServerConfigDialog {
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderSoft = Color(0xFFE2E8F0);

  /// Shows the password prompt (PIN: 0000) before allowing access to Server Configuration
  static void showAuth(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final passwordCtrl = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void handleVerify() async {
              final entered = passwordCtrl.text.trim();
              if (entered.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Password is required.';
                });
                return;
              }
              final savedPwd = await storageService.getConfigPassword();
              if (entered == '0000' || entered == savedPwd) {
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ServerConfigDialog.show(context);
                }
              } else {
                setDialogState(() {
                  errorMessage = 'Incorrect password! (Hint: 0000)';
                });
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
                                'Server Configuration Access',
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
                        const SizedBox(height: 16),
                        Text(
                          'Enter password to access Base URL configuration:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: true,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 10,
                            color: _textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••',
                            hintStyle: const TextStyle(letterSpacing: 8),
                            counterText: '',
                            errorText: errorMessage,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _primaryBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => handleVerify(),
                        ),
                        const SizedBox(height: 20),
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
                                  'Continue',
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
      },
    );
  }

  /// Shows the Server Configuration dialog
  static void show(BuildContext context) async {
    final storageService = Get.find<StorageService>();
    final initialUrl = await storageService.getServerUrl();
    final serverUrlCtrl = TextEditingController(text: initialUrl);

    bool isTesting = false;
    bool? testSuccess;
    String testMessage = '';
    String lastTestedUrl = '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return MediaQuery(
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
                              'Base URL Configuration',
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
                      const SizedBox(height: 16),

                      // Active Base URL badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Active: $initialUrl',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Base URL input
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
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.inter(fontSize: 13.5, color: _textDark),
                        decoration: InputDecoration(
                          hintText: 'https://be-vms.app.bio-experience.com',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            size: 20,
                            color: _primaryBlue,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              serverUrlCtrl.clear();
                              setDialogState(() {
                                testSuccess = null;
                                testMessage = '';
                              });
                            },
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
                        onChanged: (_) {
                          if (testSuccess != null) {
                            setDialogState(() {
                              testSuccess = null;
                              testMessage = '';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reset to Default and Test Connection in ONE ROW
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _borderSoft),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 11,
                                ),
                              ),
                              onPressed: () {
                                serverUrlCtrl.text = AppConstants.defaultServerUrl;
                                setDialogState(() {
                                  testSuccess = null;
                                  testMessage = '';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Reset to Default',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 11,
                                ),
                              ),
                              onPressed: isTesting
                                  ? null
                                  : () async {
                                      final target = serverUrlCtrl.text.trim();
                                      if (target.isEmpty) {
                                        setDialogState(() {
                                          testSuccess = false;
                                          testMessage = 'URL cannot be empty!';
                                        });
                                        return;
                                      }

                                      setDialogState(() {
                                        isTesting = true;
                                        testMessage = '';
                                      });

                                      final res = await DioClient.testConnection(target);

                                      setDialogState(() {
                                        isTesting = false;
                                        testSuccess = res.isSuccess;
                                        testMessage = res.message;
                                        lastTestedUrl = target;
                                      });
                                    },
                              icon: isTesting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.bolt_rounded, size: 16),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isTesting ? 'Testing...' : 'Test Connection',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Test Connection Feedback Banner
                      if (isTesting) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pinging and testing server connection...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (testSuccess == true) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  testMessage,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (testSuccess == false) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_rounded,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  testMessage,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Please run "Test Connection" to verify the server is reachable before applying.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

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
                                final target = serverUrlCtrl.text.trim();
                                if (target.isEmpty) {
                                  setDialogState(() {
                                    testSuccess = false;
                                    testMessage = 'URL cannot be empty!';
                                  });
                                  return;
                                }

                                var normalizedUrl = target;
                                if (!normalizedUrl.startsWith('http://') &&
                                    !normalizedUrl.startsWith('https://')) {
                                  normalizedUrl = 'https://$normalizedUrl';
                                }
                                if (normalizedUrl.endsWith('/')) {
                                  normalizedUrl = normalizedUrl.substring(
                                    0,
                                    normalizedUrl.length - 1,
                                  );
                                }

                                // Must verify connection before apply
                                if (testSuccess != true || lastTestedUrl != target) {
                                  setDialogState(() {
                                    isTesting = true;
                                    testMessage = '';
                                  });

                                  final testRes = await DioClient.testConnection(normalizedUrl);

                                  setDialogState(() {
                                    isTesting = false;
                                    testSuccess = testRes.isSuccess;
                                    testMessage = testRes.message;
                                    lastTestedUrl = target;
                                  });

                                  if (!testRes.isSuccess) {
                                    Get.snackbar(
                                      'Warning',
                                      'Server is unreachable. Please verify the URL and ensure the server is active before applying!',
                                      backgroundColor: Colors.red.shade700,
                                      colorText: Colors.white,
                                      icon: const Icon(Icons.error_outline, color: Colors.white),
                                      snackPosition: SnackPosition.TOP,
                                      duration: const Duration(seconds: 4),
                                    );
                                    return;
                                  }
                                }

                                await storageService.saveServerUrl(normalizedUrl);
                                if (Get.isRegistered<DioClient>()) {
                                  Get.find<DioClient>().updateBaseUrl(normalizedUrl);
                                }
                                if (Get.isRegistered<AuthController>()) {
                                  Get.find<AuthController>().rxServerUrlDisplay.value = normalizedUrl;
                                }

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }

                                Get.snackbar(
                                  'Success',
                                  'Base URL applied successfully: $normalizedUrl',
                                  backgroundColor: Colors.green.shade700,
                                  colorText: Colors.white,
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                  snackPosition: SnackPosition.TOP,
                                  duration: const Duration(seconds: 4),
                                );
                              },
                              child: Text(
                                'Apply Changes',
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
      ),
    );
  }
}
