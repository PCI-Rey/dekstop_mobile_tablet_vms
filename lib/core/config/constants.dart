class AppConstants {
  static const String appName = 'VMS Operator Tablet';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '100';
  static const String companyName = 'Antigravity VMS';
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyServerUrl = 'server_url';
  static const String keyRememberMe = 'remember_me';
  static const String keySavedUsername = 'saved_username';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyPrinterConfig = 'printer_config';
  static const String keyCameraConfig = 'camera_config';
  
  // Defaults (Matching mobile_vms backend server)
  static const String defaultServerUrl = 'https://be-vms.app.bio-experience.com';
  static const String pathApi = 'api'; // Base API path (/{{pathapi}}...)
  static const String pathCdn = 'cdn'; // Base CDN endpoint path for visitor images (/{{pathcdn}}{path})

  // MQTT Public Broker Configuration
  static const String mqttHost = '103.193.15.67';
  static const int mqttPort = 1883;
  static const int mqttWsPort = 15765;
  static const String mqttUsername = 'user';
  static const String mqttPassword = 'root';
  static const String mqttTopicArrivedVisitor = 'notification/dashboard/viewer/arrived';

  /// Helper to resolve full CDN photo URL from API relative path: /{{pathcdn}}{path}
  static String getCdnImageUrl(String path, {String? baseUrl}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '';
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }
    final base = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl
        : defaultServerUrl;
    final cleanBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    // Format: /{{pathcdn}}{path} -> e.g. https://be-vms.app.bio-experience.com/cdn/faces/...
    if (cleanPath.startsWith('/$pathCdn/')) {
      return '$cleanBase$cleanPath';
    }
    return '$cleanBase/$pathCdn$cleanPath';
  }
}
