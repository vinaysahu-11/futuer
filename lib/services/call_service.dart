import 'package:flutter/foundation.dart';
import 'enrollment_service.dart';
import 'insforge_service.dart';

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  /// Records supported call activity to InsForge
  Future<void> recordCall({
    required String callType, // 'INCOMING', 'OUTGOING', 'MISSED'
    String? phoneNumber,
    required DateTime startedAt,
    int? durationSeconds,
  }) async {
    final deviceId = EnrollmentService.instance.cachedDeviceId;
    if (deviceId == null) return;

    try {
      final client = InsforgeService.instance.client;

      await client.database
          .from('call_activity')
          .insert([
            {
              'device_id': deviceId,
              'call_type': callType.toUpperCase(),
              'phone_number': phoneNumber?.trim(),
              'started_at': startedAt.toUtc().toIso8601String(),
              'duration_seconds': durationSeconds,
              'recorded_at': DateTime.now().toUtc().toIso8601String(),
            }
          ])
          .execute();
    } catch (e) {
      debugPrint('Call log upload error: $e');
    }
  }
}
