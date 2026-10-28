import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/call_service.dart';
import '../../../services/enrollment_service.dart';
import '../../../services/heartbeat_service.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/role_service.dart';
import '../../../services/session_listener_service.dart';
import '../../role_selection_screen.dart';
import '../permissions/agent_permissions_screen.dart';
import '../session/agent_active_session_screen.dart';

class AgentStatusScreen extends StatefulWidget {
  const AgentStatusScreen({super.key});

  @override
  State<AgentStatusScreen> createState() => _AgentStatusScreenState();
}

class _AgentStatusScreenState extends State<AgentStatusScreen> {
  final _enrollment = EnrollmentService.instance;
  final _heartbeat = HeartbeatService.instance;
  final _location = LocationService.instance;
  final _sessionListener = SessionListenerService.instance;

  @override
  void initState() {
    super.initState();
    // Start continuous background telemetry
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
                  color: FutuerTheme.brandPrimary,
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
                    style: FilledButton.styleFrom(backgroundColor: FutuerTheme.brandPrimaryDark),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _sessionListener.updateSessionStatus(sessionId: sessionId, status: 'ACTIVE');
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AgentActiveSessionScreen(
                            sessionId: sessionId,
                            sessionType: type,
                          ),
                        ),
                      );
                    },
                    child: const Text('Accept & Stream'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisconnect() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Device?'),
        content: const Text(
          'This will unpair this phone from Futuer Controller and stop background synchronization. You can re-pair at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _heartbeat.stop();
              _location.stop();
              _sessionListener.stop();
              await _enrollment.unpair();
              await RoleService.instance.resetRole();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _triggerTestTelemetry() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Simulate / Send Telemetry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send verified telemetry records to InsForge for testing Controller updates.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_searching, color: Colors.blue),
              title: const Text('Force GPS Location Upload'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _location.forceUpdateLocation();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GPS coordinates recorded to backend.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('Simulate Notification Event'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await NotificationService.instance.recordNotification(
                  appPackage: 'com.android.mms',
                  title: 'New Message',
                  text: 'Important update from system telemetry',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification recorded to backend.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_in_talk, color: Colors.green),
              title: const Text('Simulate Call Log Record'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await CallService.instance.recordCall(
                  callType: 'INCOMING',
                  phoneNumber: '+1-555-0199',
                  startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
                  durationSeconds: 142,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call record recorded to backend.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final timeFormat = DateFormat('hh:mm:ss a');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FutuerTheme.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phonelink_setup_rounded, color: FutuerTheme.brandPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Futuer Agent',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  _enrollment.cachedDeviceName ?? 'Enrolled Phone',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configure Permissions',
            icon: const Icon(Icons.security),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AgentPermissionsScreen(isModalConfig: true)),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'telemetry') _triggerTestTelemetry();
              if (val == 'permissions') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AgentPermissionsScreen(isModalConfig: true)),
                );
              }
              if (val == 'disconnect') _confirmDisconnect();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'telemetry',
                child: Row(
                  children: [
                    Icon(Icons.send, size: 18),
                    SizedBox(width: 8),
                    Text('Send Test Telemetry'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'permissions',
                child: Row(
                  children: [
                    Icon(Icons.security, size: 18),
                    SizedBox(width: 8),
                    Text('Permissions'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.link_off, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Disconnect Device', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Status Banner Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: FutuerTheme.onlineColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FutuerTheme.onlineColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: FutuerTheme.onlineColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: FutuerTheme.onlineColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ONLINE & SYNCING',
                                style: TextStyle(
                                  color: FutuerTheme.onlineColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _enrollment.cachedDeviceName ?? 'Enrolled Phone',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Active heartbeats every 30s',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Telemetry Details
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Telemetry',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: _heartbeat.lastHeartbeatNotifier,
                      builder: (context, lastBeat, _) {
                        return _buildTelemetryRow(
                          icon: Icons.favorite_border,
                          label: 'Last Heartbeat Sent',
                          value: lastBeat != null ? timeFormat.format(lastBeat) : 'Syncing...',
                        );
                      },
                    ),
                    const Divider(height: 16),
                    _buildTelemetryRow(
                      icon: Icons.fingerprint,
                      label: 'Device ID',
                      value: _enrollment.cachedDeviceId != null
                          ? '${_enrollment.cachedDeviceId!.substring(0, 8)}...'
                          : 'Pending',
                    ),
                    const Divider(height: 16),
                    _buildTelemetryRow(
                      icon: Icons.account_circle_outlined,
                      label: 'Enrollee Account',
                      value: user?.email ?? 'Authenticated',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transparent Operation & Privacy Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? FutuerTheme.darkSurfaceVariant : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Futuer Agent runs transparently. Android visual privacy indicators (green camera/mic dots) will automatically illuminate whenever an authorized session is active.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AgentPermissionsScreen(isModalConfig: true)),
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('Configure Permissions Checklist'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _triggerTestTelemetry,
              icon: const Icon(Icons.send),
              label: const Text('Test Telemetry Upload'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _confirmDisconnect,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect This Device'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
