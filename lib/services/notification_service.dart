import 'package:flutter/foundation.dart';
import 'enrollment_service.dart';
import 'insforge_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Uploads an authorized notification record to InsForge
  Future<void> recordNotification({
    required String appPackage,
    required String title,
    String? text,
  }) async {
    final deviceId = EnrollmentService.instance.cachedDeviceId;
    if (deviceId == null) return;

    try {
      final client = InsforgeService.instance.client;

      await client.database
          .from('device_notifications')
          .insert([
            {
              'device_id': deviceId,
              'app_package': appPackage.trim(),
              'notification_title': title.trim(),
              'notification_text': text?.trim(),
              'recorded_at': DateTime.now().toUtc().toIso8601String(),
            }
          ])
          .execute();
    } catch (e) {
      debugPrint('Notification upload error: $e');
    }
  }
}
