import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/device_model.dart';
import '../../../../models/device_notification.dart';
import '../../../../services/device_service.dart';

class NotificationsTab extends StatefulWidget {
  final DeviceModel device;

  const NotificationsTab({super.key, required this.device});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<DeviceNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await DeviceService.instance.fetchNotifications(widget.device.id);
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, hh:mm a');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load notifications: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _fetchNotifications, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                'No Notifications Received',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authorized notifications received by Futuer Link will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              child: const Icon(Icons.notifications, color: Colors.blue),
            ),
            title: Text(
              n.notificationTitle ?? 'Notification',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (n.notificationText != null && n.notificationText!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(n.notificationText!),
                ],
                const SizedBox(height: 4),
                Text(
                  '${n.appPackage ?? "System"} • ${dateFormat.format(n.recordedAt.toLocal())}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
