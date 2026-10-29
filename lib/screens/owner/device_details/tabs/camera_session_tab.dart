import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../models/device_model.dart';
import '../../../../models/device_session.dart';
import '../../../../services/audit_service.dart';
import '../../../../services/device_service.dart';

class CameraSessionTab extends StatefulWidget {
  final DeviceModel device;

  const CameraSessionTab({super.key, required this.device});

  @override
  State<CameraSessionTab> createState() => _CameraSessionTabState();
}

class _CameraSessionTabState extends State<CameraSessionTab> {
  DeviceSession? _activeSession;
  bool _isLoading = false;
  Timer? _sessionPollTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _sessionPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final sessions = await DeviceService.instance.fetchSessions(widget.device.id, limit: 5);
      final active = sessions
          .where((s) => s.sessionType == 'CAMERA' && (s.status == 'REQUESTED' || s.status == 'ACTIVE'))
          .toList();
      if (active.isNotEmpty && mounted) {
        setState(() => _activeSession = active.first);
        _startPollTimer(active.first.id);
      }
    } catch (_) {}
  }

  void _startPollTimer(String sessionId) {
    _sessionPollTimer?.cancel();
    _sessionPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final sessions = await DeviceService.instance.fetchSessions(widget.device.id, limit: 5);
        final current = sessions.where((s) => s.id == sessionId).toList();
        if (current.isNotEmpty && mounted) {
          setState(() => _activeSession = current.first);
          if (current.first.status == 'ENDED' || current.first.status == 'REJECTED') {
            _sessionPollTimer?.cancel();
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _requestCameraSession() async {
    setState(() => _isLoading = true);

    try {
      final session = await DeviceService.instance.requestSession(
        deviceId: widget.device.id,
        sessionType: 'CAMERA',
      );

      await AuditService.instance.log(
        action: 'CAMERA_SESSION_REQUESTED',
        result: 'SUCCESS',
        deviceId: widget.device.id,
      );

      if (mounted) {
        setState(() {
          _activeSession = session;
          _isLoading = false;
        });
        _startPollTimer(session.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request session: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endCameraSession() async {
    if (_activeSession == null) return;

    try {
      await DeviceService.instance.endSession(_activeSession!.id);
      await AuditService.instance.log(
        action: 'CAMERA_SESSION_ENDED',
        result: 'SUCCESS',
        deviceId: widget.device.id,
      );
      _sessionPollTimer?.cancel();
      if (mounted) {
        setState(() => _activeSession = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera session ended')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end session: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = widget.device.status == DeviceStatus.online;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Privacy & Authorization Notice
          Card(
            color: FutuerTheme.brandPrimary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: FutuerTheme.brandPrimary.withValues(alpha: 0.3)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: FutuerTheme.brandPrimary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explicit User Authorization Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Camera sessions require Android permissions and user authorization on the enrolled device. A visible indicator will appear on both devices during streaming.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Session Indicator
          if (_activeSession != null && _activeSession!.status == 'ACTIVE') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 2),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'AUTHORIZED CAMERA SESSION ACTIVE',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Streaming active. Visible notification displayed on enrolled phone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _endCameraSession,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Live Camera Session'),
                  ),
                ],
              ),
            ),
          ] else if (_activeSession != null && _activeSession!.status == 'REQUESTED') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Waiting for Device User Consent...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A prompt has been sent to the enrolled device. Session begins when accepted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _endCameraSession,
                    child: const Text('Cancel Request'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Initiation card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.videocam_outlined, size: 56, color: FutuerTheme.brandSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Request Authorized Camera Session',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline
                          ? 'Device is online and ready to receive session requests.'
                          : 'Device is currently offline. Sessions can only be started when the device is online.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isOnline ? Colors.grey : Colors.red),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: FutuerTheme.brandSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isOnline && !_isLoading ? _requestCameraSession : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Start Camera Session'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
