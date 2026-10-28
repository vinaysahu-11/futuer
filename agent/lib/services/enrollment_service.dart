import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'insforge_service.dart';

class EnrollmentService {
  EnrollmentService._();
  static final EnrollmentService instance = EnrollmentService._();

  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = 'futuer_agent_device_id';
  static const _keyDeviceName = 'futuer_agent_device_name';

  String? _cachedDeviceId;
  String? _cachedDeviceName;

  String? get cachedDeviceId => _cachedDeviceId;
  String? get cachedDeviceName => _cachedDeviceName;

  Future<bool> checkEnrollment() async {
    _cachedDeviceId = await _storage.read(key: _keyDeviceId);
    _cachedDeviceName = await _storage.read(key: _keyDeviceName);
    return _cachedDeviceId != null && _cachedDeviceId!.isNotEmpty;
  }

  /// Pairs this agent with the Futuer Controller using the 6-character pairing code
  Future<Map<String, dynamic>> pairDevice({
    required String pairingCode,
    String? deviceModel,
  }) async {
    final client = InsforgeService.instance.client;
    final code = pairingCode.trim().toUpperCase();

    // 1. Look up device with matching pairing code
    final rows = await client.database
        .from('devices')
        .select()
        .eq('pairing_code', code)
        .limit(1)
        .execute();

    if (rows.isEmpty) {
      throw StateError('Invalid pairing code. Please check the code on Futuer Controller.');
    }

    final device = rows.first;
    final expiresStr = device['pairing_code_expires_at']?.toString();
    if (expiresStr != null) {
      final expiresAt = DateTime.tryParse(expiresStr);
      if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.toUtc())) {
        throw StateError('Pairing code has expired. Please generate a new code on Controller.');
      }
    }

    final deviceId = device['id'] as String;
    final deviceName = device['device_name'] as String? ?? 'Futuer Agent';

    // 2. Mark device as paired and save initial telemetry
    await client.database
        .from('devices')
        .eq('id', deviceId)
        .update({
          'is_paired': true,
          'device_model': deviceModel ?? 'Android Phone',
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .execute();

    // 3. Persist pairing locally in secure storage
    await _storage.write(key: _keyDeviceId, value: deviceId);
    await _storage.write(key: _keyDeviceName, value: deviceName);

    _cachedDeviceId = deviceId;
    _cachedDeviceName = deviceName;

    return device;
  }

  /// Revokes local enrollment
  Future<void> unpair() async {
    await _storage.delete(key: _keyDeviceId);
    await _storage.delete(key: _keyDeviceName);
    _cachedDeviceId = null;
    _cachedDeviceName = null;
  }
}
