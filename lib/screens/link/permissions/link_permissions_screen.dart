import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/theme.dart';
import '../../../services/heartbeat_service.dart';
import '../home/link_status_screen.dart';

class LinkPermissionsScreen extends StatefulWidget {
  final bool isModalConfig;
  const LinkPermissionsScreen({super.key, this.isModalConfig = false});

  @override
  State<LinkPermissionsScreen> createState() => _LinkPermissionsScreenState();
}

class _LinkPermissionsScreenState extends State<LinkPermissionsScreen> {
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
        MaterialPageRoute(builder: (_) => const LinkStatusScreen()),
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
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Required Android Permissions',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Grant the required permissions below for Futuer Link telemetry and remote management.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Location
            _PermissionTile(
              title: 'Location (GPS)',
              description: 'Required for real-time and last-known location tracking on Google Maps.',
              icon: Icons.location_on_outlined,
              isGranted: _locationGranted,
              onRequest: _requestLocation,
            ),
            const SizedBox(height: 12),

            // 2. Notifications
            _PermissionTile(
              title: 'Notification Listener',
              description: 'Enables real-time notification forwarding to your Futuer Owner.',
              icon: Icons.notifications_active_outlined,
              isGranted: _notificationsGranted,
              onRequest: () {
                setState(() => _notificationsGranted = !_notificationsGranted);
              },
            ),
            const SizedBox(height: 12),

            // 3. Camera
            _PermissionTile(
              title: 'Camera Access',
              description: 'Required for authorized live camera sessions with prominent privacy indicator.',
              icon: Icons.videocam_outlined,
              isGranted: _cameraGranted,
              onRequest: () {
                setState(() => _cameraGranted = !_cameraGranted);
              },
            ),
            const SizedBox(height: 12),

            // 4. Microphone
            _PermissionTile(
              title: 'Microphone Access',
              description: 'Required for authorized real-time audio streams with visible session badge.',
              icon: Icons.mic_none_outlined,
              isGranted: _micGranted,
              onRequest: () {
                setState(() => _micGranted = !_micGranted);
              },
            ),
            const SizedBox(height: 32),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: FutuerTheme.brandPrimaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _finishSetup,
              child: Text(
                widget.isModalConfig ? 'Save Permissions' : 'Complete Setup & Connect',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? Colors.green.withValues(alpha: 0.4)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isGranted ? Colors.green : Colors.grey, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isGranted ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isGranted ? 'GRANTED' : 'OPTIONAL / PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: isGranted
                ? const SizedBox.shrink()
                : FilledButton(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: FutuerTheme.brandPrimary,
                    ),
                    onPressed: onRequest,
                    child: const Text('Grant Access', style: TextStyle(fontSize: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}
