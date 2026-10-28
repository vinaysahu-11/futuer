/// Configuration for InsForge Backend.
///
/// By default, credentials are empty placeholders so the app does NOT connect
/// to any dummy or unauthorized ID until you supply your credentials.
///
/// You can either:
/// 1. Enter your Project URL & Anon Key in this file, OR
/// 2. Launch the app and enter them directly on the Setup screen.
class InsforgeConfig {
  InsforgeConfig._();

  /// Your InsForge Project Base URL.
  /// Example: 'https://xyz123.us-east.insforge.app'
  /// Leave empty or set to your actual InsForge backend URL.
  static const String defaultUrl = '';

  /// Your InsForge Public Anonymous Key.
  /// Leave empty or set to your actual InsForge anon key.
  static const String defaultAnonKey = '';

  /// Optional OpenRouter / AI API key if utilizing InsForge AI gateway.
  static const String defaultAiKey = '';

  /// Checks if URL and Key are provided and not default placeholders.
  static bool isConfigured({String? url, String? anonKey}) {
    final effectiveUrl = (url ?? defaultUrl).trim();
    final effectiveKey = (anonKey ?? defaultAnonKey).trim();

    if (effectiveUrl.isEmpty || effectiveKey.isEmpty) {
      return false;
    }

    if (effectiveUrl.contains('YOUR_') || effectiveKey.contains('YOUR_')) {
      return false;
    }

    return true;
  }
}
