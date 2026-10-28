import 'dart:async';
import 'package:flutter/foundation.dart';
import 'enrollment_service.dart';
import 'insforge_service.dart';

class HeartbeatService {
  HeartbeatService._();
  static final HeartbeatService instance = HeartbeatService._();

  Timer? _timer;
  bool _isRunning = false;
  final ValueNotifier<DateTime?> lastHeartbeatNotifier = ValueNotifier<DateTime?>(null);

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _sendHeartbeat();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  Future<void> _sendHeartbeat({
    Map<String, bool>? permissions,
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    final deviceId = EnrollmentService.instance.cachedDeviceId;
    if (deviceId == null) return;

    try {
      final nowUtc = DateTime.now().toUtc();
      final client = InsforgeService.instance.client;

      // 1. Insert into device_heartbeats
      await client.database
          .from('device_heartbeats')
          .insert({
            'device_id': deviceId,
            'connection_state': 'ONLINE',
            'app_version': '1.0.0',
            'battery_level': batteryLevel ?? 88,
            'received_at': nowUtc.toIso8601String(),
          })
          .execute();

      // 2. Update last_seen_at on devices
      final updateData = <String, dynamic>{
        'last_seen_at': nowUtc.toIso8601String(),
        'battery_level': batteryLevel ?? 88,
        'is_charging': isCharging,
        'updated_at': nowUtc.toIso8601String(),
      };

      if (permissions != null) {
        updateData['permission_status'] = permissions;
      }

      await client.database
          .from('devices')
          .eq('id', deviceId)
          .update(updateData)
          .execute();

      lastHeartbeatNotifier.value = DateTime.now();
    } catch (e) {
      debugPrint('Heartbeat transmission error: $e');
    }
  }

  /// Manually triggers an immediate heartbeat update
  Future<void> triggerHeartbeat({
    Map<String, bool>? permissions,
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    await _sendHeartbeat(
      permissions: permissions,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
  }
}
