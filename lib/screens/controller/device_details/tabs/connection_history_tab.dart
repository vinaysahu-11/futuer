import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:futuer/config/theme.dart';
import 'package:futuer/models/device_model.dart';
import 'package:futuer/services/device_service.dart';

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
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, hh:mm:ss a');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetchHeartbeats, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_heartbeats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_disabled, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                'No Heartbeats Recorded',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Futuer Agent periodically transmits authenticated heartbeats to verify online status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchHeartbeats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
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
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final h = _heartbeats[index];
          final state = h['connection_state'] ?? 'ONLINE';
          final battery = h['battery_level'];
          final version = h['app_version'] ?? '1.0.0';
          final receivedAt = DateTime.tryParse(h['received_at']?.toString() ?? '');

          return Card(
            child: ListTile(
              leading: const Icon(Icons.favorite, color: FutuerTheme.brandPrimary, size: 24),
              title: Text(
                'State: $state • App v$version',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                battery != null ? 'Battery: $battery%' : 'Battery level unavailable',
              ),
              trailing: Text(
                receivedAt != null ? dateFormat.format(receivedAt.toLocal()) : '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
