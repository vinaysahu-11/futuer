import 'package:flutter/foundation.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../config/insforge_config.dart';

class InsforgeService {
  InsforgeService._();
  static final InsforgeService instance = InsforgeService._();

  InsforgeClient? _client;

  bool get isInitialized => _client != null;

  InsforgeClient get client {
    final c = _client;
    if (c == null) {
      throw StateError('InsforgeService is not initialized. Call initialize() first.');
    }
    return c;
  }

  Future<void> initialize() async {
    try {
      if (_client != null) return;

      final newClient = InsforgeClient(
        InsforgeConfig.baseUrl,
        InsforgeConfig.anonKey,
        apiKey: InsforgeConfig.apiKey,
        sessionStorage: SecureSessionStorage(),
      );

      await newClient.restoreSession();
      _client = newClient;
    } catch (e) {
      debugPrint('Agent InsforgeService initialize failed: $e');
      rethrow;
    }
  }
}
