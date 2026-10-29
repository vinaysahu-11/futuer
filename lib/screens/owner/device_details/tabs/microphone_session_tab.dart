import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../models/device_model.dart';
import '../../../../models/device_session.dart';
import '../../../../services/audit_service.dart';
import '../../../../services/device_service.dart';

class MicrophoneSessionTab extends StatefulWidget {
  final DeviceModel device;

  const MicrophoneSessionTab({super.key, required this.device});

  @override
  State<MicrophoneSessionTab> createState() => _MicrophoneSessionTabState();
}

class _MicrophoneSessionTabState extends State<MicrophoneSessionTab> {
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
          .where((s) => s.sessionType == 'MIC' && (s.status == 'REQUESTED' || s.status == 'ACTIVE'))
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

  Future<void> _requestMicSession() async {
    setState(() => _isLoading = true);

    try {
      final session = await DeviceService.instance.requestSession(
        deviceId: widget.device.id,
        sessionType: 'MIC',
      );

      await AuditService.instance.log(
        action: 'MIC_SESSION_REQUESTED',
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

  Future<void> _endMicSession() async {
    if (_activeSession == null) return;

    try {
      await DeviceService.instance.endSession(_activeSession!.id);
      await AuditService.instance.log(
        action: 'MIC_SESSION_ENDED',
        result: 'SUCCESS',
        deviceId: widget.device.id,
      );
      _sessionPollTimer?.cancel();
      if (mounted) {
        setState(() => _activeSession = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone session ended')),
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
          // Privacy Notice
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
                          'Authorized Audio Session Notice',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Microphone streaming requires explicit authorization on the enrolled device. Visible active status is maintained throughout the session.',
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
                      Icon(Icons.mic, color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'AUTHORIZED AUDIO SESSION ACTIVE',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Microphone audio session running. Prominent active icon displayed on target device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _endMicSession,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Audio Session'),
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
                    'Audio authorization request sent to the secondary phone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _endMicSession,
                    child: const Text('Cancel Request'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.mic_outlined, size: 56, color: FutuerTheme.brandSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Request Authorized Microphone Session',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline
                          ? 'Device is online and ready for audio session request.'
                          : 'Device is offline. Connect device to initiate microphone stream.',
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
                      onPressed: isOnline && !_isLoading ? _requestMicSession : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Start Microphone Session'),
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
