class AppConstants {
  AppConstants._();

  // Base URL is injected at build time: --dart-define=API_BASE_URL=...
  // Default targets the host machine from the Android emulator (10.0.2.2).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String verifyEndpoint = '/verify';
  static const String reportEndpoint = '/reports';

  static String get verifyUrl => '$baseUrl$verifyEndpoint';
  static String get reportUrl => '$baseUrl$reportEndpoint';

  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 60;

  static const int maxImageSizeBytes = 10 * 1024 * 1024;
  static const int imageQuality = 85;
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1920;

  static const String appName = 'MediVerify';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@mediverify.com';
}