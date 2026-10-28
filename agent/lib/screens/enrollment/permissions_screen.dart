import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import 'pairing_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = true;
  bool _callsGranted = true;
  bool _cameraGranted = true;
  bool _micGranted = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationGranted = status == LocationPermission.always || status == LocationPermission.whileInUse;
      });
    }
  }

  Future<void> _requestLocation() async {
    final status = await Geolocator.requestPermission();
    if (mounted) {
      setState(() {
        _locationGranted = status == LocationPermission.always || status == LocationPermission.whileInUse;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorize Permissions'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Required Authorizations',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Review the permissions required for Futuer Agent. You maintain full control and can revoke these in Android Settings at any time.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            _buildPermissionTile(
              title: 'Location Tracking',
              desc: 'Collects GPS coordinates for remote location updates on Google Maps.',
              icon: Icons.location_on_outlined,
              isGranted: _locationGranted,
              onToggle: () => _requestLocation(),
            ),
            _buildPermissionTile(
              title: 'Notification Listener',
              desc: 'Forwards exposed Android notifications to Futuer Controller.',
              icon: Icons.notifications_active_outlined,
              isGranted: _notificationGranted,
              onToggle: () => setState(() => _notificationGranted = !_notificationGranted),
            ),
            _buildPermissionTile(
              title: 'Call Log Access',
              desc: 'Shares incoming, outgoing, and missed call metadata.',
              icon: Icons.phone_in_talk_outlined,
              isGranted: _callsGranted,
              onToggle: () => setState(() => _callsGranted = !_callsGranted),
            ),
            _buildPermissionTile(
              title: 'Camera Access',
              desc: 'Enables user-authorized live video sessions with visual privacy indicator.',
              icon: Icons.videocam_outlined,
              isGranted: _cameraGranted,
              onToggle: () => setState(() => _cameraGranted = !_cameraGranted),
            ),
            _buildPermissionTile(
              title: 'Microphone Access',
              desc: 'Enables user-authorized live audio streaming sessions.',
              icon: Icons.mic_none_outlined,
              isGranted: _micGranted,
              onToggle: () => setState(() => _micGranted = !_micGranted),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final perms = {
                  'location': _locationGranted,
                  'background_location': _locationGranted,
                  'notifications': _notificationGranted,
                  'call_log': _callsGranted,
                  'camera': _cameraGranted,
                  'microphone': _micGranted,
                };
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PairingScreen(initialPermissions: perms)),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: FutuerAgentTheme.brandSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continue to Pairing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String desc,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onToggle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isGranted ? Colors.green : Colors.grey, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: isGranted,
          onChanged: (_) => onToggle(),
          activeThumbColor: FutuerAgentTheme.brandPrimary,
        ),
      ),
    );
  }
}
