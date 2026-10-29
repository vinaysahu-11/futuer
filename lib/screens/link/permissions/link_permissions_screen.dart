import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/theme.dart';
import '../../../services/heartbeat_service.dart';
import '../home/link_status_screen.dart';

class LinkPermissionsScreen extends StatefulWidget {
  final bool isModalConfig;
  const LinkPermissionsScreen({super.key, this.isModalConfig = false});

  @override
  State<LinkPermissionsScreen> createState() => _LinkPermissionsScreenState();
}

class _LinkPermissionsScreenState extends State<LinkPermissionsScreen>
    with WidgetsBindingObserver {
  bool _locationGranted = false;
  bool _notificationsGranted = false;
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recheckAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAll();
    }
  }

  Future<void> _recheckAll() async {
    setState(() => _isChecking = true);
    try {
      final loc = await Permission.location.status;
      final cam = await Permission.camera.status;
      final mic = await Permission.microphone.status;
      final notif = await Permission.notification.status;

      if (mounted) {
        setState(() {
          _locationGranted = loc.isGranted;
          _cameraGranted = cam.isGranted;
          _micGranted = mic.isGranted;
          _notificationsGranted = notif.isGranted;
        });
      }
    } catch (e) {
      debugPrint('Permission recheck error: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await _recheckAll();
    }
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await _recheckAll();
    }
  }

  Future<void> _requestMicrophone() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await _recheckAll();
    }
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await _recheckAll();
    }
  }

  void _finishSetup() {
    // Report permissions to backend via heartbeat immediately
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
              'Grant the required permissions below for Futuer Link telemetry, live camera, and remote management.',
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

            // 2. Camera
            _PermissionTile(
              title: 'Camera Access',
              description: 'Required for authorized live camera sessions with prominent privacy indicator.',
              icon: Icons.videocam_outlined,
              isGranted: _cameraGranted,
              onRequest: _requestCamera,
            ),
            const SizedBox(height: 12),

            // 3. Microphone
            _PermissionTile(
              title: 'Microphone Access',
              description: 'Required for authorized real-time audio streams with visible session badge.',
              icon: Icons.mic_none_outlined,
              isGranted: _micGranted,
              onRequest: _requestMicrophone,
            ),
            const SizedBox(height: 12),

            // 4. Notifications
            _PermissionTile(
              title: 'Notification Access',
              description: 'Enables real-time notifications and background connection status.',
              icon: Icons.notifications_active_outlined,
              isGranted: _notificationsGranted,
              onRequest: _requestNotifications,
            ),
            const SizedBox(height: 20),

            // Settings fallback
            OutlinedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Open Android App Settings (if blocked)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isGranted)
                const Chip(
                  avatar: Icon(Icons.check, size: 14, color: Colors.green),
                  label: Text('Granted', style: TextStyle(color: Colors.green, fontSize: 12)),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.green),
                  visualDensity: VisualDensity.compact,
                )
              else
                FilledButton.tonal(
                  onPressed: onRequest,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Turn On'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
