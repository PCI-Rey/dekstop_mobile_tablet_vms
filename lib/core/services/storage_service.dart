import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';

class StorageService extends GetxService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const String _boxCardTap = 'card_tap_visitors_box';
  static const String _keyVisitorsList = 'visitors_list';
  late Box _cardTapBox;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    _cardTapBox = await Hive.openBox(_boxCardTap);
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
    if (url == null || url.isEmpty || url.contains('example.com')) {
      return AppConstants.defaultServerUrl;
    }
    return url;
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

  // Card Tap Visitors Persistence (Hive with 5-minute TTL auto-expiration)
  static const Duration cardTapTtl = Duration(minutes: 5);

  Future<void> saveCardTapVisitors(List<Map<String, dynamic>> visitors) async {
    final now = DateTime.now();
    // Only persist visitors created within the 5-minute TTL
    final validVisitors = visitors.where((v) {
      final createdStr = v['createdAt'];
      if (createdStr != null) {
        try {
          final dt = DateTime.parse(createdStr);
          return now.difference(dt) <= cardTapTtl;
        } catch (_) {}
      }
      return true;
    }).toList();

    final jsonList = validVisitors.map((v) => json.encode(v)).toList();
    await _cardTapBox.put(_keyVisitorsList, jsonList);
  }

  List<Map<String, dynamic>> getCardTapVisitors({Duration maxAge = cardTapTtl}) {
    final rawList = _cardTapBox.get(_keyVisitorsList);
    if (rawList == null) return [];
    try {
      final now = DateTime.now();
      final list = List<dynamic>.from(rawList);
      final validItems = <Map<String, dynamic>>[];
      bool hasExpired = false;

      for (final item in list) {
        Map<String, dynamic> map;
        if (item is String) {
          map = Map<String, dynamic>.from(json.decode(item));
        } else if (item is Map) {
          map = Map<String, dynamic>.from(item);
        } else {
          continue;
        }

        if (map.isEmpty) continue;

        // Verify if record is within 5-minute TTL
        final createdStr = map['createdAt'];
        if (createdStr != null) {
          try {
            final dt = DateTime.parse(createdStr);
            if (now.difference(dt) > maxAge) {
              hasExpired = true;
              continue; // Drop expired item
            }
          } catch (_) {}
        }
        validItems.add(map);
      }

      // If any expired records were dropped, clean up Hive storage
      if (hasExpired) {
        saveCardTapVisitors(validItems);
      }

      return validItems;
    } catch (_) {
      return [];
    }
  }

  Future<void> addCardTapVisitor(Map<String, dynamic> visitor) async {
    final currentList = getCardTapVisitors();
    currentList.insert(0, visitor);
    await saveCardTapVisitors(currentList);
  }

  Future<void> clearCardTapVisitors() async {
    await _cardTapBox.delete(_keyVisitorsList);
  }

  // Reset all
  Future<void> clearAll() async {
    await _storage.deleteAll();
    await clearCardTapVisitors();
  }
}
