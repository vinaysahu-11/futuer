import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/device_model.dart';
import '../../../models/device_session.dart';
import '../../../services/audit_service.dart';
import '../../../services/device_service.dart';

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
      final active = sessions.where((s) => s.sessionType == 'CAMERA' && (s.status == 'REQUESTED' || s.status == 'ACTIVE')).toList();
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

      if (mounted) {
        setState(() {
          _activeSession = null;
        });
        _sessionPollTimer?.cancel();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Privacy and Transparency Notice
          Card(
            color: FutuerTheme.brandSecondary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: FutuerTheme.brandPrimary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Authorized sessions require explicit permission on the secondary Android phone. Android privacy indicators will display during active video sessions.',
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
                    child: const Icon(Icons.videocam_outlined, size: 64, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No Active Camera Session',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Initiate a user-authorized live camera session with Futuer Agent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _requestCameraSession,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.videocam),
                    label: Text(_isLoading ? 'Requesting...' : 'Request Camera Session'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: FutuerTheme.brandSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Active or Requested Session Container
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _activeSession!.status == 'ACTIVE'
                      ? FutuerTheme.onlineColor
                      : Colors.orange,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _activeSession!.status == 'ACTIVE'
                            ? Icons.videocam
                            : Icons.hourglass_top,
                        size: 54,
                        color: _activeSession!.status == 'ACTIVE'
                            ? FutuerTheme.onlineColor
                            : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _activeSession!.status == 'ACTIVE'
                            ? 'LIVE VIDEO STREAM ACTIVE'
                            : 'WAITING FOR AGENT AUTHORIZATION...',
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
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('REC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _endCameraSession,
              icon: const Icon(Icons.call_end),
              label: const Text('End Camera Session'),
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
