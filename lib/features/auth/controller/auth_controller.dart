import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../../../core/shared/widgets/app_snackbar.dart';
import '../repository/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthController(this._authRepository, this._storageService);

  // Splash Screen States
  final rxSplashMessage = 'Checking server configuration...'.obs;
  final rxIsLoadingSplash = true.obs;

  // Login Page States
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final rxIsObscurePassword = true.obs;
  final rxRememberMe = false.obs;
  final rxIsLoadingLogin = false.obs;
  final rxServerConnected = true.obs;
  final rxServerUrlDisplay = ''.obs;

  // Captcha States
  final captchaController = TextEditingController();
  final rxCaptchaId = ''.obs;
  final rxCaptchaCode = ''.obs;
  final rxCaptchaSvg = ''.obs;
  final rxIsRefreshingCaptcha = false.obs;
  final rxCaptchaError = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _loadSavedUsername();
    _loadServerUrl();
    fetchCaptcha();
    captchaController.addListener(() {
      if (rxCaptchaError.value != null) rxCaptchaError.value = null;
    });
  }

  // Loaded at Startup
  Future<void> _loadSavedUsername() async {
    final remember = await _storageService.getRememberMe();
    rxRememberMe.value = remember;
    if (remember) {
      final savedUser = await _storageService.getUsername();
      if (savedUser != null) {
        usernameController.text = savedUser;
      }
    }
  }

  Future<void> _loadServerUrl() async {
    final url = await _storageService.getServerUrl();
    rxServerUrlDisplay.value = url;
  }

  // --- Splash Flow (3 Seconds Total) ---
  Future<void> runSplashFlow() async {
    rxIsLoadingSplash.value = true;
    
    // Step 1: Initialize System (1.5 seconds)
    rxSplashMessage.value = 'Initializing system...';
    await Future.delayed(const Duration(milliseconds: 1500));
    final serverUrl = await _storageService.getServerUrl();
    
    if (serverUrl.isEmpty) {
      Get.offAllNamed(AppRoutes.configure);
      return;
    }

    // Step 2: Check Login Session (1.5 seconds)
    rxSplashMessage.value = 'Checking login session...';
    await Future.delayed(const Duration(milliseconds: 1500));
    final token = await _storageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    
    rxIsLoadingSplash.value = false;
  }

    Future<void> fetchCaptcha() async {
    rxIsRefreshingCaptcha.value = true;
    captchaController.clear();
    rxCaptchaError.value = null;

    try {
      final res = await _authRepository.getCaptcha();
      if (res != null && res.captchaId.isNotEmpty) {
        rxCaptchaId.value = res.captchaId;
        rxCaptchaCode.value = res.captchaCode;
        rxCaptchaSvg.value = res.svgBackground;
        debugPrint(
          '🔥 [TABLET CAPTCHA LIVE] ID: ${res.captchaId} | CODE: ${res.captchaCode}',
        );
      } else {
        _generateDummyCaptcha();
      }
    } catch (e) {
      debugPrint('⚠️ [TABLET CAPTCHA ERROR] $e');
      _generateDummyCaptcha();
    } finally {
      rxIsRefreshingCaptcha.value = false;
    }
  }

  void _generateDummyCaptcha() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = math.Random();
    final newCode =
        List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    rxCaptchaCode.value = newCode;
    rxCaptchaSvg.value = '';
    rxCaptchaId.value = '';
  }

  Future<void> refreshCaptcha() async {
    await fetchCaptcha();
  }

  // --- Login Action ---
  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final captcha = captchaController.text.trim();

    if (username.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message: 'Username is required',
      );
      return;
    }
    if (password.isEmpty) {
      AppSnackbar.error(
        title: 'Validation Error',
        message: 'Password is required',
      );
      return;
    }
    if (captcha.isEmpty) {
      rxCaptchaError.value = 'Please enter the captcha code';
      return;
    }

    // Local fallback check if dummy was generated
    if (rxCaptchaSvg.value.isEmpty && rxCaptchaCode.value.isNotEmpty) {
      if (captcha.toUpperCase() != rxCaptchaCode.value.toUpperCase()) {
        rxCaptchaError.value = 'Invalid captcha code';
        refreshCaptcha();
        return;
      }
    }

    rxIsLoadingLogin.value = true;

    final result = await _authRepository.login(
      username,
      password,
      captchaId: rxCaptchaId.value.isNotEmpty ? rxCaptchaId.value : null,
      captchaAnswer: captcha,
    );
    rxIsLoadingLogin.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final collection = (data['collection'] is Map)
          ? data['collection'] as Map<String, dynamic>
          : data;

      final accessToken = (collection['access_token'] ??
              collection['token'] ??
              data['access_token'] ??
              data['token'] ??
              data['data']?['access_token'] ??
              data['data']?['token'] ??
              '')
          .toString();
      final refreshToken = (collection['refresh_token'] ??
              data['refresh_token'] ??
              data['data']?['refresh_token'] ??
              '')
          .toString();
      
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveRememberMe(rxRememberMe.value);
      
      if (rxRememberMe.value) {
        await _storageService.saveUsername(username);
      } else {
        await _storageService.saveUsername('');
      }

      final successMsg = (data['msg'] ?? 'Welcome back, $username!').toString();

      AppSnackbar.success(
        title: 'Login Successful',
        message: successMsg,
      );

      Get.offAllNamed(AppRoutes.dashboard);
    } else if (result is Failure) {
      final msg = (result as Failure).exception.message;
      if (msg.toLowerCase().contains('captcha')) {
        rxCaptchaError.value = msg;
      }
      AppSnackbar.error(
        title: 'Login Failed',
        message: msg,
      );
      refreshCaptcha();
    }
  }

  // --- Tapping Card Action ---
  void loginWithCard() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contactless_rounded,
                  size: 64,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tapping Card',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please place your RFID / NFC access card on the card reader.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Logout Action ---
  void logout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('logout'.tr),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await _storageService.clearTokens();
              Get.back(); // close dialog
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text('logout'.tr),
          ),
        ],
      )
    );
  }
}
