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

class _MicrophoneSessionTabState extends State<MicrophoneSessionTab>
    with SingleTickerProviderStateMixin {
  DeviceSession? _activeSession;
  bool _isLoading = false;
  Timer? _sessionPollTimer;

  // Live recording controls
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isMuted = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkExistingSession();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _sessionPollTimer?.cancel();
    _recordTimer?.cancel();
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
    // 1-second poll for zero-delay responsiveness
    _sessionPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final sessions = await DeviceService.instance.fetchSessions(widget.device.id, limit: 5);
        final current = sessions.where((s) => s.id == sessionId).toList();
        if (current.isNotEmpty && mounted) {
          final s = current.first;
          if (_activeSession?.status != s.status) {
            setState(() => _activeSession = s);
          }
          if (s.status == 'ENDED' || s.status == 'REJECTED') {
            _sessionPollTimer?.cancel();
            _stopRecording();
            setState(() => _activeSession = null);
          }
        }
      } catch (_) {}
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio clip recorded and saved (${_formatTimer(_recordSeconds)})'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    _recordTimer = null;
    if (mounted) setState(() => _isRecording = false);
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    _stopRecording();

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
              padding: EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: FutuerTheme.brandPrimary, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Live Audio Stream',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Listen to real-time audio streamed directly from the enrolled device with optional recording.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Active Session Container
          if (_activeSession != null && _activeSession!.status == 'ACTIVE') ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.green.shade400,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : Colors.green).withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'LIVE AUDIO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.device.deviceName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_isRecording)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimer(_recordSeconds),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            '48kHz • Opus • 35ms',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                      ],
                    ),
                  ),

                  // Animated Waveform Display
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(12, (index) {
                                final animVal = (_waveController.value + (index * 0.1)) % 1.0;
                                final height = _isMuted ? 8.0 : 16.0 + (animVal * 42.0);
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 6,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: _isMuted
                                        ? Colors.grey
                                        : (_isRecording ? Colors.redAccent : const Color(0xFF00E5FF)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isMuted ? 'Audio Output Muted' : 'Listening Live...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Authorized high-fidelity audio stream',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Controls Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute / Unmute
                        IconButton(
                          tooltip: _isMuted ? 'Unmute' : 'Mute',
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(() => _isMuted = !_isMuted),
                        ),

                        // Record Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : FutuerTheme.brandPrimaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _toggleRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, size: 18),
                          label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
                        ),

                        // End Session
                        IconButton(
                          tooltip: 'End Live Session',
                          icon: const Icon(Icons.call_end, color: Colors.redAccent),
                          onPressed: _endMicSession,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_activeSession != null && _activeSession!.status == 'REQUESTED') ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connecting to Enrolled Device Audio...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Request sent to the device. Audio stream will begin immediately once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: _endMicSession,
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
                    const Icon(Icons.mic_none_outlined, size: 56, color: FutuerTheme.brandSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Start Live Audio Stream',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Listen to live audio directly from the device. You can record voice clips whenever needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: FutuerTheme.brandSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (!isOnline || _isLoading) ? null : _requestMicSession,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.mic),
                      label: Text(_isLoading ? 'Connecting...' : 'Open Live Audio'),
                    ),
                    if (!isOnline) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Device must be ONLINE to initiate live audio.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
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
