/// InsForge Backend Configuration for Futuer Controller.
class InsforgeConfig {
  InsforgeConfig._();

  static const String projectId = '8b68b972-f8f5-4f51-a96d-cac5b84afaa6';
  static const String projectName = 'futuer123';
  static const String baseUrl = 'https://6krn5up4.us-east.insforge.app';
  static const String apiKey = 'ik_3039eac4f5de85011d8a2ddf076aab68';
  static const String anonKey = 'ik_3039eac4f5de85011d8a2ddf076aab68';

  // Server-side heartbeat timeout before marking device offline (in seconds)
  static const int heartbeatTimeoutSeconds = 60;
  // Polling interval for controller dashboard (in seconds)
  static const int dashboardPollIntervalSeconds = 5;
}
