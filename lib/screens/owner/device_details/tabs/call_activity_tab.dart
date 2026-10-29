import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/call_activity.dart';
import '../../../../models/device_model.dart';
import '../../../../services/device_service.dart';

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
        return Icons.call;
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
              Text('Failed to load call activity: $_error', textAlign: TextAlign.center),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_disabled_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                'No Call Activity Logged',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authorized call activities (subject to Android permissions) will be logged here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = _calls[index];
          final icon = _getCallIcon(c.callType);
          final color = _getCallColor(c.callType);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            title: Text(
              c.phoneNumber ?? 'Unknown Number',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${c.callType.toUpperCase()} • ${dateFormat.format(c.startedAt.toLocal())}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: c.durationSeconds != null
                ? Text(
                    '${c.durationSeconds}s',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  )
                : null,
          );
        },
      ),
    );
  }
}
