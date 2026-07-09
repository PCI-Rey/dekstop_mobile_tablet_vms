import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../config/constants.dart';

class StorageService extends GetxService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  Future<StorageService> init() async {
    return this;
  }

  // Token Management
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
  }

  // Configuration settings
  Future<void> saveServerUrl(String url) async {
    await _storage.write(key: AppConstants.keyServerUrl, value: url);
  }

  Future<String> getServerUrl() async {
    final url = await _storage.read(key: AppConstants.keyServerUrl);
    return url ?? AppConstants.defaultServerUrl;
  }

  Future<void> saveRememberMe(bool value) async {
    await _storage.write(key: AppConstants.keyRememberMe, value: value.toString());
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: AppConstants.keyRememberMe);
    return value == 'true';
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: AppConstants.keySavedUsername, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: AppConstants.keySavedUsername);
  }

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: AppConstants.keyThemeMode, value: mode);
  }

  Future<String> getThemeMode() async {
    final mode = await _storage.read(key: AppConstants.keyThemeMode);
    return mode ?? 'system';
  }

  Future<void> saveLanguage(String code) async {
    await _storage.write(key: AppConstants.keyLanguageCode, value: code);
  }

  Future<String> getLanguage() async {
    final code = await _storage.read(key: AppConstants.keyLanguageCode);
    return code ?? 'id';
  }

  // Camera & Printer Configurations (stored as JSON)
  Future<void> savePrinterConfig(Map<String, dynamic> config) async {
    await _storage.write(key: AppConstants.keyPrinterConfig, value: json.encode(config));
  }

  Future<Map<String, dynamic>?> getPrinterConfig() async {
    final data = await _storage.read(key: AppConstants.keyPrinterConfig);
    if (data == null) return null;
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCameraConfig(Map<String, dynamic> config) async {
    await _storage.write(key: AppConstants.keyCameraConfig, value: json.encode(config));
  }

  Future<Map<String, dynamic>?> getCameraConfig() async {
    final data = await _storage.read(key: AppConstants.keyCameraConfig);
    if (data == null) return null;
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Reset all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
