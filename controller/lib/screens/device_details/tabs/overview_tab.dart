import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/device_model.dart';
import '../../../services/audit_service.dart';
import '../../../services/device_service.dart';

class OverviewTab extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onRefresh;

  const OverviewTab({
    super.key,
    required this.device,
    required this.onRefresh,
  });

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return FutuerTheme.onlineColor;
      case DeviceStatus.offline:
      case DeviceStatus.lastSeen:
        return FutuerTheme.offlineColor;
      case DeviceStatus.connecting:
        return FutuerTheme.connectingColor;
      case DeviceStatus.permissionRequired:
        return FutuerTheme.permissionReqColor;
    }
  }

  Future<void> _confirmRevoke(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Device Authorization?'),
        content: Text(
          'This will disconnect "${device.deviceName}" and remove all pairing authorization. The secondary phone will need to be re-paired to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revoke Device'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await DeviceService.instance.revokeDevice(device.id);
        await AuditService.instance.log(
          action: 'DEVICE_REVOKED',
          result: 'SUCCESS',
          deviceId: device.id,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device authorization revoked')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Revocation failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(device.status);
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm:ss a');

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          device.statusLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if (device.batteryLevel != null) ...[
                          Icon(
                            device.isCharging ? Icons.battery_charging_full : Icons.battery_std,
                            size: 20,
                            color: device.batteryLevel! < 20 ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.batteryLevel}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: 28),
                    _buildInfoRow('Device Name', device.deviceName),
                    _buildInfoRow('Model', device.deviceModel ?? 'Android Device'),
                    _buildInfoRow('Platform', device.devicePlatform.toUpperCase()),
                    _buildInfoRow(
                      'Last Heartbeat',
                      device.lastSeenAt != null
                          ? dateFormat.format(device.lastSeenAt!.toLocal())
                          : 'Never recorded',
                    ),
                    _buildInfoRow(
                      'Enrolled At',
                      dateFormat.format(device.createdAt.toLocal()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Heartbeat note
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 20, color: FutuerTheme.brandPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Online status is continuously determined by verified background heartbeats every 60 seconds.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Revoke Button
            OutlinedButton.icon(
              onPressed: () => _confirmRevoke(context),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Revoke Device Authorization', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
