import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../models/device_model.dart';
import '../../../../services/device_service.dart';

class ConnectionHistoryTab extends StatefulWidget {
  final DeviceModel device;

  const ConnectionHistoryTab({super.key, required this.device});

  @override
  State<ConnectionHistoryTab> createState() => _ConnectionHistoryTabState();
}

class _ConnectionHistoryTabState extends State<ConnectionHistoryTab> {
  List<Map<String, dynamic>> _heartbeats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHeartbeats();
  }

  Future<void> _fetchHeartbeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await DeviceService.instance.fetchHeartbeats(widget.device.id);
      if (mounted) {
        setState(() {
          _heartbeats = items;
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
    final dateFormat = DateFormat('MMM d, hh:mm:ss a');

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
              Text('Failed to load history: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _fetchHeartbeats, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_heartbeats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                'No Connection Events Recorded',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verified 60-second telemetry heartbeats from Futuer Link will be logged here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHeartbeats,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _heartbeats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final h = _heartbeats[index];
          final state = h['connection_state']?.toString().toUpperCase() ?? 'ONLINE';
          final isOnline = state == 'ONLINE';
          final receivedAt = h['received_at'] != null ? DateTime.tryParse(h['received_at'].toString()) : null;
          final battery = h['battery_level'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: isOnline
                  ? FutuerTheme.onlineColor.withValues(alpha: 0.15)
                  : FutuerTheme.offlineColor.withValues(alpha: 0.15),
              child: Icon(
                isOnline ? Icons.check_circle : Icons.offline_bolt,
                color: isOnline ? FutuerTheme.onlineColor : FutuerTheme.offlineColor,
              ),
            ),
            title: Text(
              'Heartbeat Verified: $state',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              receivedAt != null ? dateFormat.format(receivedAt.toLocal()) : 'Timestamp N/A',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: battery != null
                ? Text(
                    '$battery% Battery',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  )
                : null,
          );
        },
      ),
    );
  }
}
