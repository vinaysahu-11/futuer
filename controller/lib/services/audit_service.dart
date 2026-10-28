import 'auth_service.dart';
import 'insforge_service.dart';

class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  Future<void> log({
    required String action,
    required String result,
    String? deviceId,
  }) async {
    try {
      final ownerId = AuthService.instance.currentUser?.id;
      if (ownerId == null) return;

      await InsforgeService.instance.client.database
          .from('device_audit_logs')
          .insert({
            'owner_user_id': ownerId,
            'device_id': deviceId,
            'action': action,
            'result': result,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .execute();
    } catch (_) {
      // Best-effort auditing, do not crash UI
    }
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs({int limit = 50}) async {
    final ownerId = AuthService.instance.currentUser?.id;
    if (ownerId == null) return [];

    return await InsforgeService.instance.client.database
        .from('device_audit_logs')
        .select()
        .eq('owner_user_id', ownerId)
        .order('created_at', ascending: false)
        .limit(limit)
        .execute();
  }
}
