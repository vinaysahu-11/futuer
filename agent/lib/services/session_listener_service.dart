import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/insforge_config.dart';
import 'enrollment_service.dart';
import 'insforge_service.dart';

class SessionListenerService {
  SessionListenerService._();
  static final SessionListenerService instance = SessionListenerService._();

  Timer? _pollTimer;
  bool _isListening = false;
  final ValueNotifier<Map<String, dynamic>?> activeSessionNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  bool get isListening => _isListening;

  void start() {
    if (_isListening) return;
    _isListening = true;
    _pollSessions();
    _pollTimer = Timer.periodic(
      const Duration(seconds: InsforgeConfig.sessionPollIntervalSeconds),
      (_) => _pollSessions(),
    );
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isListening = false;
  }

  Future<void> _pollSessions() async {
    final deviceId = EnrollmentService.instance.cachedDeviceId;
    if (deviceId == null) return;

    try {
      final client = InsforgeService.instance.client;

      final rows = await client.database
          .from('device_sessions')
          .select()
          .eq('device_id', deviceId)
          .order('started_at', ascending: false)
          .limit(1)
          .execute();

      if (rows.isNotEmpty) {
        final session = rows.first;
        final status = session['status'] as String?;
        if (status == 'REQUESTED' || status == 'ACTIVE') {
          activeSessionNotifier.value = session;
          return;
        }
      }
      activeSessionNotifier.value = null;
    } catch (e) {
      debugPrint('Session listener poll error: $e');
    }
  }

  Future<void> updateSessionStatus({
    required String sessionId,
    required String status, // 'ACTIVE', 'REJECTED', 'ENDED'
  }) async {
    try {
      final client = InsforgeService.instance.client;

      await client.database
          .from('device_sessions')
          .eq('id', sessionId)
          .update({
            'status': status,
            if (status == 'ENDED' || status == 'REJECTED')
              'ended_at': DateTime.now().toUtc().toIso8601String(),
          })
          .execute();

      _pollSessions();
    } catch (e) {
      debugPrint('Update session status error: $e');
    }
  }
}
