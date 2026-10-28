/// Configuration for InsForge Backend.
///
/// Linked project: futuer123 (8b68b972-f8f5-4f51-a96d-cac5b84afaa6)
/// Account: projecttest1437@gmail.com
class InsforgeConfig {
  InsforgeConfig._();

  /// Your InsForge Project Base URL.
  static const String defaultUrl = 'https://6krn5up4.us-east.insforge.app';

  /// Your InsForge Project API / Anon Key.
  static const String defaultAnonKey = 'ik_3039eac4f5de85011d8a2ddf076aab68';

  /// Project Identifier.
  static const String projectId = '8b68b972-f8f5-4f51-a96d-cac5b84afaa6';

  /// Optional OpenRouter / AI API key if utilizing InsForge AI gateway.
  static const String defaultAiKey = '';

  /// Checks if URL and Key are provided and not empty placeholders.
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
