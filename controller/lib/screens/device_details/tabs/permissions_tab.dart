import 'package:flutter/material.dart';
import '../../../models/device_model.dart';

class PermissionsTab extends StatelessWidget {
  final DeviceModel device;

  const PermissionsTab({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perms = device.permissionStatus;

    final permissionItems = [
      {
        'title': 'Location Access',
        'key': 'location',
        'desc': 'Allows precise coordinates collection for Google Maps tracking.',
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'Background Location',
        'key': 'background_location',
        'desc': 'Allows periodic location updates when the app is in background.',
        'icon': Icons.my_location,
      },
      {
        'title': 'Notification Listener',
        'key': 'notifications',
        'desc': 'Allows reading user-exposed notification details.',
        'icon': Icons.notifications_active_outlined,
      },
      {
        'title': 'Call Log Access',
        'key': 'call_log',
        'desc': 'Allows reading incoming, outgoing, and missed call metadata.',
        'icon': Icons.phone_in_talk_outlined,
      },
      {
        'title': 'Camera Access',
        'key': 'camera',
        'desc': 'Allows authorized live camera sessions with visual privacy indicator.',
        'icon': Icons.videocam_outlined,
      },
      {
        'title': 'Microphone Access',
        'key': 'microphone',
        'desc': 'Allows authorized live audio streaming sessions.',
        'icon': Icons.mic_none_outlined,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: const Padding(
            padding: EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permissions must be explicitly granted on the secondary phone. When permissions are denied or revoked, corresponding features become unavailable.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...permissionItems.map((item) {
          final isGranted = perms[item['key']] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(item['icon'] as IconData, color: isGranted ? Colors.green : Colors.grey),
              title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['desc'] as String, style: const TextStyle(fontSize: 12)),
              trailing: Chip(
                avatar: Icon(
                  isGranted ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isGranted ? Colors.green : Colors.red,
                ),
                label: Text(
                  isGranted ? 'GRANTED' : 'DENIED / MISSING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.green : Colors.red,
                  ),
                ),
                backgroundColor: isGranted
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
              ),
            ),
          );
        }),
      ],
    );
  }
}
