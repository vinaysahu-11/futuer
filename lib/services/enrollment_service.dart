import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pairing_request.dart';
import 'insforge_service.dart';
import 'role_service.dart';

class EnrollmentService {
  EnrollmentService._();
  static final EnrollmentService instance = EnrollmentService._();

  static const _storage = FlutterSecureStorage();
  static const _keyDeviceId = 'futuer_agent_device_id';
  static const _keyDeviceName = 'futuer_agent_device_name';
  static const _keyControllerId = 'futuer_agent_controller_id';

  String? _cachedDeviceId;
  String? _cachedDeviceName;
  String? _cachedControllerId;

  String? get cachedDeviceId => _cachedDeviceId;
  String? get cachedDeviceName => _cachedDeviceName;
  String? get cachedControllerId => _cachedControllerId;

  // Rate limiting for code verification: track consecutive failures
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  Future<bool> checkEnrollment() async {
    _cachedDeviceId = await _storage.read(key: _keyDeviceId);
    _cachedDeviceName = await _storage.read(key: _keyDeviceName);
    _cachedControllerId = await _storage.read(key: _keyControllerId);
    return _cachedDeviceId != null && _cachedDeviceId!.isNotEmpty;
  }

  /// Validates format and checks if lockout is active
  void _checkRateLimit() {
    if (_lockoutUntil != null) {
      if (DateTime.now().isBefore(_lockoutUntil!)) {
        final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
        throw StateError('Too many failed attempts. Please wait $remaining seconds before trying again.');
      } else {
        _lockoutUntil = null;
        _failedAttempts = 0;
      }
    }
  }

  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

  void _recordSuccess() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Verifies format and looks up the pending pairing request to show confirmation details
  Future<PairingRequest> lookupPairingCode(String pairingCode) async {
    _checkRateLimit();

    final code = pairingCode.trim().toUpperCase();
    if (code.isEmpty || code.length < 4) {
      throw ArgumentError('Please enter a valid pairing code (e.g. FUT-123).');
    }

    final client = InsforgeService.instance.client;

    try {
      final rows = await client.database
          .from('pairing_requests')
          .select()
          .eq('pairing_code', code)
          .eq('status', 'PENDING')
          .limit(1)
          .execute();

      if (rows.isEmpty) {
        _recordFailure();
        throw StateError('Invalid pairing code, or the code has expired or already been used.');
      }

      final req = PairingRequest.fromJson(rows.first);
      if (req.isExpired) {
        _recordFailure();
        throw StateError('This pairing code has expired. Please ask the Controller to generate a new one.');
      }

      return req;
    } catch (e) {
      if (e is! StateError && e is! ArgumentError) {
        debugPrint('Error looking up pairing code: $e');
        throw StateError('Could not verify pairing code. Please check your network connection.');
      }
      rethrow;
    }
  }

  /// Atomically confirms pairing using stored procedure verify_and_consume_pairing_code
  Future<Map<String, dynamic>> confirmAndPairDevice({
    required String pairingCode,
    String? deviceModel,
  }) async {
    _checkRateLimit();

    final client = InsforgeService.instance.client;
    final code = pairingCode.trim().toUpperCase();

    try {
      final dynamic rawResult = await client.database
          .rpc('verify_and_consume_pairing_code', args: {
            'p_code': code,
            'p_device_model': deviceModel ?? 'Android Phone',
          })
          .execute();

      Map<String, dynamic> result;
      if (rawResult is Map) {
        result = Map<String, dynamic>.from(rawResult);
      } else {
        throw StateError('Unexpected response from backend pairing service.');
      }

      if (result['success'] != true) {
        _recordFailure();
        final err = result['error']?.toString() ?? 'Pairing failed. Code may be expired or already consumed.';
        throw StateError(err);
      }

      _recordSuccess();

      final deviceId = result['device_id'] as String;
      final deviceName = result['device_name'] as String? ?? 'Futuer Agent';
      final controllerId = result['controller_user_id'] as String? ?? '';

      // Persist credentials securely
      await _storage.write(key: _keyDeviceId, value: deviceId);
      await _storage.write(key: _keyDeviceName, value: deviceName);
      await _storage.write(key: _keyControllerId, value: controllerId);
      await RoleService.instance.setConfiguredRole(FutuerRole.agent);

      _cachedDeviceId = deviceId;
      _cachedDeviceName = deviceName;
      _cachedControllerId = controllerId;

      return result;
    } catch (e) {
      debugPrint('Pairing confirmation failed: $e');
      rethrow;
    }
  }

  /// Revokes local device enrollment
  Future<void> unpair() async {
    await _storage.delete(key: _keyDeviceId);
    await _storage.delete(key: _keyDeviceName);
    await _storage.delete(key: _keyControllerId);
    _cachedDeviceId = null;
    _cachedDeviceName = null;
    _cachedControllerId = null;
    _recordSuccess();
  }
}
