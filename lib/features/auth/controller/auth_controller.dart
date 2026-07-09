import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_result.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/shared/routes/app_pages.dart';
import '../repository/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthController(this._authRepository, this._storageService);

  // Splash Screen States
  final rxSplashMessage = 'splash_check_config'.obs;
  final rxIsLoadingSplash = true.obs;

  // Login Page States
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final rxIsObscurePassword = true.obs;
  final rxRememberMe = false.obs;
  final rxIsLoadingLogin = false.obs;
  final rxServerConnected = true.obs;
  final rxServerUrlDisplay = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedUsername();
    _loadServerUrl();
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

  // --- Splash Flow ---
  Future<void> runSplashFlow() async {
    rxIsLoadingSplash.value = true;
    
    // Step 1: Check Config
    rxSplashMessage.value = 'splash_check_config'.tr;
    await Future.delayed(const Duration(milliseconds: 1000));
    final serverUrl = await _storageService.getServerUrl();
    
    if (serverUrl.isEmpty) {
      // Configuration missing -> redirect to setting
      Get.offAllNamed(AppRoutes.configure);
      return;
    }

    // Step 2: Check Server
    rxSplashMessage.value = 'splash_check_server'.tr;
    final serverCheck = await _authRepository.checkServerConnection();
    
    if (serverCheck is Failure) {
      rxServerConnected.value = false;
      // Continue login in offline mode if cached, but for demo we assume success
      // If server check fails and it's a real server, we could warn, but for demo we proceed.
    } else {
      rxServerConnected.value = true;
    }

    // Step 3: Check Login Credentials
    rxSplashMessage.value = 'splash_check_login'.tr;
    await Future.delayed(const Duration(milliseconds: 1000));
    final token = await _storageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    
    rxIsLoadingSplash.value = false;
  }

  // --- Login Action ---
  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      Get.snackbar('error_title'.tr, 'username_required'.tr, 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (password.isEmpty) {
      Get.snackbar('error_title'.tr, 'password_required'.tr, 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    rxIsLoadingLogin.value = true;

    final result = await _authRepository.login(username, password);
    rxIsLoadingLogin.value = false;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveRememberMe(rxRememberMe.value);
      
      if (rxRememberMe.value) {
        await _storageService.saveUsername(username);
      } else {
        await _storageService.saveUsername('');
      }

      Get.offAllNamed(AppRoutes.dashboard);
    } else if (result is Failure) {
      Get.snackbar(
        'error_title'.tr, 
        (result as Failure).exception.message,
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white
      );
    }
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
