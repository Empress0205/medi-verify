class AppConstants {
  AppConstants._();

  static const String baseUrl =
      'https://overdefensive-curtis-dominantly.ngrok-free.dev';

  static const String verifyEndpoint = '/verify/';

  static String get verifyUrl => '$baseUrl$verifyEndpoint';

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