import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:futuer/models/call_activity.dart';
import 'package:futuer/models/device_model.dart';
import 'package:futuer/services/device_service.dart';

class CallActivityTab extends StatefulWidget {
  final DeviceModel device;

  const CallActivityTab({super.key, required this.device});

  @override
  State<CallActivityTab> createState() => _CallActivityTabState();
}

class _CallActivityTabState extends State<CallActivityTab> {
  List<CallActivity> _calls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

  Future<void> _fetchCalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await DeviceService.instance.fetchCallActivities(widget.device.id);
      if (mounted) {
        setState(() {
          _calls = items;
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

  IconData _getCallIcon(String type) {
    switch (type.toUpperCase()) {
      case 'INCOMING':
        return Icons.call_received;
      case 'OUTGOING':
        return Icons.call_made;
      case 'MISSED':
        return Icons.call_missed;
      default:
        return Icons.phone;
    }
  }

  Color _getCallColor(String type) {
    switch (type.toUpperCase()) {
      case 'INCOMING':
        return Colors.green;
      case 'OUTGOING':
        return Colors.blue;
      case 'MISSED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _fetchCalls, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_calls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_missed_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                'No Call Activity Recorded',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Standard Android telephony call logs captured with owner authorization will appear here.\n(Third-party VoIP calls like WhatsApp/Telegram are not captured by standard Android telephony APIs).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchCalls,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCalls,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _calls.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = _calls[index];
          final icon = _getCallIcon(c.callType);
          final color = _getCallColor(c.callType);

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(
                c.phoneNumber ?? 'Unknown Number',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${c.callType} • Duration: ${_formatDuration(c.durationSeconds)}',
              ),
              trailing: Text(
                dateFormat.format(c.startedAt.toLocal()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
