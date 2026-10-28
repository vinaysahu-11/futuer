import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../config/insforge_config.dart';

/// Central service responsible for initializing and managing the InsForge backend connection.
class InsforgeService {
  InsforgeService._();
  static final InsforgeService instance = InsforgeService._();

  static const _storage = FlutterSecureStorage();
  static const _keySavedUrl = 'insforge_saved_url';
  static const _keySavedAnonKey = 'insforge_saved_anon_key';

  InsforgeClient? _client;

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> activeUrlNotifier = ValueNotifier<String?>(null);

  bool get isConnected => isConnectedNotifier.value && _client != null;
  String? get activeUrl => activeUrlNotifier.value;

  /// The active InsForge client.
  InsforgeClient get client {
    final c = _client;
    if (c == null) {
      throw StateError('InsForge client is not initialized. Connect backend first.');
    }
    return c;
  }

  /// Loads stored credentials or fallback to [InsforgeConfig] and attempts initialization.
  Future<bool> initializeFromSavedOrConfig() async {
    try {
      String? savedUrl = await _storage.read(key: _keySavedUrl);
      String? savedKey = await _storage.read(key: _keySavedAnonKey);

      final url = (savedUrl != null && savedUrl.trim().isNotEmpty)
          ? savedUrl.trim()
          : InsforgeConfig.defaultUrl.trim();

      final anonKey = (savedKey != null && savedKey.trim().isNotEmpty)
          ? savedKey.trim()
          : InsforgeConfig.defaultAnonKey.trim();

      if (InsforgeConfig.isConfigured(url: url, anonKey: anonKey)) {
        return await connect(url: url, anonKey: anonKey, persist: false);
      }
    } catch (e) {
      debugPrint('Error restoring saved InsForge configuration: $e');
    }
    return false;
  }

  /// Connects to InsForge with the provided [url] and [anonKey].
  Future<bool> connect({
    required String url,
    required String anonKey,
    bool persist = true,
  }) async {
    try {
      final sanitizedUrl = _sanitizeUrl(url);

      if (_client != null) {
        await _client!.dispose();
        _client = null;
      }

      final newClient = InsforgeClient(
        sanitizedUrl,
        anonKey.trim(),
        sessionStorage: SecureSessionStorage(),
      );

      try {
        await newClient.restoreSession();
      } catch (e) {
        debugPrint('Session restore skipped or failed: $e');
      }
      _client = newClient;

      if (persist) {
        await _storage.write(key: _keySavedUrl, value: sanitizedUrl);
        await _storage.write(key: _keySavedAnonKey, value: anonKey.trim());
      }

      activeUrlNotifier.value = sanitizedUrl;
      isConnectedNotifier.value = true;
      return true;
    } catch (e) {
      debugPrint('Failed to connect to InsForge: $e');
      _client = null;
      isConnectedNotifier.value = false;
      activeUrlNotifier.value = null;
      rethrow;
    }
  }

  /// Clears stored connection credentials and resets the client.
  Future<void> disconnect() async {
    try {
      if (_client != null) {
        await _client!.auth.signOut();
        await _client!.dispose();
        _client = null;
      }
      await _storage.delete(key: _keySavedUrl);
      await _storage.delete(key: _keySavedAnonKey);
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    } finally {
      isConnectedNotifier.value = false;
      activeUrlNotifier.value = null;
    }
  }

  /// Helper to ensure the URL has the correct scheme.
  String _sanitizeUrl(String input) {
    var trimmed = input.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
