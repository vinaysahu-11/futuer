import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/call_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/heartbeat_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/session_listener_service.dart';
import '../enrollment/welcome_screen.dart';
import '../session/active_session_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _enrollment = EnrollmentService.instance;
  final _heartbeat = HeartbeatService.instance;
  final _location = LocationService.instance;
  final _sessionListener = SessionListenerService.instance;

  @override
  void initState() {
    super.initState();
    // Start continuous background operations
    _heartbeat.start();
    _location.start();
    _sessionListener.start();
    _sessionListener.activeSessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _sessionListener.activeSessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final session = _sessionListener.activeSessionNotifier.value;
    if (session != null && session['status'] == 'REQUESTED' && mounted) {
      _showSessionPrompt(session);
    }
  }

  void _showSessionPrompt(Map<String, dynamic> session) {
    final type = session['session_type'] ?? 'CAMERA';
    final sessionId = session['id'] as String;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  type == 'CAMERA' ? Icons.videocam : Icons.mic,
                  color: FutuerAgentTheme.brandPrimary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Authorized $type Request',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your Futuer Controller is requesting an authorized real-time $type session. Do you wish to accept?',
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _sessionListener.updateSessionStatus(sessionId: sessionId, status: 'REJECTED');
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: FutuerAgentTheme.brandPrimary),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final navigator = Navigator.of(context);
                      await _sessionListener.updateSessionStatus(sessionId: sessionId, status: 'ACTIVE');
                      if (mounted) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => ActiveSessionScreen(
                              sessionId: sessionId,
                              sessionType: type,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Accept & Stream', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnpair() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpair This Device?'),
        content: const Text(
          'This will remove enrollment authorization on this secondary phone and stop all remote synchronization.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _heartbeat.stop();
      _location.stop();
      _sessionListener.stop();
      await _enrollment.unpair();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('hh:mm:ss a');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: FutuerAgentTheme.onlineColor,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FUTUER AGENT',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Unpair Device',
            icon: const Icon(Icons.link_off),
            onPressed: _handleUnpair,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enrollment Badge Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: FutuerAgentTheme.onlineColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'DEVICE ENROLLED & ACTIVE',
                          style: TextStyle(
                            color: FutuerAgentTheme.onlineColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _enrollment.cachedDeviceName ?? 'Futuer Agent',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Device ID: ${_enrollment.cachedDeviceId ?? "N/A"}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: _heartbeat.lastHeartbeatNotifier,
                      builder: (context, lastHeartbeat, _) {
                        return Text(
                          lastHeartbeat != null
                              ? 'Last Heartbeat Sent: ${dateFormat.format(lastHeartbeat.toLocal())}'
                              : 'Heartbeat: Transmitting...',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Background Services Status
            Text(
              'Background Operation Services',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildServiceStatusCard(
              title: 'Heartbeat Worker',
              desc: 'Periodic online verification every 30s',
              isActive: _heartbeat.isRunning,
              icon: Icons.favorite_border,
            ),
            _buildServiceStatusCard(
              title: 'Location Service',
              desc: 'GPS position recording every 60s',
              isActive: _location.isRunning,
              icon: Icons.location_searching,
            ),
            _buildServiceStatusCard(
              title: 'Session Listener',
              desc: 'Listening for authorized live camera/mic sessions',
              isActive: _sessionListener.isListening,
              icon: Icons.sensors,
            ),
            const SizedBox(height: 20),

            // Testing / Simulation Controls
            Text(
              'Quick Actions & Telemetry Upload',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FilledButton.tonalIcon(
              onPressed: () async {
                await _heartbeat.triggerHeartbeat();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Heartbeat transmitted to InsForge')),
                  );
                }
              },
              icon: const Icon(Icons.sync),
              label: const Text('Transmit Immediate Heartbeat'),
            ),
            const SizedBox(height: 8),

            FilledButton.tonalIcon(
              onPressed: () async {
                final pos = await _location.forceUpdateLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        pos != null
                            ? 'Location uploaded: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                            : 'Location capture unavailable or permission denied',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Capture & Upload Location'),
            ),
            const SizedBox(height: 8),

            FilledButton.tonalIcon(
              onPressed: () async {
                await NotificationService.instance.recordNotification(
                  appPackage: 'com.google.android.apps.messaging',
                  title: 'Security Alert',
                  text: 'Your device verification code is 492019.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification record uploaded to InsForge')),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Record Test Notification'),
            ),
            const SizedBox(height: 8),

            FilledButton.tonalIcon(
              onPressed: () async {
                await CallService.instance.recordCall(
                  callType: 'INCOMING',
                  phoneNumber: '+1 (555) 019-2834',
                  startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
                  durationSeconds: 142,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call log record uploaded to InsForge')),
                  );
                }
              },
              icon: const Icon(Icons.phone_in_talk_outlined),
              label: const Text('Record Test Call Activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard({
    required String title,
    required String desc,
    required bool isActive,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isActive ? FutuerAgentTheme.brandPrimary : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Chip(
          label: Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          backgroundColor: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
