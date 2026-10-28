import 'dart:async';
import 'package:flutter/material.dart';
import 'package:futuer/config/theme.dart';
import 'package:futuer/models/device_model.dart';
import 'package:futuer/models/device_session.dart';
import 'package:futuer/services/audit_service.dart';
import 'package:futuer/services/device_service.dart';

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
      final active = sessions.where((s) => s.sessionType == 'MICROPHONE' && (s.status == 'REQUESTED' || s.status == 'ACTIVE')).toList();
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

  Future<void> _requestMicrophoneSession() async {
    setState(() => _isLoading = true);

    try {
      final session = await DeviceService.instance.requestSession(
        deviceId: widget.device.id,
        sessionType: 'MICROPHONE',
      );

      await AuditService.instance.log(
        action: 'MICROPHONE_SESSION_REQUESTED',
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
          SnackBar(content: Text('Failed to request audio session: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endMicrophoneSession() async {
    if (_activeSession == null) return;

    try {
      await DeviceService.instance.endSession(_activeSession!.id);
      await AuditService.instance.log(
        action: 'MICROPHONE_SESSION_ENDED',
        result: 'SUCCESS',
        deviceId: widget.device.id,
      );

      if (mounted) {
        setState(() {
          _activeSession = null;
        });
        _sessionPollTimer?.cancel();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Privacy Notice
          Card(
            color: FutuerTheme.brandSecondary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.mic_none, color: FutuerTheme.brandPrimary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Microphone sessions are authorized live sessions with explicit user consent. Covert audio recording or listening is prohibited.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_activeSession == null || _activeSession!.status == 'ENDED') ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FutuerTheme.darkSurfaceVariant,
                    ),
                    child: const Icon(Icons.mic_outlined, size: 64, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Active Audio Session',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Request an authorized real-time audio session from Futuer Agent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _requestMicrophoneSession,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.mic),
                    label: Text(_isLoading ? 'Requesting...' : 'Request Audio Session'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: FutuerTheme.brandSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Active Audio Session Indicator
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: FutuerTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _activeSession!.status == 'ACTIVE'
                      ? FutuerTheme.onlineColor
                      : Colors.orange,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 64,
                    color: _activeSession!.status == 'ACTIVE'
                        ? FutuerTheme.onlineColor
                        : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _activeSession!.status == 'ACTIVE'
                        ? 'LIVE AUDIO STREAM CONNECTED'
                        : 'AWAITING AGENT MICROPHONE APPROVAL...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _activeSession!.status == 'ACTIVE'
                          ? FutuerTheme.onlineColor
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Session ID: ${_activeSession!.id.substring(0, 8)}...',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _endMicrophoneSession,
              icon: const Icon(Icons.mic_off),
              label: const Text('End Audio Session'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
