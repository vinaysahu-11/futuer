import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:insforge_flutter/insforge_flutter.dart';

/// A robust, non-blocking SessionStorage implementation for InsForge.
/// Uses an instant in-memory cache combined with FlutterSecureStorage
/// configured with strict 1.5s timeouts so Android KeyStore locks can NEVER hang the app.
class SafeSessionStorage implements SessionStorage {
  SafeSessionStorage();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  final Map<String, String> _memoryCache = {};

  @override
  Future<void> write(String key, String value) async {
    _memoryCache[key] = value;
    try {
      await _storage
          .write(key: key, value: value)
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {
        debugPrint('SafeSessionStorage write timed out (cached in memory)');
      });
    } catch (e) {
      debugPrint('SafeSessionStorage write warning: $e');
    }
  }

  @override
  Future<String?> read(String key) async {
    // Return immediately from memory cache if available
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    try {
      final val = await _storage
          .read(key: key)
          .timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      if (val != null) {
        _memoryCache[key] = val;
      }
      return val;
    } catch (e) {
      debugPrint('SafeSessionStorage read warning: $e');
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    _memoryCache.remove(key);
    try {
      await _storage
          .delete(key: key)
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {
        debugPrint('SafeSessionStorage delete timed out (cleared from memory)');
      });
    } catch (e) {
      debugPrint('SafeSessionStorage delete warning: $e');
    }
  }
}
