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

  // MQTT Public Broker Configuration
  static const String mqttHost = '103.193.15.67';
  static const int mqttPort = 1883;
  static const int mqttWsPort = 15765;
  static const String mqttUsername = 'user';
  static const String mqttPassword = 'root';
  static const String mqttTopicArrivedVisitor = 'notification/dashboard/viewer/arrived';
}
