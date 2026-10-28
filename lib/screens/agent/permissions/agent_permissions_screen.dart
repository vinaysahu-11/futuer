import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/theme.dart';
import '../../../services/heartbeat_service.dart';
import '../home/agent_status_screen.dart';

class AgentPermissionsScreen extends StatefulWidget {
  final bool isModalConfig;
  const AgentPermissionsScreen({super.key, this.isModalConfig = false});

  @override
  State<AgentPermissionsScreen> createState() => _AgentPermissionsScreenState();
}

class _AgentPermissionsScreenState extends State<AgentPermissionsScreen> {
  bool _locationGranted = false;
  bool _notificationsGranted = false;
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _recheckAll();
  }

  Future<void> _recheckAll() async {
    setState(() => _isChecking = true);
    await _checkLocation();
    setState(() => _isChecking = false);
  }

  Future<void> _checkLocation() async {
    try {
      final status = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _locationGranted = status == LocationPermission.always || status == LocationPermission.whileInUse;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestLocation() async {
    try {
      final status = await Geolocator.requestPermission();
      if (mounted) {
        setState(() {
          _locationGranted = status == LocationPermission.always || status == LocationPermission.whileInUse;
        });
      }
    } catch (_) {}
  }

  void _finishSetup() {
    // Report permissions to backend via heartbeat
    HeartbeatService.instance.triggerHeartbeat(
      permissions: {
        'location': _locationGranted,
        'notifications': _notificationsGranted,
        'camera': _cameraGranted,
        'microphone': _micGranted,
      },
    );

    if (widget.isModalConfig) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AgentStatusScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Checklist'),
        actions: [
          IconButton(
            tooltip: 'Recheck All',
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _recheckAll,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? FutuerTheme.darkSurfaceVariant : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review features and grant permissions. Denying a permission will not cancel device enrollment; only that specific feature will be marked unavailable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade300 : Colors.blue.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. Location Permission
            _PermissionItemCard(
              title: 'Location',
              icon: Icons.location_on_outlined,
              isGranted: _locationGranted,
              whyNeeded:
                  'Required for continuous GPS location tracking and displaying real-time coordinates on the Controller Google Maps view.',
              onEnable: _requestLocation,
              onRecheck: _checkLocation,
            ),
            const SizedBox(height: 14),

            // 2. Notifications Permission
            _PermissionItemCard(
              title: 'Notifications',
              icon: Icons.notifications_none_outlined,
              isGranted: _notificationsGranted,
              whyNeeded:
                  'Required for the Android Notification Listener to synchronize incoming status updates and alerts to the Controller dashboard.',
              onEnable: () => setState(() => _notificationsGranted = !_notificationsGranted),
              onRecheck: () => setState(() {}),
            ),
            const SizedBox(height: 14),

            // 3. Camera Permission
            _PermissionItemCard(
              title: 'Camera',
              icon: Icons.videocam_outlined,
              isGranted: _cameraGranted,
              whyNeeded:
                  'Required for owner-authorized live video sessions. Always triggers the Android visual privacy indicator (green dot).',
              onEnable: () => setState(() => _cameraGranted = !_cameraGranted),
              onRecheck: () => setState(() {}),
            ),
            const SizedBox(height: 14),

            // 4. Microphone Permission
            _PermissionItemCard(
              title: 'Microphone',
              icon: Icons.mic_none_outlined,
              isGranted: _micGranted,
              whyNeeded:
                  'Required for owner-authorized remote audio sessions with visual privacy indicator compliance.',
              onEnable: () => setState(() => _micGranted = !_micGranted),
              onRecheck: () => setState(() {}),
            ),

            const SizedBox(height: 28),

            FilledButton(
              onPressed: _finishSetup,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: FutuerTheme.brandPrimaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.isModalConfig ? 'Save Changes' : 'Finish Setup & Start Futuer Agent',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionItemCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isGranted;
  final String whyNeeded;
  final VoidCallback onEnable;
  final VoidCallback onRecheck;

  const _PermissionItemCard({
    required this.title,
    required this.icon,
    required this.isGranted,
    required this.whyNeeded,
    required this.onEnable,
    required this.onRecheck,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = isGranted ? Colors.green : Colors.orange;

    return Card(
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
            Row(
              children: [
                Icon(icon, color: isGranted ? Colors.green : FutuerTheme.brandPrimary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGranted ? Icons.check_circle : Icons.error_outline,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isGranted ? 'Granted' : 'Not Granted',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              whyNeeded,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            if (!isGranted) ...[
              const SizedBox(height: 6),
              const Text(
                'Note: Without this permission, the feature will be unavailable on the Controller.',
                style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onEnable,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isGranted ? 'Reconfigure' : 'Enable / Configure',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onRecheck,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Recheck', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
